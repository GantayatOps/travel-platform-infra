from datetime import datetime
from math import isfinite


def parse_optional_datetime(value, field_name):
    if value in (None, ""):
        return None

    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string")

    normalized = value.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise ValueError(f"{field_name} must be a valid ISO 8601 datetime") from exc


def parse_required_string(value, field_name, max_length=None):
    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string")

    text = value.strip()
    if not text:
        raise ValueError(f"{field_name} is required")

    if max_length is not None and len(text) > max_length:
        raise ValueError(f"{field_name} must be {max_length} characters or fewer")

    return text


def parse_positive_float(value, field_name):
    if isinstance(value, bool):
        raise ValueError(f"{field_name} must be a number greater than 0")

    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be a number greater than 0") from exc

    if not isfinite(number) or number <= 0:
        raise ValueError(f"{field_name} must be a number greater than 0")

    return number


def parse_positive_int(value, field_name):
    if isinstance(value, bool):
        raise ValueError(f"{field_name} must be a positive integer")

    try:
        number = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be a positive integer") from exc

    if number <= 0:
        raise ValueError(f"{field_name} must be a positive integer")

    return number


def normalize_content_type(value):
    return (value or "").split(";", 1)[0].strip().lower()
