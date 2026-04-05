from flask import Flask, request, jsonify
import boto3
import os
import json

from db import test_connection, engine, SessionLocal
from models import Trip, Expense, Photo, Base

from sqlalchemy import func

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
        test_connection()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

# Trip
@app.route("/trips", methods=["POST"])
def create_trip():
    db = SessionLocal()
    try:
        data = request.get_json()

        if not data or "name" not in data:
            return jsonify({"error": "name is required"}), 400

        trip = Trip(user_id=1, name=data.get("name"))

        db.add(trip)
        db.commit()
        db.refresh(trip)

        return jsonify({"id": trip.id})
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()


@app.route("/trips", methods=["GET"])
def list_trips():
    db = SessionLocal()
    try:
        trips = db.query(Trip).all()

        return jsonify([{"id": t.id, "name": t.name} for t in trips])
    finally:
        db.close()

@app.route("/trips/<int:trip_id>/total", methods=["GET"])
def get_trip_total(trip_id):
    db = SessionLocal()
    try:
        total = db.query(func.sum(Expense.amount))\
                  .filter(Expense.trip_id == trip_id)\
                  .scalar()

        return jsonify({
            "trip_id": trip_id,
            "total_expense": total or 0
        })

    finally:
        db.close()

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
    Base.metadata.create_all(bind=engine)
    app.run(host="0.0.0.0", port=3000)