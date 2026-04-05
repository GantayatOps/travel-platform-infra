from flask import Flask, request, jsonify
import boto3
import os
import json

from db import SessionLocal
from models import Trip, Expense, Photo

app = Flask(__name__)

REGION = "ap-south-2"

s3 = boto3.client("s3", region_name=REGION)
sqs = boto3.client("sqs", region_name=REGION)

# Environment Variables
BUCKET_NAME = os.getenv("BUCKET_NAME", "travel-platform-assets-952341")
QUEUE_URL = os.getenv("SQS_QUEUE_URL")

print("===============debug point 1===============")
print("BUCKET:", BUCKET_NAME)
print("SQS QUEUE:", QUEUE_URL)

@app.route("/")
def home():
    return "Hello from Python Docker App on Private EC2 v4"

# DB Health Check
@app.route("/healthz")
def health():
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

# Trip
@app.route("/trips", methods=["POST"])
def create_trip():
    db = SessionLocal()
    data = request.json

    trip = Trip(user_id=1, name=data.get("name"))

    db.add(trip)
    db.commit()
    db.refresh(trip)

    return jsonify({"id": trip.id})


@app.route("/trips", methods=["GET"])
def list_trips():
    db = SessionLocal()
    trips = db.query(Trip).all()

    return jsonify([{"id": t.id, "name": t.name} for t in trips])

# Upload file to S3 + Trigger Events
@app.route("/upload", methods=["POST"])
def upload_file():
    file = request.files.get("file")

    if not file:
        return jsonify({"error": "No file provided"}), 400

    try:
        # 1. Upload to S3
        s3.upload_fileobj(file, BUCKET_NAME, file.filename)

        # 2. Send message to SQS (async processing trigger)
        if QUEUE_URL:
            try:
                sqs.send_message(
                    QueueUrl=QUEUE_URL,
                    MessageBody=json.dumps({
                        "file_name": file.filename,
                        "event": "UPLOAD",
                        "bucket": BUCKET_NAME
                    })
                )
            except Exception as sqs_error:
                print("SQS ERROR:", str(sqs_error))

        return jsonify({"message": f"{file.filename} uploaded successfully"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Generate presigned URL
@app.route("/get/<filename>", methods=["GET"])
def get_file(filename):
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET_NAME, "Key": filename},
            ExpiresIn=3600
        )
        return jsonify({"url": url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)