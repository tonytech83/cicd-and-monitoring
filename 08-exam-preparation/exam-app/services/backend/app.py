from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import os
import redis
import json
import uuid

app = Flask(__name__)

REQUEST_COUNT = Counter(
    'http_requests_total', 'Total HTTP Requests', 
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds', 'HTTP request latency',
    ['method', 'endpoint']
)

NOTES_CREATED = Counter('notes_created_total', 'Total number of notes created')
NOTES_COMPLETED  = Counter('notes_completed_total', 'Total number of notes completed')
NOTES_DELETED = Counter('notes_deleted_total', 'Total number of notes deleted')

BACKEND_PORT = os.getenv('BACKEND_PORT', 5000)
REDIS_HOST = os.getenv('REDIS_HOST', 'redis-db')
REDIS_PORT = os.getenv('REDIS_PORT', 6379)
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

db = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD, decode_responses=True)

@app.before_request
def start_timer():
    request.start_time = time.time()

@app.after_request
def record_metrics(response):
    latency = time.time() - request.start_time
    REQUEST_COUNT.labels(
        method=request.method, 
        endpoint=request.path, 
        http_status=response.status_code
    ).inc()
    REQUEST_LATENCY.labels(
        method=request.method, 
        endpoint=request.path
    ).observe(latency)
    return response

def validate_note(data):
    if not data or not data.get("title"):
        return False, "Title is required"
    if data.get("priority") == "High" and not data.get("due_date"):
        return False, "High priority notes need a due date"
    return True, None

@app.route('/metrics')
def metrics():
    """Endpoint for Prometheus to scrape"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/notes', methods=['POST'])
def create_note():
    data = request.json
    is_valid, error = validate_note(data)
    
    if not is_valid:
        return jsonify({"status": "error", "message": error}), 400
    
    note_id = str(uuid.uuid4())
    new_note = {
        "id": note_id,
        "title": data.get("title"),
        "priority": data.get("priority", "Low"),
        "due_date": data.get("due_date"),
        "status": "Pending"
    }
    
    db.set(f"note:{note_id}", json.dumps(new_note))

    NOTES_CREATED.inc()
    
    return jsonify(new_note), 201

@app.route('/notes', methods=['GET'])
def get_notes():
    """List all active notes (not archived)"""
    keys = db.keys("note:*")
    notes = [json.loads(db.get(k)) for k in keys]
    return jsonify(notes)

@app.route('/notes/<note_id>/complete', methods=['PUT'])
def complete_note(note_id):
    """Mark a note as completed so the Java Archiver can find it"""
    key = f"note:{note_id}"
    note_data = db.get(key)
    if not note_data:
        return jsonify({"error": "Note not found"}), 404
    
    note = json.loads(note_data)
    note['status'] = "Completed"
    db.set(key, json.dumps(note))

    NOTES_COMPLETED.inc()

    return jsonify(note)

@app.route('/notes/<note_id>', methods=['DELETE'])
def delete_note(note_id):
    """Manual deletion of a note"""
    result = db.delete(f"note:{note_id}")
    if result == 0:
        return jsonify({"error": "Note not found"}), 404

    NOTES_DELETED.inc()

    return jsonify({"message": "Note deleted"}), 200

@app.route('/status', methods=['GET'])
def status():
    """Get notes statistics"""
    activeCount = 0
    completedCount = 0
    try:
        keys = db.keys("note:*")
        notes = [json.loads(db.get(k)) for k in keys]

        for n in notes:
            if n['status'] == "Completed":
                completedCount = completedCount + 1
            else:
                activeCount= activeCount + 1
        return jsonify({"total": len(keys), "active": activeCount, "completed": completedCount}), 200
    except Exception as e:
        return jsonify({"total": "0", "active": "0", "completed": "0", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=BACKEND_PORT)
