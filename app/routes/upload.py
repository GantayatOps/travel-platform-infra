import os
from uuid import uuid4

import boto3
from flask import Blueprint, jsonify, request
from werkzeug.utils import secure_filename

from db import SessionLocal
from models import Photo, Trip

upload_bp = Blueprint("upload", __name__)

REGION = "ap-south-2"
BUCKET_NAME = os.getenv("BUCKET_NAME", "travel-platform-assets-952341")

s3 = boto3.client("s3", region_name=REGION)


def _photo_key(trip_id, filename):
    safe_filename = secure_filename(filename or "")
    if not safe_filename:
        safe_filename = "upload"

    return f"trips/{trip_id}/photos/{uuid4().hex}-{safe_filename}"


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
        content_type = data.get("content_type", "application/octet-stream")

        if not filename:
            return jsonify({"error": "filename is required"}), 400

        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            return jsonify({"error": "trip not found"}), 404

        s3_key = _photo_key(trip_id, filename)
        photo = Photo(
            trip_id=trip_id,
            s3_bucket=BUCKET_NAME,
            s3_key=s3_key,
            status="pending",
            content_type=content_type,
        )

        db.add(photo)
        db.commit()
        db.refresh(photo)

        upload_url = s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": s3_key,
                "ContentType": content_type,
            },
            ExpiresIn=3600,
        )

        return jsonify(
            {
                "photo": _serialize_photo(photo),
                "upload_url": upload_url,
                "s3_key": s3_key,
                "method": "PUT",
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


@upload_bp.route("/get/<filename>", methods=["GET"])
def get_file(filename):
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET_NAME, "Key": filename},
            ExpiresIn=3600,
        )
        return jsonify({"url": url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
