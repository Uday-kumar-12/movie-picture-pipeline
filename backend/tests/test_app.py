import pytest
from movies.app import create_app


@pytest.fixture
def client():
    app = create_app({"TESTING": True})
    with app.test_client() as client:
        yield client


def test_health_check(client):
    """Test health check returns 200 and healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.is_json
    data = response.get_json()
    assert data == {"status": "healthy"}


def test_get_movies_status_code(client):
    """Test 1: HTTP 200 response."""
    response = client.get("/movies")
    assert response.status_code == 200


def test_get_movies_is_json(client):
    """Test 2: JSON response."""
    response = client.get("/movies")
    assert response.is_json
    assert response.content_type == "application/json"


def test_get_movies_valid_data(client):
    """Test 3: Valid movie data."""
    response = client.get("/movies")
    data = response.get_json()
    assert "movies" in data
    movies = data["movies"]
    assert isinstance(movies, list)
    assert len(movies) == 3

    expected_movies = [
        {"id": "123", "title": "Top Gun: Maverick"},
        {"id": "456", "title": "Sonic the Hedgehog"},
        {"id": "789", "title": "A Quiet Place"},
    ]

    for expected in expected_movies:
        match = next((m for m in movies if m.get("id") == expected["id"]), None)
        assert match is not None
        assert match["title"] == expected["title"]
