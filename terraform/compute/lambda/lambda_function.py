import json
import logging
import os
from functools import lru_cache
from urllib.parse import unquote_plus

import boto3
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_SECRET_ARN = os.environ.get("DB_SECRET_ARN")
AWS_REGION = os.environ.get("AWS_REGION")
BUCKET_NAME = os.environ["BUCKET_NAME"]
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
MAX_UPLOAD_BYTES = int(os.environ.get("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}

secretsmanager = boto3.client("secretsmanager", region_name=AWS_REGION)
s3 = boto3.client("s3", region_name=AWS_REGION)
sns = boto3.client("sns", region_name=AWS_REGION)


@lru_cache(maxsize=1)
def get_db_password():
    # Cache the secret per warm Lambda runtime to avoid a Secrets Manager call for every SQS record.
    if not DB_SECRET_ARN:
        if DB_PASSWORD:
            return DB_PASSWORD
        raise ValueError("Missing DB password configuration")

    response = secretsmanager.get_secret_value(SecretId=DB_SECRET_ARN)
    secret = json.loads(response["SecretString"])
    return secret["password"]


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=get_db_password(),
        connect_timeout=5,
    )


def normalized_content_type(value):
    return (value or "").split(";", 1)[0].strip().lower()


def parse_s3_record(s3_event):
    try:
        bucket = s3_event["s3"]["bucket"]["name"]
        raw_key = s3_event["s3"]["object"]["key"]
        event_size = int(s3_event["s3"]["object"].get("size", 0))
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("Invalid S3 event record shape") from exc

    # S3 event keys are URL encoded; decode before matching the DB key written by the app.
    key = unquote_plus(raw_key)

    if bucket != BUCKET_NAME:
        raise ValueError(f"Unexpected bucket {bucket}; expected {BUCKET_NAME}")

    if not key.startswith("trips/"):
        raise ValueError(f"Unexpected S3 key prefix: {key}")

    if event_size <= 0:
        raise ValueError(f"Invalid object size in event for {key}: {event_size}")

    if event_size > MAX_UPLOAD_BYTES:
        raise ValueError(f"Object exceeds max upload size: {event_size}")

    return bucket, key, event_size


def inspect_s3_object(bucket, key, event_size):
    response = s3.head_object(Bucket=bucket, Key=key)
    content_type = normalized_content_type(response.get("ContentType"))
    content_length = int(response.get("ContentLength", event_size))

    if content_type not in ALLOWED_CONTENT_TYPES:
        allowed = ", ".join(sorted(ALLOWED_CONTENT_TYPES))
        raise ValueError(f"Invalid content type {content_type}; allowed: {allowed}")

    if content_length <= 0:
        raise ValueError(f"Invalid object size from S3 for {key}: {content_length}")

    if content_length > MAX_UPLOAD_BYTES:
        raise ValueError(f"Object exceeds max upload size: {content_length}")

    return content_type, content_length


def update_photo_record(bucket, key, content_type, size):
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Keep processing idempotent: an SQS retry should not republish or mutate already processed photos.
            cur.execute(
                """
                UPDATE photos
                SET status = 'processed',
                    content_type = %s,
                    size = %s,
                    processed_at = NOW()
                WHERE s3_bucket = %s
                  AND s3_key = %s
                  AND status != 'processed'
                RETURNING id, trip_id;
                """,
                (content_type, size, bucket, key),
            )

            result = cur.fetchone()
            conn.commit()

    return result


def publish_processed_notification(photo_id, trip_id, bucket, key, content_type, size):
    if not SNS_TOPIC_ARN:
        logger.info("SNS_TOPIC_ARN not configured; skipping notification")
        return False

    message = {
        "event": "photo_processed",
        "photo_id": photo_id,
        "trip_id": trip_id,
        "bucket": bucket,
        "key": key,
        "content_type": content_type,
        "size": size,
    }

    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="Travel photo processed",
            Message=json.dumps(message, sort_keys=True),
        )
    except Exception:
        # DB processing is the source of truth; notification delivery should not force SQS retries.
        logger.exception("Failed to publish SNS notification for photo_id=%s", photo_id)
        return False

    return True


def process_s3_event(s3_event):
    bucket, key, event_size = parse_s3_record(s3_event)
    logger.info("Processing S3 upload s3://%s/%s", bucket, key)

    content_type, size = inspect_s3_object(bucket, key, event_size)
    result = update_photo_record(bucket, key, content_type, size)

    if not result:
        logger.info("Photo already processed or not found: s3://%s/%s", bucket, key)
        return False

    photo_id, trip_id = result
    sns_published = publish_processed_notification(
        photo_id, trip_id, bucket, key, content_type, size
    )
    logger.info(
        "Processed photo_id=%s trip_id=%s key=%s sns_published=%s",
        photo_id,
        trip_id,
        key,
        sns_published,
    )
    return True


def process_sqs_record(record):
    try:
        body = json.loads(record["body"])
    except (KeyError, TypeError, json.JSONDecodeError) as exc:
        raise ValueError("SQS message body must be a valid S3 event JSON payload") from exc

    if body.get("Event") == "s3:TestEvent":
        logger.info("Skipping S3 test event")
        return 0

    s3_records = body.get("Records")
    if not isinstance(s3_records, list):
        raise ValueError("S3 event payload is missing Records list")

    processed = 0
    for s3_event in s3_records:
        if process_s3_event(s3_event):
            processed += 1

    return processed


def lambda_handler(event, context):
    sqs_records = event.get("Records", [])
    logger.info("Received %s SQS record(s)", len(sqs_records))

    processed = 0
    for record in sqs_records:
        processed += process_sqs_record(record)

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": processed}),
    }
