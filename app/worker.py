import boto3
import json
import time
import os
from functools import lru_cache
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
DB_SECRET_ARN = os.environ.get("DB_SECRET_ARN")
AWS_REGION_ENV = os.environ.get("AWS_REGION", REGION)


@lru_cache(maxsize=1)
def get_db_password():
    if DB_PASSWORD:
        return DB_PASSWORD

    if not DB_SECRET_ARN:
        raise ValueError("Missing DB password configuration")

    secretsmanager = boto3.client("secretsmanager", region_name=AWS_REGION_ENV)
    response = secretsmanager.get_secret_value(SecretId=DB_SECRET_ARN)
    secret = json.loads(response["SecretString"])
    return secret["password"]

engine = create_engine(
    f"postgresql://{DB_USER}:{get_db_password()}@{DB_HOST}:5432/{DB_NAME}"
)


def process_message(body):
    try:
        logger.info(f"Raw message body: {body}")  #Debug Point

        data = json.loads(body)

        if "Records" not in data:
            raise Exception("Missing 'Records' in S3 event")

        for record in data["Records"]:
            bucket = record["s3"]["bucket"]["name"]
            file_name = unquote_plus(record["s3"]["object"]["key"])

            logger.info(f"Processing file: {file_name} | bucket: {bucket}")

            # DB update per record
            with engine.begin() as conn:
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

    except (KeyError, IndexError, json.JSONDecodeError) as e:
        logger.error(f"Invalid S3 event format: {e}")
        raise Exception(f"Invalid S3 event format: {e}")

    except Exception as e:
        logger.error(f"Processing failed: {str(e)}")
        raise  # ensures retry + DLQ


def poll_sqs():
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=5,
                WaitTimeSeconds=20
            )

            messages = response.get("Messages", [])

            if not messages:
                continue

            for msg in messages:
                try:
                    process_message(msg["Body"])

                    # Delete ONLY after successful processing
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=msg["ReceiptHandle"]
                    )

                    logger.info("Message deleted")

                except Exception as e:
                    logger.error(f"Error processing message: {str(e)}")
                    # DO NOT delete → allow retry + DLQ

        except Exception as e:
            logger.error(f"SQS polling error: {str(e)}")

        time.sleep(2)


if __name__ == "__main__":
    logger.info("Worker started. Waiting for messages...")
    poll_sqs()
