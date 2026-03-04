import pytest
from app import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_app_responce(client):
    responce = client.get('/')
    print("Responce Status:", responce.status_code)
    assert responce.status_code == 200