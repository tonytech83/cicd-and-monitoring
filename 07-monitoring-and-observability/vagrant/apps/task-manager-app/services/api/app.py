from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time
import os
import redis
import json
import uuid


app = Flask(__name__)

# --- PROMETHEUS METRICS DEFINITION ---
# Counter for total requests (Labels help us differentiate between endpoints/methods)
REQUEST_COUNT = Counter(
    'http_requests_total', 'Total HTTP Requests', 
    ['method', 'endpoint', 'http_status']
)

# Histogram for request duration (latency)
REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds', 'HTTP request latency',
    ['method', 'endpoint']
)

# Custom Business Metric: Total tasks created
TASKS_CREATED = Counter('tasks_created_total', 'Total number of tasks created')

# Custom Business Metric: Total completed tasks
TASKS_COMPLETED = Counter('tasks_completed_total', 'Total number of tasks completed')

# Custom Business Metric: Return active tasks
TASKS_ACTIVE = Gauge('tasks_active', 'Current active tasks')
# -------------------------------------

# these are giving us flexibility
REDIS_HOST = os.getenv('REDIS_HOST', 'redis-db')
REDIS_PORT = os.getenv('REDIS_PORT', 6379)
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

db = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD, decode_responses=True)

@app.before_request
def start_timer():
    request.start_time = time.time()

@app.after_request
def record_metrics(response):
    # Calculate latency
    latency = time.time() - request.start_time
    # Record metrics
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

def validate_task(data):
    if not data or not data.get("title"):
        return False, "Title is required"
    if data.get("priority") == "High" and not data.get("due_date"):
        return False, "High priority tasks need a due date"
    return True, None

def sync_active_tasks():
    """ Update active tasks """
    keys = db.keys("task:*")
    tasks = [json.loads(db.get(k)) for k in keys]
    active = [t for t in tasks if t.get("status") == "Pending"]
    TASKS_ACTIVE.set(len(active))

@app.route('/tasks', methods=['POST'])
def create_task():
    data = request.json
    is_valid, error = validate_task(data)
    
    if not is_valid:
        return jsonify({"status": "error", "message": error}), 400
    
    task_id = str(uuid.uuid4())
    new_task = {
        "id": task_id,
        "title": data.get("title"),
        "priority": data.get("priority", "Low"),
        "due_date": data.get("due_date"),
        "status": "Pending"
    }
    
    # Persist to Redis
    db.set(f"task:{task_id}", json.dumps(new_task))

    # Increment our business metric
    sync_active_tasks()
    TASKS_CREATED.inc()

    return jsonify(new_task), 201

@app.route('/tasks', methods=['GET'])
def get_tasks():
    """List all active tasks (not archived)"""
    keys = db.keys("task:*")
    tasks = [json.loads(db.get(k)) for k in keys]

    return jsonify(tasks)

@app.route('/tasks/<task_id>/complete', methods=['PUT'])
def complete_task(task_id):
    """Mark a task as completed so the Java Archiver can find it"""
    key = f"task:{task_id}"
    task_data = db.get(key)
    if not task_data:
        return jsonify({"error": "Task not found"}), 404
    
    task = json.loads(task_data)
    task['status'] = "Completed"
    db.set(key, json.dumps(task))

    # Increment our business metric
    sync_active_tasks()
    TASKS_COMPLETED.inc()

    return jsonify(task)

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Manual deletion of a task"""
    result = db.delete(f"task:{task_id}")
    if result == 0:
        return jsonify({"error": "Task not found"}), 404

    sync_active_tasks()

    return jsonify({"message": "Task deleted"}), 200

@app.route('/health', methods=['GET'])
def health():
    try:
        db.ping()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

@app.route('/metrics')
def metrics():
    """Endpoint for Prometheus to scrape"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    # Standard Flask port
    app.run(host='0.0.0.0', port=5000)
