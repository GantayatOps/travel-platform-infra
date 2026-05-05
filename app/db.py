import json
import os

import boto3
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_SECRET_ARN = os.getenv("DB_SECRET_ARN")
AWS_REGION = os.getenv("AWS_REGION")


def _load_db_password():
    if DB_PASSWORD:
        return DB_PASSWORD

    if not DB_SECRET_ARN:
        return None

    client = boto3.client("secretsmanager", region_name=AWS_REGION)
    response = client.get_secret_value(SecretId=DB_SECRET_ARN)
    secret = json.loads(response["SecretString"])
    return secret["password"]


RESOLVED_DB_PASSWORD = _load_db_password()

if not all([DB_HOST, DB_NAME, DB_USER, RESOLVED_DB_PASSWORD]):
    raise ValueError("Missing DB environment variables")

DATABASE_URL = f"postgresql://{DB_USER}:{RESOLVED_DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(bind=engine)

def test_connection():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
