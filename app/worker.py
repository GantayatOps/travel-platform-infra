import boto3
import json
import time
import os
from sqlalchemy import create_engine, text
import logging
from urllib.parse import unquote_plus

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

logger = logging.getLogger(__name__)

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
    try:
        data = json.loads(body)

        # S3 event structure
        record = data["Records"][0]

        bucket = record["s3"]["bucket"]["name"]
        file_name = unquote_plus(record["s3"]["object"]["key"])

        logger.info(f"Processing file: {file_name} | bucket: {bucket}")

    except (KeyError, IndexError, json.JSONDecodeError) as e:
        logger.error(f"Invalid S3 event format: {e}")
        return

    try:
        with engine.begin() as conn:
            # Idempotent update
            result = conn.execute(
                text("""
                    UPDATE photos
                    SET status = 'processed',
                        processed_at = NOW()
                    WHERE s3_key = :file_name
                    AND status != 'processed'
                """),
                {"file_name": file_name}
            )

            logger.info(f"Rows updated: {result.rowcount}")

    except Exception as e:
        logger.error(f"DB update failed: {str(e)}")
        raise  # important for retry


def poll_sqs():
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=5,
                WaitTimeSeconds=20  # Long polling
            )

            messages = response.get("Messages", [])

            if not messages:
                continue

            for msg in messages:
                try:
                    process_message(msg["Body"])

                    # Delete after success
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=msg["ReceiptHandle"]
                    )

                    logger.info("Message deleted")

                except Exception as e:
                    logger.error(f"Error processing message: {str(e)}")
                    # Do NOT delete → retry + DLQ

        except Exception as e:
            logger.error(f"SQS polling error: {str(e)}")

        time.sleep(2)


if __name__ == "__main__":
    logger.info("Worker started. Waiting for messages...")
    poll_sqs()