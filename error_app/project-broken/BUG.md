# Injected bug — for status page testing only

**Component affected:** Wordle only (`/wordle/guess`)
**Not affected:** Home page (`/`), Hangman (`/hangman`, `/hangman/guess`)

## Symptom
- `GET /wordle` loads fine — the board renders normally.
- Every `POST /wordle/guess` returns `500 Internal Server Error`
  (deterministic, happens on 100% of guesses, not intermittent).

## Root cause
`app.py`, inside `wordle_guess()`:

```python
secret = game["scret_word"]   # typo — should be "secret_word"
```

This raises a `KeyError` on every guess submission.

## Fix
Change the line back to:

```python
secret = game["secret_word"]
```

That's the only change needed to fully restore the game.
