import json
import os
import psycopg2

DB_NAME = "appdb"
DB_HOST = os.environ["DB_HOST"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=5
    )


def process_s3_event(s3_event):
    bucket = s3_event["s3"]["bucket"]["name"]
    key = s3_event["s3"]["object"]["key"]

    print(f"Processing file: s3://{bucket}/{key}")

    conn = get_connection()
    cur = conn.cursor()

    try:
        # 🔒 Idempotent update
        cur.execute("""
            UPDATE photos
            SET status = 'processed',
                processed_at = NOW()
            WHERE s3_key = %s
              AND status != 'processed'
            RETURNING id;
        """, (key,))

        result = cur.fetchone()

        if result:
            print(f"Updated photo ID: {result[0]}")
        else:
            print(f"Already processed or not found: {key}")

        conn.commit()

    except Exception as e:
        conn.rollback()
        print(f"DB error: {str(e)}")
        raise

    finally:
        cur.close()
        conn.close()


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    for record in event["Records"]:
        body = json.loads(record["body"])

        # SQS → contains S3 event
        for s3_event in body.get("Records", []):
            process_s3_event(s3_event)

    return {
        "statusCode": 200,
        "body": "Processed successfully"
    }