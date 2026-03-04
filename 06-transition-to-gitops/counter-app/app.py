from flask import Flask

app = Flask(__name__)

count = 0

@app.route('/')
def hello():
    global count
    count = count + 1
    return f'Hello! This Python app has been viewed {count} times.\n'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
