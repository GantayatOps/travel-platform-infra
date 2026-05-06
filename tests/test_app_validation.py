import os
import sys
import unittest
from datetime import datetime
from pathlib import Path
from types import SimpleNamespace

os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
os.environ.setdefault("AWS_REGION", "ap-south-2")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_NAME", "appdb")
os.environ.setdefault("DB_USER", "postgres")
os.environ.setdefault("DB_PASSWORD", "postgres")
os.environ.setdefault("BUCKET_NAME", "travel-platform-assets-952341")

APP_DIR = Path(__file__).resolve().parents[1] / "app"
sys.path.insert(0, str(APP_DIR))

from flask import Flask  # noqa: E402
from models import Trip  # noqa: E402
from routes import expenses, trips, upload  # noqa: E402


class AppValidationTests(unittest.TestCase):
    def test_s3_client_uses_regional_endpoint_for_presigned_urls(self):
        self.assertEqual(
            upload.s3.meta.endpoint_url,
            "https://s3.ap-south-2.amazonaws.com",
        )

    def test_trip_name_validation(self):
        self.assertEqual(trips._parse_trip_name("  Sydney  "), "Sydney")

        for value in (None, "", "   ", 123, "x" * 121):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    trips._parse_trip_name(value)

    def test_trip_date_validation(self):
        trips._validate_trip_dates(
            datetime.fromisoformat("2026-05-01T00:00:00"),
            datetime.fromisoformat("2026-05-02T00:00:00"),
        )

        with self.assertRaises(ValueError):
            trips._validate_trip_dates(
                datetime.fromisoformat("2026-05-02T00:00:00"),
                datetime.fromisoformat("2026-05-01T00:00:00"),
            )

        with self.assertRaises(ValueError):
            trips._validate_trip_dates(
                datetime.fromisoformat("2026-05-01T00:00:00+00:00"),
                datetime.fromisoformat("2026-05-02T00:00:00"),
            )

    def test_expense_amount_validation(self):
        self.assertEqual(expenses._parse_positive_amount("42.50"), 42.5)

        for value in (None, "", 0, -1, True, "abc", "nan", "inf"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    expenses._parse_positive_amount(value)

    def test_trip_id_validation(self):
        self.assertEqual(expenses._parse_trip_id("7"), 7)

        for value in (None, "", 0, -1, True, "abc"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    expenses._parse_trip_id(value)


class FakeQuery:
    def __init__(self, result):
        self.result = result

    def filter(self, *args, **kwargs):
        return self

    def first(self):
        return self.result


class FakeDb:
    def __init__(self, trip_exists=True):
        self.trip_exists = trip_exists
        self.add_count = 0
        self.commit_count = 0
        self.rollback_count = 0
        self.close_count = 0

    def query(self, model):
        if model is Trip and self.trip_exists:
            return FakeQuery(SimpleNamespace(id=1))
        return FakeQuery(None)

    def add(self, obj):
        self.add_count += 1

    def commit(self):
        self.commit_count += 1

    def refresh(self, obj):
        obj.id = 123
        obj.uploaded_at = None
        obj.processed_at = None
        obj.created_at = None

    def rollback(self):
        self.rollback_count += 1

    def close(self):
        self.close_count += 1


class FailingS3:
    def generate_presigned_url(self, *args, **kwargs):
        raise RuntimeError("signing failed")


class SuccessS3:
    def generate_presigned_url(self, operation, Params, ExpiresIn):
        if operation != "put_object":
            raise AssertionError(operation)
        if not Params["Key"].startswith("trips/1/photos/"):
            raise AssertionError(Params["Key"])
        if Params["ContentType"] != "image/png":
            raise AssertionError(Params["ContentType"])
        if ExpiresIn != 3600:
            raise AssertionError(ExpiresIn)
        return "https://example.test/upload"


class PresignFlowTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.original_session = upload.SessionLocal
        self.original_s3 = upload.s3

    def tearDown(self):
        upload.SessionLocal = self.original_session
        upload.s3 = self.original_s3

    def test_presign_failure_does_not_insert_photo(self):
        fake_db = FakeDb()
        upload.SessionLocal = lambda: fake_db
        upload.s3 = FailingS3()

        with self.app.test_request_context(
            json={
                "filename": "receipt.png",
                "content_type": "image/png",
                "file_size": 128,
            }
        ):
            response, status = upload.presign_photo_upload(1)

        self.assertEqual(status, 500)
        self.assertEqual(response.get_json()["error"], "signing failed")
        self.assertEqual(fake_db.add_count, 0)
        self.assertEqual(fake_db.commit_count, 0)
        self.assertEqual(fake_db.rollback_count, 1)
        self.assertEqual(fake_db.close_count, 1)

    def test_presign_success_inserts_photo_after_url_generation(self):
        fake_db = FakeDb()
        upload.SessionLocal = lambda: fake_db
        upload.s3 = SuccessS3()

        with self.app.test_request_context(
            json={
                "filename": "receipt.png",
                "content_type": "image/png; charset=binary",
                "file_size": "128",
            }
        ):
            response = upload.presign_photo_upload(1)

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload["photo"]["status"], "pending")
        self.assertEqual(payload["upload_url"], "https://example.test/upload")
        self.assertEqual(fake_db.add_count, 1)
        self.assertEqual(fake_db.commit_count, 1)
        self.assertEqual(fake_db.rollback_count, 0)
        self.assertEqual(fake_db.close_count, 1)


if __name__ == "__main__":
    unittest.main()
