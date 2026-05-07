import os
from uuid import uuid4

import boto3
from flask import Blueprint, jsonify, request
from werkzeug.utils import secure_filename

from db import SessionLocal
from models import Photo, Trip

upload_bp = Blueprint("upload", __name__)

REGION = os.getenv("AWS_REGION", "ap-south-2")
BUCKET_NAME = os.getenv("BUCKET_NAME", "travel-platform-assets-952341")
# Presigned URLs must use the bucket's regional endpoint; the global endpoint fails for ap-south-2 buckets.
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", f"https://s3.{REGION}.amazonaws.com")
MAX_UPLOAD_BYTES = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}


def create_s3_client():
    return boto3.client(
        "s3",
        region_name=REGION,
        endpoint_url=S3_ENDPOINT_URL,
    )


s3 = create_s3_client()


def _photo_key(trip_id, filename):
    safe_filename = secure_filename(filename or "")
    if not safe_filename:
        raise ValueError("filename must include at least one safe character")

    if len(safe_filename) > 255:
        raise ValueError("filename must be 255 characters or fewer")

    return f"trips/{trip_id}/photos/{uuid4().hex}-{safe_filename}"


def _validate_content_type(content_type):
    normalized = (content_type or "").split(";", 1)[0].strip().lower()
    if normalized not in ALLOWED_CONTENT_TYPES:
        allowed = ", ".join(sorted(ALLOWED_CONTENT_TYPES))
        raise ValueError(f"content_type must be one of: {allowed}")

    return normalized


def _validate_file_size(value):
    if value in (None, ""):
        raise ValueError("file_size is required")

    try:
        size = int(value)
    except (TypeError, ValueError):
        raise ValueError("file_size must be an integer")

    if size <= 0:
        raise ValueError("file_size must be greater than 0")

    if size > MAX_UPLOAD_BYTES:
        raise ValueError(f"file_size must be less than or equal to {MAX_UPLOAD_BYTES}")

    return size


def _serialize_photo(photo):
    return {
        "id": photo.id,
        "trip_id": photo.trip_id,
        "s3_bucket": photo.s3_bucket,
        "s3_key": photo.s3_key,
        "status": photo.status,
        "content_type": photo.content_type,
        "size": photo.size,
        "uploaded_at": photo.uploaded_at.isoformat() if photo.uploaded_at else None,
        "processed_at": photo.processed_at.isoformat() if photo.processed_at else None,
        "created_at": photo.created_at.isoformat() if photo.created_at else None,
    }


@upload_bp.route("/trips/<int:trip_id>/photos/presign", methods=["POST"])
def presign_photo_upload(trip_id):
    db = SessionLocal()
    try:
        data = request.get_json(silent=True) or {}
        filename = data.get("filename")

        if not filename:
            return jsonify({"error": "filename is required"}), 400

        try:
            content_type = _validate_content_type(data.get("content_type"))
            file_size = _validate_file_size(data.get("file_size"))
            s3_key = _photo_key(trip_id, filename)
        except ValueError as e:
            return jsonify({"error": str(e)}), 400

        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            return jsonify({"error": "trip not found"}), 404

        upload_url = s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": s3_key,
                "ContentType": content_type,
            },
            ExpiresIn=3600,
        )

        # Create the DB row only after signing succeeds so failed presign attempts do not leave orphaned pending photos.
        photo = Photo(
            trip_id=trip_id,
            s3_bucket=BUCKET_NAME,
            s3_key=s3_key,
            status="pending",
            content_type=content_type,
            size=file_size,
        )

        db.add(photo)
        db.commit()
        db.refresh(photo)

        return jsonify(
            {
                "photo": _serialize_photo(photo),
                "upload_url": upload_url,
                "s3_key": s3_key,
                "method": "PUT",
                "max_upload_bytes": MAX_UPLOAD_BYTES,
                "headers": {
                    "Content-Type": content_type,
                },
            }
        )
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()


@upload_bp.route("/photos/<int:photo_id>/download", methods=["GET"])
def get_photo_download_url(photo_id):
    db = SessionLocal()
    try:
        photo = db.query(Photo).filter(Photo.id == photo_id).first()
        if not photo:
            return jsonify({"error": "photo not found"}), 404

        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": photo.s3_bucket, "Key": photo.s3_key},
            ExpiresIn=3600,
        )
        return jsonify({"photo": _serialize_photo(photo), "url": url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()
