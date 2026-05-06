import importlib.util
import json
import os
import sys
import unittest
from pathlib import Path

os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
os.environ.setdefault("AWS_REGION", "ap-south-2")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_NAME", "appdb")
os.environ.setdefault("DB_USER", "postgres")
os.environ.setdefault("DB_PASSWORD", "postgres")
os.environ.setdefault("BUCKET_NAME", "travel-platform-assets-952341")

LAMBDA_PATH = (
    Path(__file__).resolve().parents[1]
    / "terraform"
    / "compute"
    / "lambda"
    / "lambda_function.py"
)

spec = importlib.util.spec_from_file_location("lambda_function_under_test", LAMBDA_PATH)
lambda_function = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = lambda_function
spec.loader.exec_module(lambda_function)


def s3_event(bucket="travel-platform-assets-952341", key="trips/1/photos/a+b.jpg", size=10):
    return {
        "s3": {
            "bucket": {"name": bucket},
            "object": {"key": key, "size": size},
        }
    }


class LambdaParsingTests(unittest.TestCase):
    def test_normalized_content_type(self):
        self.assertEqual(
            lambda_function.normalized_content_type("Image/JPEG; charset=binary"),
            "image/jpeg",
        )
        self.assertEqual(lambda_function.normalized_content_type(None), "")

    def test_parse_s3_record_decodes_key_and_validates_shape(self):
        bucket, key, size = lambda_function.parse_s3_record(
            s3_event(key="trips/1/photos/boarding+pass.jpg", size="42")
        )

        self.assertEqual(bucket, "travel-platform-assets-952341")
        self.assertEqual(key, "trips/1/photos/boarding pass.jpg")
        self.assertEqual(size, 42)

    def test_parse_s3_record_rejects_unexpected_bucket(self):
        with self.assertRaises(ValueError):
            lambda_function.parse_s3_record(s3_event(bucket="other-bucket"))

    def test_parse_s3_record_rejects_unexpected_prefix(self):
        with self.assertRaises(ValueError):
            lambda_function.parse_s3_record(s3_event(key="misc/file.jpg"))

    def test_parse_s3_record_rejects_invalid_size(self):
        for size in (0, -1, lambda_function.MAX_UPLOAD_BYTES + 1):
            with self.subTest(size=size):
                with self.assertRaises(ValueError):
                    lambda_function.parse_s3_record(s3_event(size=size))

    def test_inspect_s3_object_validates_metadata(self):
        original_s3 = lambda_function.s3

        class FakeS3:
            def __init__(self, content_type, content_length):
                self.content_type = content_type
                self.content_length = content_length

            def head_object(self, Bucket, Key):
                return {
                    "ContentType": self.content_type,
                    "ContentLength": self.content_length,
                }

        try:
            lambda_function.s3 = FakeS3("image/webp; charset=binary", 128)
            self.assertEqual(
                lambda_function.inspect_s3_object("bucket", "key", 128),
                ("image/webp", 128),
            )

            lambda_function.s3 = FakeS3("text/plain", 128)
            with self.assertRaises(ValueError):
                lambda_function.inspect_s3_object("bucket", "key", 128)

            lambda_function.s3 = FakeS3("image/png", 0)
            with self.assertRaises(ValueError):
                lambda_function.inspect_s3_object("bucket", "key", 128)
        finally:
            lambda_function.s3 = original_s3


class LambdaSqsTests(unittest.TestCase):
    def test_process_sqs_record_skips_s3_test_event(self):
        record = {"body": json.dumps({"Event": "s3:TestEvent"})}
        self.assertEqual(lambda_function.process_sqs_record(record), 0)

    def test_process_sqs_record_counts_processed_s3_events(self):
        original_process = lambda_function.process_s3_event
        calls = []

        def fake_process(event):
            calls.append(event)
            return event["processed"]

        try:
            lambda_function.process_s3_event = fake_process
            record = {
                "body": json.dumps(
                    {
                        "Records": [
                            {"processed": True},
                            {"processed": False},
                            {"processed": True},
                        ]
                    }
                )
            }
            self.assertEqual(lambda_function.process_sqs_record(record), 2)
            self.assertEqual(len(calls), 3)
        finally:
            lambda_function.process_s3_event = original_process

    def test_process_sqs_record_rejects_bad_body(self):
        with self.assertRaises(ValueError):
            lambda_function.process_sqs_record({"body": "not-json"})

        with self.assertRaises(ValueError):
            lambda_function.process_sqs_record({"body": json.dumps({"Records": {}})})


class LambdaNotificationTests(unittest.TestCase):
    def test_publish_notification_is_best_effort(self):
        original_topic = lambda_function.SNS_TOPIC_ARN
        original_sns = lambda_function.sns

        class BrokenSns:
            def publish(self, **kwargs):
                raise RuntimeError("publish failed")

        class WorkingSns:
            def __init__(self):
                self.kwargs = None

            def publish(self, **kwargs):
                self.kwargs = kwargs

        try:
            lambda_function.SNS_TOPIC_ARN = None
            self.assertFalse(
                lambda_function.publish_processed_notification(
                    1, 2, "bucket", "key", "image/png", 10
                )
            )

            lambda_function.SNS_TOPIC_ARN = "arn:aws:sns:test"
            lambda_function.sns = BrokenSns()
            with self.assertLogs(lambda_function.logger, level="ERROR"):
                self.assertFalse(
                    lambda_function.publish_processed_notification(
                        1, 2, "bucket", "key", "image/png", 10
                    )
                )

            working_sns = WorkingSns()
            lambda_function.sns = working_sns
            self.assertTrue(
                lambda_function.publish_processed_notification(
                    1, 2, "bucket", "key", "image/png", 10
                )
            )
            self.assertEqual(working_sns.kwargs["TopicArn"], "arn:aws:sns:test")
        finally:
            lambda_function.SNS_TOPIC_ARN = original_topic
            lambda_function.sns = original_sns


if __name__ == "__main__":
    unittest.main()
