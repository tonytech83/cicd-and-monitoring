from flask import Flask
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")

app = Flask(__name__)

cnx = mysql.connector.connect(user=DB_USER,
                              password=DB_PASS,
                              host=DB_HOST, 
                              database=DB_NAME)

@app.route('/')
def hello():
    cursor = cnx.cursor()
    cursor.execute("INSERT INTO hits () VALUES ();")
    cnx.commit()
    cursor.execute("SELECT COUNT(*) FROM hits;")
    (count,) = cursor.fetchone()
    cursor.close()

    return f'Hello! This Python app has been viewed {count} times.\n'


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
    cnx.close()