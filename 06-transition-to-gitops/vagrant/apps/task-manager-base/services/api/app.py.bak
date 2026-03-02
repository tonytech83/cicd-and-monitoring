from flask import Flask, request, jsonify
import redis
import json
import uuid
import os

app = Flask(__name__)

# these are giving us flexibility
REDIS_HOST = os.getenv('REDIS_HOST', 'redis-db')
REDIS_PORT = os.getenv('REDIS_PORT', 6379)

db = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

def validate_task(data):
    if not data or not data.get("title"):
        return False, "Title is required"
    if data.get("priority") == "High" and not data.get("due_date"):
        return False, "High priority tasks need a due date"
    return True, None

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
    return jsonify(task)

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Manual deletion of a task"""
    result = db.delete(f"task:{task_id}")
    if result == 0:
        return jsonify({"error": "Task not found"}), 404
    return jsonify({"message": "Task deleted"}), 200

@app.route('/health', methods=['GET'])
def health():
    try:
        db.ping()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

if __name__ == '__main__':
    # Standard Flask port
    app.run(host='0.0.0.0', port=5000)
