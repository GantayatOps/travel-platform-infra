from flask import Flask
import boto3

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Python Docker App on Private EC2"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
