import os
from flask import Flask, jsonify
from flask_cors import CORS

MOVIES_DATA = [
    {
        "id": "123",
        "title": "Top Gun: Maverick"
    },
    {
        "id": "456",
        "title": "Sonic the Hedgehog"
    },
    {
        "id": "789",
        "title": "A Quiet Place"
    }
]


def create_app(test_config=None):
    """Application factory for Flask app."""
    app = Flask(__name__)
    CORS(app)

    if test_config:
        app.config.update(test_config)

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({"status": "healthy"}), 200

    @app.route("/movies", methods=["GET"])
    def get_movies():
        return jsonify({"movies": MOVIES_DATA}), 200

    return app


app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
