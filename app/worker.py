import boto3
import json
import time
import os
from sqlalchemy import create_engine, text

REGION = "ap-south-2"

sqs = boto3.client("sqs", region_name=REGION)

QUEUE_URL = os.getenv("SQS_QUEUE_URL")

# DB
DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")

engine = create_engine(
    f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"
)


def process_message(body):
    data = json.loads(body)

    file_name = data.get("file_name")
    bucket = data.get("bucket")
    event = data.get("event")

    print(f"Processing: {file_name}", flush=True)

    if event != "UPLOAD":
        print("Skipping unknown event")
        return

    with engine.connect() as conn:
        # Idempotent update
        result = conn.execute(
            text("""
                UPDATE photos
                SET status = 'processed', processed_at = NOW()
                WHERE s3_key = :file_name
                AND status != 'processed'
            """),
            {"file_name": file_name}
        )

        print(f"Rows updated: {result.rowcount}")


def poll_sqs():
    while True:
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=20  # Long polling
        )

        messages = response.get("Messages", [])

        if not messages:
            print("No messages...")
            continue

        for msg in messages:
            try:
                process_message(msg["Body"])

                # Delete after success
                sqs.delete_message(
                    QueueUrl=QUEUE_URL,
                    ReceiptHandle=msg["ReceiptHandle"]
                )

                print("Message deleted")

            except Exception as e:
                print("Error:", str(e))
                # Do NOT delete → retry + DLQ

        time.sleep(2)


if __name__ == "__main__":
    print("Worker started...", flush=True)
    poll_sqs()