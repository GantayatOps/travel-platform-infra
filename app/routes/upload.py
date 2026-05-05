import os

import boto3
from flask import Blueprint, jsonify, request

from db import SessionLocal
from models import Photo

upload_bp = Blueprint("upload", __name__)

REGION = "ap-south-2"
BUCKET_NAME = os.getenv("BUCKET_NAME", "travel-platform-assets-952341")

s3 = boto3.client("s3", region_name=REGION)


@upload_bp.route("/upload", methods=["POST"])
def upload_file():
    db = SessionLocal()
    file = request.files.get("file")

    if not file:
        return jsonify({"error": "No file provided"}), 400

    try:
        s3.upload_fileobj(file, BUCKET_NAME, file.filename)

        new_photo = Photo(
            trip_id=1,
            s3_key=file.filename,
            status="pending",
        )

        db.add(new_photo)
        db.commit()

        return jsonify(
            {
                "message": f"{file.filename} uploaded successfully",
                "status": "pending",
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
