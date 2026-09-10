"""
DCYN (Deterministic Check Yes/No) validation library.

Converts incoming Yes/No values into deterministic canonical values.
"""

from typing import Any

YES_VALUES = {"yes", "y", "true", "1"}
NO_VALUES = {"no", "n", "false", "0"}


def normalize_yes_no(value: Any) -> str:
    """Normalize an incoming value to exactly 'Yes' or 'No'."""

    if isinstance(value, bool):
        return "Yes" if value else "No"

    if isinstance(value, int) and value in (0, 1):
        return "Yes" if value == 1 else "No"

    if isinstance(value, str):
        normalized = value.strip().lower()

        if normalized in YES_VALUES:
            return "Yes"

        if normalized in NO_VALUES:
            return "No"

    raise ValueError("Value must be a deterministic Yes/No response.")


def require_yes_no(value: Any) -> str:
    """Validate and return a canonical Yes/No value."""
    return normalize_yes_no(value)


def is_yes(value: Any) -> bool:
    """Return True when the value represents Yes."""
    return normalize_yes_no(value) == "Yes"


def is_no(value: Any) -> bool:
    """Return True when the value represents No."""
    return normalize_yes_no(value) == "No"
