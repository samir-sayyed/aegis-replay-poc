import pytest

from poc import greeting


def test_greeting_preserves_input_case() -> None:
    assert greeting("Aegis") == "Hello, Aegis!"


def test_greeting_rejects_empty_name() -> None:
    with pytest.raises(ValueError, match="must not be empty"):
        greeting("")
