import sys
import importlib
import unittest

sys.path.insert(0, 'src')


class TestUninstallOrchestrator(unittest.TestCase):
    def test_uninstall_sequence_dry_run(self):
        mod = importlib.import_module('uninstall.uninstall_orchestrator')
        res = mod.uninstall_sequence(yes=False, dry_run=True)
        self.assertEqual(len(res), 3)
        for r in res:
            # ensure StepResult-like object
            self.assertTrue(hasattr(r, 'to_dict'))
            d = r.to_dict()
            self.assertIn('name', d)
            self.assertIn('status', d)
            self.assertIn('message', d)
        # statuses should be Skipped in dry-run
        self.assertTrue(all(r.status == 'Skipped' for r in res))


class TestStatusSmoke(unittest.TestCase):
    def test_status_functions_dry_run(self):
        m1 = importlib.import_module('status.status_orchestrator')
        r1 = m1.get_system_status(dry_run=True)
        self.assertEqual(r1.status, 'Skipped')

        m2 = importlib.import_module('status.docker.get_docker_status')
        r2 = m2.get_docker_status(dry_run=True)
        self.assertEqual(r2.status, 'Skipped')

        m3 = importlib.import_module('status.wsl.get_wsl_status')
        r3 = m3.get_wsl_status(dry_run=True)
        self.assertEqual(r3.status, 'Skipped')


if __name__ == '__main__':
    unittest.main()
