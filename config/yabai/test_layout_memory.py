import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('memory', Path(__file__).with_name('layout-memory.py'))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

D = {'index': 1, 'uuid': 'monitor-A', 'frame': {'x': 0, 'y': 0, 'w': 1500, 'h': 1000}}
S = {'id': 7, 'index': 1, 'uuid': 'desktop-A', 'label': 'claude', 'display': 1, 'is-native-fullscreen': False}
W = {'id': 10, 'pid': 20, 'app': 'Claude', 'title': 'Document', 'role': 'AXWindow',
     'subrole': 'AXStandardWindow', 'space': 1, 'display': 1,
     'frame': {'x': 10, 'y': 40, 'w': 700, 'h': 800}}

class MemoryTests(unittest.TestCase):
    def test_display_identity_not_transient_index(self):
        self.assertEqual(m.topology([D]), m.topology([D | {'index': 3}]))
        self.assertNotEqual(m.topology([D]), m.topology([D | {'uuid': 'monitor-B'}]))
        self.assertNotEqual(m.topology([D]), m.topology([D | {'frame': D['frame'] | {'w': 900}}]))

    def test_skip_fullscreen_and_minimized(self):
        self.assertEqual(m.capture([D], [S], [W | {'is-native-fullscreen': True}]), [])
        self.assertEqual(m.capture([D], [S], [W | {'is-minimized': True}]), [])
        self.assertEqual(m.capture([D], [S], [W | {'has-ax-reference': False}]), [])
        self.assertEqual(m.capture([D], [S], [W])[0]['space_label'], 'claude')

    def test_ambiguous_documents_are_not_guessed(self):
        saved = m.capture([D], [S], [W])[0]
        windows = [W | {'id': 11, 'pid': 21}, W | {'id': 12, 'pid': 21}]
        self.assertIsNone(m.match(saved, windows, set()))
        self.assertEqual(m.match(saved, windows[:1], set())['id'], 11)

    def test_restore_routes_to_label_and_restores_geometry(self):
        saved = m.capture([D], [S], [W])
        current = W | {'space': 5}
        with patch.object(m, 'call', return_value=json.dumps(current)) as call:
            m.restore(saved, [D], [S], [current])
        args = [c.args for c in call.call_args_list]
        self.assertIn(('window', 10, '--space', 1), args)
        self.assertIn(('window', 10, '--resize', 'abs:700:800'), args)
        self.assertIn(('window', 10, '--move', 'abs:10:40'), args)

    def test_fullsize_overrides_app_route_and_saved_geometry(self):
        full = S | {'index': 6, 'label': 'fullsize'}
        saved = m.capture([D], [full], [W | {'space': 6}])
        with patch.object(m, 'call', return_value=json.dumps(W)) as call:
            m.restore(saved, [D], [S, full], [W])
        args = [c.args for c in call.call_args_list]
        self.assertIn(('window', 10, '--space', 6), args)
        self.assertFalse(any('--resize' in a or '--move' in a for a in args))

    def test_fullsize_keeps_utilities_on_general_desktop(self):
        spaces = [S | {'index': 6, 'label': 'fullsize'}, S | {'index': 5, 'label': 'general'}]
        with patch.object(m, 'call') as call:
            m.enforce_fullsize(spaces, [W | {'space': 6, 'app': 'Ghostty'}])
        call.assert_called_once_with('window', 10, '--space', 5)

    def test_restore_failure_propagates_to_preserve_saved_profile(self):
        with patch.object(m, 'call', side_effect=RuntimeError('permission denied')):
            with self.assertRaises(RuntimeError):
                m.restore(m.capture([D], [S], [W]), [D], [S], [W])

if __name__ == '__main__':
    unittest.main()
