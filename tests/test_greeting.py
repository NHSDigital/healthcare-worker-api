from src.greeting import greeting_message


def test_greeting():
    assert greeting_message() == "Hello World!"
