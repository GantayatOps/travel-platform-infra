import json
import boto3
import os

sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    for record in event["Records"]:
        message = record["body"]

        print(f"Processing message: {message}")

        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=f"Processed: {message}"
        )

    return {
        "statusCode": 200,
        "body": json.dumps("Processed successfully")
    }