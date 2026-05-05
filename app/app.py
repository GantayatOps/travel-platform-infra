from flask import Flask

from db import engine, test_connection
from models import Base
from routes.expenses import expenses_bp
from routes.trips import trips_bp
from routes.upload import upload_bp

app = Flask(__name__)

app.register_blueprint(trips_bp)
app.register_blueprint(expenses_bp)
app.register_blueprint(upload_bp)


@app.route("/")
def home():
    return "Hello from Python Docker App on Private EC2 v4"


@app.route("/healthz")
def health():
    try:
        test_connection()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500


if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    app.run(host="0.0.0.0", port=3000)
