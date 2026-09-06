import os
import random
import uuid

from flask import Flask, jsonify, render_template, request, session

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", os.urandom(24))

# --- Wordle ---------------------------------------------------------------

WORDLE_WORDS = ["ocean", "apple", "piano", "earth", "cloud", "tacos", "barca"]
WORD_LENGTH = 5
MAX_ATTEMPTS = 6

wordle_games: dict[str, dict] = {}


def create_wordle_game() -> dict:
    return {"secret_word": random.choice(WORDLE_WORDS), "history": []}


# --- Hangman ---------------------------------------------------------------

HANGMAN_WORDS = {
    "Animals": ["elephant", "giraffe", "dolphin", "kangaroo", "penguin", "cheetah"],
    "Countries": ["canada", "brazil", "france", "japan", "egypt", "norway"],
    "Food": ["pizza", "burger", "sushi", "pasta", "falafel", "pancake"],
    "Technology": ["python", "docker", "keyboard", "internet", "algorithm", "database"],
    "Sports": ["soccer", "tennis", "hockey", "cricket", "boxing", "cycling"],
}
MAX_WRONG_GUESSES = 6

hangman_games: dict[str, dict] = {}


def create_hangman_game() -> dict:
    category = random.choice(list(HANGMAN_WORDS.keys()))
    word = random.choice(HANGMAN_WORDS[category])
    return {"secret_word": word, "category": category, "guessed": set()}


def hangman_state(game: dict) -> dict:
    secret = game["secret_word"]
    guessed = game["guessed"]

    display = [letter.upper() if letter in guessed else "" for letter in secret]
    correct_letters = sorted(letter for letter in guessed if letter in secret)
    wrong_letters = sorted(letter for letter in guessed if letter not in secret)

    won = all(letter in guessed for letter in secret)
    lost = len(wrong_letters) >= MAX_WRONG_GUESSES
    game_over = won or lost

    state = {
        "display": display,
        "correct_letters": [l.upper() for l in correct_letters],
        "wrong_letters": [l.upper() for l in wrong_letters],
        "wrong_count": len(wrong_letters),
        "max_wrong": MAX_WRONG_GUESSES,
        "won": won,
        "game_over": game_over,
        "category": game["category"],
    }

    if game_over:
        state["correct_word"] = secret.upper()

    return state


# --- Routes ------------------------------------------------------------


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/wordle")
def wordle_page():
    game_id = str(uuid.uuid4())
    session["wordle_game_id"] = game_id
    wordle_games[game_id] = create_wordle_game()
    return render_template(
        "wordle.html", max_attempts=MAX_ATTEMPTS, word_length=WORD_LENGTH
    )


@app.route("/wordle/guess", methods=["POST"])
def wordle_guess():
    game_id = session.get("wordle_game_id")
    game = wordle_games.get(game_id)

    if not game:
        return jsonify({"error": "No active game, please refresh the page."}), 400

    data = request.get_json(silent=True) or {}
    user_guess = str(data.get("guess", "")).lower().strip()

    if len(user_guess) != WORD_LENGTH or not user_guess.isalpha():
        return jsonify({"error": f"Must be exactly {WORD_LENGTH} letters!"}), 400

    if len(game["history"]) >= MAX_ATTEMPTS:
        return jsonify({"error": "No attempts left!"}), 400

    secret = game["secret_word"]
    result = []
    for i, letter in enumerate(user_guess):
        if letter == secret[i]:
            status = "correct"
        elif letter in secret:
            status = "present"
        else:
            status = "absent"
        result.append({"letter": letter.upper(), "status": status})

    game["history"].append({"guess": user_guess.upper(), "result": result})

    won = user_guess == secret
    attempts_left = MAX_ATTEMPTS - len(game["history"])
    game_over = won or attempts_left == 0

    response = {
        "history": game["history"],
        "won": won,
        "attempts_left": attempts_left,
        "game_over": game_over,
    }

    if game_over:
        response["correct_word"] = secret.upper()
        wordle_games.pop(game_id, None)

    return jsonify(response)


@app.route("/hangman")
def hangman_page():
    game_id = str(uuid.uuid4())
    session["hangman_game_id"] = game_id
    game = create_hangman_game()
    hangman_games[game_id] = game
    return render_template(
        "hangman.html",
        max_wrong=MAX_WRONG_GUESSES,
        word_length=len(game["secret_word"]),
        category=game["category"],
    )


@app.route("/hangman/guess", methods=["POST"])
def hangman_guess():
    game_id = session.get("hangman_game_id")
    game = hangman_games.get(game_id)

    if not game:
        return jsonify({"error": "No active game, please refresh the page."}), 400

    data = request.get_json(silent=True) or {}
    letter = str(data.get("letter", "")).lower().strip()

    if len(letter) != 1 or not letter.isalpha():
        return jsonify({"error": "Guess a single letter."}), 400

    if letter in game["guessed"]:
        return jsonify({"error": "You already guessed that letter."}), 400

    game["guessed"].add(letter)
    state = hangman_state(game)

    if state["game_over"]:
        hangman_games.pop(game_id, None)

    return jsonify(state)


if __name__ == "__main__":
    debug_mode = os.environ.get("FLASK_DEBUG", "0") == "1"
    app.run(host="0.0.0.0", port=5000, debug=debug_mode)
