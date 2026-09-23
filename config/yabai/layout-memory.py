#!/usr/bin/env python3
"""Remember freeform yabai layouts separately for each physical display setup."""
import collections
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

STATE = Path.home() / '.local/state/yabai-layouts'
YABAI = '/opt/homebrew/bin/yabai'
ROUTES = {'Claude': 'claude', 'Brave Browser': 'brave', 'Signal': 'signal',
          'sioyek': 'sioyek', 'Sioyek': 'sioyek'}


def call(*args):
    result = subprocess.run([YABAI, '-m', *map(str, args)], capture_output=True,
                            text=True, timeout=15)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def query(kind):
    return json.loads(call('query', '--' + kind))


def topology(displays):
    # Indexes change when docks reconnect; physical UUIDs do not.
    identity = sorted((d['uuid'], d['frame']) for d in displays)
    return hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:24]


def eligible(w):
    return (w.get('has-ax-reference', True)
            and w.get('role') == 'AXWindow' and w.get('subrole') == 'AXStandardWindow'
            and not any(w.get(k) for k in ('is-native-fullscreen', 'is-minimized',
                                           'is-hidden', 'is-sticky')))


def capture(displays, spaces, windows):
    ds = {d['index']: d for d in displays}
    ss = {s['index']: s for s in spaces}
    result = []
    for w in windows:
        if not eligible(w) or w['display'] not in ds or w['space'] not in ss:
            continue
        d, s = ds[w['display']], ss[w['space']]
        desktops = [x for x in spaces if x['display'] == d['index']
                    and not x['is-native-fullscreen']]
        if s not in desktops:
            continue
        result.append({k: w[k] for k in ('id', 'pid', 'app', 'title', 'frame')} |
                      {'display_uuid': d['uuid'], 'space_uuid': s['uuid'],
                       'space_label': s['label'], 'slot': desktops.index(s)})
    return result


def match(saved, windows, used):
    candidates = [w for w in windows if eligible(w) and w['id'] not in used
                  and w['app'] == saved['app']]
    exact = [w for w in candidates if w['id'] == saved['id'] and w['pid'] == saved['pid']]
    if exact:
        return exact[0]
    titles = [w for w in candidates if w['title'] == saved['title']]
    if len(titles) == 1:
        return titles[0]
    # Do not guess among multiple documents with ambiguous names.
    return candidates[0] if len(candidates) == 1 else None


def restore(saved, displays, spaces, windows):
    used = set()
    for old in saved:
        w = match(old, windows, used)
        if not w:
            continue
        used.add(w['id'])
        display = next((d for d in displays if d['uuid'] == old['display_uuid']), None)
        if not display:
            continue
        label = ('fullsize' if old['space_label'] == 'fullsize'
                 else ROUTES.get(w['app'], old['space_label']))
        target = next((s for s in spaces if label and s['label'] == label), None)
        if target is None:
            target = next((s for s in spaces if old['space_uuid'] and
                           s['uuid'] == old['space_uuid']), None)
        if target is None:
            desktops = [s for s in spaces if s['display'] == display['index']
                        and not s['is-native-fullscreen']]
            target = desktops[min(old['slot'], len(desktops) - 1)] if desktops else None
        if not target:
            raise RuntimeError('No desktop for ' + old['app'])
        if target['display'] != display['index']:
            # Route assigned apps to their remembered monitor as well.
            call('space', target['index'], '--display', display['index'])
            spaces = query('spaces')
            target = next(s for s in spaces if s['id'] == target['id'])
        w = json.loads(call('query', '--windows', '--window', w['id']))
        if w['space'] != target['index']:
            call('window', w['id'], '--space', target['index'])
        if target.get('label') == 'fullsize':
            continue  # The stack layout owns geometry on desktop six.
        f = old['frame']
        call('window', w['id'], '--resize', f"abs:{round(f['w'])}:{round(f['h'])}")
        call('window', w['id'], '--move', f"abs:{round(f['x'])}:{round(f['y'])}")


def enforce_fullsize(spaces, windows):
    target = next((s for s in spaces if s['label'] == 'fullsize'), None)
    general = next((s for s in spaces if s['label'] == 'general'), None)
    if not target:
        return
    for w in windows:
        if w['space'] != target['index'] or not eligible(w):
            continue
        if w['app'] in ('Ghostty', 'ghostty', 'System Settings', 'System Preferences'):
            if general:
                call('window', w['id'], '--space', general['index'])
        elif w.get('is-floating'):
            call('window', w['id'], '--toggle', 'float')


def write_snapshot(path, snapshot):
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(snapshot, indent=2) + '\n')
    temp.replace(path)


def watch():
    active = None
    changed_at = 0
    ready = False
    history = collections.deque()
    last_poll = time.monotonic()
    last_event = None
    while True:
        try:
            now = time.monotonic()
            displays = query('displays')
            if not displays:
                raise RuntimeError('No displays available')
            key = topology(displays)
            event_file = STATE / 'display-event'
            event = event_file.stat().st_mtime_ns if event_file.exists() else None
            if key != active or now - last_poll > 20 or event != last_event:
                active, changed_at, ready = key, now, False
                history.clear()
            last_poll, last_event = now, event
            # Let macOS settle after a dock change or wake before restoring.
            if now - changed_at < 8:
                time.sleep(2)
                continue
            path = STATE / (key + '.json')
            if not ready:
                subprocess.run([str(Path(__file__).with_name('create_spaces.sh'))],
                               check=True, timeout=60)
                if path.exists():
                    restore(json.loads(path.read_text()), displays, query('spaces'), query('windows'))
                    # Space moves may renumber desktops; refresh routing rules.
                    subprocess.run([str(Path(__file__).with_name('create_spaces.sh'))],
                                   check=True, timeout=60)
                    print('Restored display setup ' + key, flush=True)
                ready = True
                time.sleep(2)
                continue
            spaces, windows = query('spaces'), query('windows')
            enforce_fullsize(spaces, windows)
            snapshot = capture(displays, spaces, windows)
            # Reject a snapshot if the topology changed during the queries.
            if topology(query('displays')) != key:
                continue
            history.append((now, snapshot))
            # Delayed writes protect the previous setup from disconnect reshuffling.
            while history and now - history[0][0] >= 10:
                _, stable = history.popleft()
                if stable:
                    write_snapshot(path, stable)
        except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as exc:
            print(time.strftime('%F %T'), str(exc), flush=True)
            history.clear()
            # Keep the saved layout intact if restoration fails; retry later.
            time.sleep(10)
        time.sleep(2)


def main():
    os.umask(0o077)
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'worker.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        watch()


if __name__ == '__main__':
    main()
