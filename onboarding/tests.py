from django.test import SimpleTestCase

from .dcyn import normalize_yes_no


class DCYNTests(SimpleTestCase):
    def test_yes_values(self):
        self.assertEqual(normalize_yes_no("Yes"), "Yes")
        self.assertEqual(normalize_yes_no("yes"), "Yes")
        self.assertEqual(normalize_yes_no(True), "Yes")
        self.assertEqual(normalize_yes_no(1), "Yes")

    def test_no_values(self):
        self.assertEqual(normalize_yes_no("No"), "No")
        self.assertEqual(normalize_yes_no("no"), "No")
        self.assertEqual(normalize_yes_no(False), "No")
        self.assertEqual(normalize_yes_no(0), "No")

    def test_invalid_value_is_rejected(self):
        with self.assertRaises(ValueError):
            normalize_yes_no("maybe")
