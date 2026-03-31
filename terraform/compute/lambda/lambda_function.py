import json
import boto3
import os

sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            filename = body.get("file_name")

            print(f"Processing file: {filename}")

            # Simulate failure for DLQ testing
            if filename == "fail.txt":
                raise Exception("Simulated failure for DLQ testing")

            # Success path
            sns.publish(
                TopicArn=TOPIC_ARN,
                Message=f"Processed successfully: {filename}"
            )

        except Exception as e:
            print(f"Error processing message: {str(e)}")
            # Re-raise to trigger retry + DLQ
            raise e

    return {
        "statusCode": 200,
        "body": json.dumps("Processed successfully")
    }