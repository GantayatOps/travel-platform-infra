import json
import os
from logging.config import fileConfig

import boto3
from alembic import context
from sqlalchemy import engine_from_config, pool
from sqlalchemy.engine import URL

from models import Base

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def get_db_password():
    password = os.getenv("DB_PASSWORD")
    secret_arn = os.getenv("DB_SECRET_ARN")

    if not secret_arn:
        return password

    client = boto3.client(
        "secretsmanager",
        region_name=os.getenv("AWS_REGION"),
    )
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response["SecretString"])
    return secret["password"]


def get_database_url():
    db_host = os.getenv("DB_HOST")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_password = get_db_password()

    if not all([db_host, db_name, db_user, db_password]):
        raise ValueError("Missing database environment variables for Alembic")

    return URL.create(
        "postgresql+psycopg2",
        username=db_user,
        password=db_password,
        host=db_host,
        port=5432,
        database=db_name,
    )


def get_database_url_string():
    return get_database_url().render_as_string(hide_password=False)


def run_migrations_offline():
    context.configure(
        url=get_database_url_string(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_database_url_string()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
