import unittest
from pathlib import Path


class AlembicConfigTests(unittest.TestCase):
    def test_database_url_renders_real_password_for_migrations(self):
        env_py = Path("app/migrations/env.py").read_text()

        self.assertIn("render_as_string(hide_password=False)", env_py)
        self.assertNotIn("str(get_database_url())", env_py)


if __name__ == "__main__":
    unittest.main()
