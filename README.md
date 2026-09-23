# Dotfiles

Personal macOS configuration managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Included

- Zsh and Bash profiles
- Ghostty, Kitty, Hyper, and tmux
- Neovim
- Vimium C settings export (manual browser import)
- LaTeX preamble and starter document
- MATLAB startup configuration
- yabai, skhd, SketchyBar, and Karabiner-Elements
- Obsidian application settings and portable settings for all three vaults
- macOS defaults
- Homebrew packages
- skhd LaunchAgent
- AltTab LaunchAgent (`config/launchagents/`)

SSH keys, shell history, credentials, caches, generated files, and backups are intentionally excluded.

## Install

Clone the repository, inspect the links in `install.conf.yaml`, and run:

```sh
./install
```

The default profile is deliberately non-destructive: Dotbot will relink existing symlinks, but it will not overwrite regular files or directories. On an existing machine, move conflicting live files aside after verifying their copies in this repository, then run the installer again.

Optional profiles are separate because they install software or change system preferences:

```sh
./install profiles/packages.conf.yaml
./install profiles/macos.conf.yaml
./install profiles/services.conf.yaml
./install profiles/obsidian.conf.yaml
```

The macOS profile applies user-level Finder, Dock, keyboard, trackpad,
screenshot, menu-bar, and application preferences. It skips non-macOS hosts
and does not require administrator access by default. To also set the Mac's
computer and local host names, opt in explicitly:

```sh
DOTFILES_COMPUTER_NAME="Anders-MacBook" ./install profiles/macos.conf.yaml
```

Set `DOTFILES_SCREENSHOTS_FOLDER` to override the default `~/Screenshots`
location, or `DOTFILES_RESTART_APPS=0` to avoid restarting Finder, Dock, and
SystemUIServer after applying preferences.

The Obsidian profile merges the stored JSON settings into the existing vaults. It deliberately preserves notes, workspaces, downloaded plugin code, caches, and local credential-bearing plugin settings.

The skhd service uses the maintained `jackielii/skhd.zig` app bundle and its managed `com.jackielii.skhd` service. The services profile disables the obsolete custom and C implementation LaunchAgents before registering it, so only one daemon owns the hotkeys. On first install, grant the skhd app Accessibility and Input Monitoring access when macOS asks.

The services profile also copies `config/launchagents/com.anders.alttab.plist` into `~/Library/LaunchAgents/` (launchd ignores symlinked plists) and loads it. It starts AltTab with `open -a` rather than the raw binary so macOS attributes its permissions to AltTab.app. Turn off "Start at login" in AltTab's own preferences to avoid a second copy.

Pass Dotbot flags after the profile name, for example:

```sh
./install install.conf.yaml --dry-run
```

## Browser and LaTeX settings

See [Vimium C restore instructions](config/vimium-c/README.md) and
[LaTeX template usage](config/tex/README.md). The default installer links both
folders under `~/.config`; Vimium C settings must then be imported in the
extension options.

## Troubleshooting

### How the background services run

| Service | launchd label | Started by | Log |
|---|---|---|---|
| skhd (skhd.zig) | `com.jackielii.skhd` | `skhd --start-service` | `~/Library/Logs/skhd.log` |
| yabai | `com.yabai.daemon` | yabai service | `/tmp/yabai_$USER.err.log` |
| JankyBorders | started by `yabairc`, toggled with Shift+Cmd+B | — | — |
| AltTab | `com.anders.alttab` | `profiles/services.conf.yaml` | — |

Check what is running with:

```sh
launchctl list | grep -Ei 'skhd|yabai|borders|alttab'
pgrep -lx skhd yabai borders
```

### Edits have no effect

`~/.config/skhd` and `~/.config/yabai` must be symlinks into this repository.
If an app or script replaced them with real folders, edits here never reach
the running config:

```sh
ls -ld ~/.config/skhd ~/.config/yabai   # should show -> ~/Dotfiles/dotfiles/config/...
```

To check every linked path at once, run `scripts/check-links.sh`. Anything
not marked `OK` is a real file or folder that shadows the repository copy.
To fix them, run `scripts/adopt-links.sh` (dry run: shows which live copies
differ from the repo), then `scripts/adopt-links.sh --apply`. It copies the live
version into the repo, keeps the old path as `<path>.pre-dotbot-<timestamp>`
and creates the symlink. Review with `git diff` before committing.

### All hotkeys stop working

skhd rejects the whole file if a single line is wrong, most often a duplicate
hotkey. Clear the log, reload and read the fresh error:

```sh
: > ~/Library/Logs/skhd.log; skhd --reload; sleep 1; cat ~/Library/Logs/skhd.log
```

The error names the line (`skhdrc:87:11: Duplicate hotkey ...`). Remove the
duplicate and reload. If skhd is not running at all: `skhd --restart-service`.

### Cmd+1–6 or moving windows between Spaces does nothing

Those commands need the yabai scripting addition. Test it:

```sh
yabai -m space --focus 2; echo $?
```

If it fails, reload it with `sudo yabai --load-sa`. `yabairc` loads it at every
start via `sudo -n`, which depends on `/private/etc/sudoers.d/yabai`. That file
pins yabai's checksum, so every yabai upgrade breaks it. To avoid that, yabai
is pinned in Homebrew (`brew pin yabai`) and only upgraded with:

```sh
scripts/update-yabai.sh
```

It upgrades yabai, re-pins it, rewrites the sudoers rule with the new checksum
(validated with `visudo`), restarts yabai and checks the scripting addition.
Run the same script if yabai was upgraded some other way.

### An app says "Not allowed" although the permission is switched on

Usually a stale privacy (TCC) entry after an update, or the app was not
restarted after granting access.

1. Quit the app.
2. Reset its entries (find the bundle id with `osascript -e 'id of app "AltTab"'`):
   ```sh
   tccutil reset Accessibility com.lwouis.alt-tab-macos
   tccutil reset ScreenCapture com.lwouis.alt-tab-macos
   tccutil reset ListenEvent <bundle-id>   # Input Monitoring, e.g. for skhd
   ```
3. Start the app with `open -a <App>` and grant the permissions when asked.
4. **Quit and start it again.** Screen Recording only takes effect after a relaunch.

For skhd, grant Accessibility and Input Monitoring, then `skhd --restart-service`.

## Local-only settings

Keep tokens, credentials, private keys, and machine-specific overrides in ignored `*.local`, `*.secret`, `.env`, or `private/` files. Never add SSH private keys, `~/.pgpass`, shell history, or application credential stores.

## Updating

Edit the files in this repository. Once installed, most managed paths are symlinks, so application changes are reflected here automatically. Review `git diff` before committing.
