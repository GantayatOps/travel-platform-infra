from flask import Flask, request, jsonify
import boto3
import os
import json

app = Flask(__name__)

# AWS Clients (IAM Role based)
REGION = "ap-south-2"  # Ensure all services are in same region

s3 = boto3.client("s3", region_name=REGION)
sqs = boto3.client("sqs", region_name=REGION)

# Environment Variables
BUCKET_NAME = os.getenv("BUCKET_NAME", "travel-platform-assets-952341")
QUEUE_URL = os.getenv("SQS_QUEUE_URL")

print("BUCKET:", BUCKET_NAME)
print("SQS QUEUE:", QUEUE_URL)

# Routes
@app.route("/")
def home():
    return "Hello from Python Docker App on Private EC2"

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

# Run App
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)