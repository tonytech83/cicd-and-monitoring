import pytest
from unittest.mock import patch
from app import app, validate_task

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_validate_task_missing_title_high():
    data = {"priority": "High"}
    is_valid, error = validate_task(data)
    assert is_valid is False
    assert error == "Title is required"

def test_validate_task_missing_title_low():
    data = {"priority": "Low"}
    is_valid, error = validate_task(data)
    assert is_valid is False
    assert error == "Title is required"

def test_validate_task_high_priority_no_date():
    data = {"title": "Critical Bug", "priority": "High"}
    is_valid, error = validate_task(data)
    assert is_valid is False
    assert error == "High priority tasks need a due date"

def test_validate_task_valid_low():
    data = {"title": "Read the news", "priority": "Low"}
    is_valid, error = validate_task(data)
    assert is_valid is True
    assert error is None

def test_validate_task_valid_high():
    data = {"title": "Update Jenkins", "priority": "High", "due_date": "2026-02-10"}
    is_valid, error = validate_task(data)
    assert is_valid is True
    assert error is None

@patch('app.db.set')
def test_create_task_api(mock_set, client):
    payload = {
        "title": "Pipeline Test",
        "priority": "Low"
    }
    response = client.post('/tasks', json=payload)
    data = response.get_json()
    
    assert response.status_code == 201
    assert data['title'] == "Pipeline Test"
    assert mock_set.called

@patch('app.db.set')
def test_create_task_api_high(mock_set, client):
    payload = {
        "title": "Pipeline Test",
        "priority": "High"
    }
    response = client.post('/tasks', json=payload)
    data = response.get_json()
    
    assert response.status_code == 400 # used to be 201
    #assert data['status'] == 'error'
    assert mock_set.called is False

@patch('app.db.keys')
def test_get_tasks_api(mock_keys, client):
    mock_keys.return_value = []
    response = client.get('/tasks')
    assert response.status_code == 200
    assert isinstance(response.get_json(), list)

def test_delete_nonexistent_task(client):
    with patch('app.db.delete') as mock_del:
        mock_del.return_value = 0
        response = client.delete('/tasks/invalid-id')
        assert response.status_code == 404
        assert response.get_json()['error'] == "Task not found"
