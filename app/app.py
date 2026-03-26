from flask import Flask, request, jsonify
import boto3

app = Flask(__name__)

# S3 client (uses IAM role automatically)
s3 = boto3.client("s3")

BUCKET_NAME = "app_bucket"  # replace if actual bucket name differs

@app.route("/")
def home():
    return "Hello from Python Docker App on Private EC2"

# Upload file to S3
@app.route("/upload", methods=["POST"])
def upload_file():
    file = request.files.get("file")

    if not file:
        return jsonify({"error": "No file provided"}), 400

    try:
        s3.upload_fileobj(file, BUCKET_NAME, file.filename)
        return jsonify({"message": f"{file.filename} uploaded successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Generate presigned URL to access file
@app.route("/get/<filename>", methods=["GET"])
def get_file(filename):
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET_NAME, "Key": filename},
            ExpiresIn=3600
        )
        return jsonify({"url": url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)