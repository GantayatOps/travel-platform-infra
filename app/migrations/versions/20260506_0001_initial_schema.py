"""Create initial travel platform schema.

Revision ID: 20260506_0001
Revises:
Create Date: 2026-05-06 00:00:00
"""

from alembic import op


revision = "20260506_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            email VARCHAR NOT NULL UNIQUE,
            created_at TIMESTAMP WITHOUT TIME ZONE
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_users_id ON users (id)")
    op.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_email ON users (email)")

    op.execute(
        """
        CREATE TABLE IF NOT EXISTS trips (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            name VARCHAR NOT NULL,
            start_date TIMESTAMP WITHOUT TIME ZONE,
            end_date TIMESTAMP WITHOUT TIME ZONE,
            created_at TIMESTAMP WITHOUT TIME ZONE,
            CONSTRAINT trips_user_id_fkey
                FOREIGN KEY(user_id) REFERENCES users (id)
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_trips_id ON trips (id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_trips_user_id ON trips (user_id)")

    op.execute(
        """
        CREATE TABLE IF NOT EXISTS expenses (
            id SERIAL PRIMARY KEY,
            trip_id INTEGER NOT NULL,
            amount DOUBLE PRECISION NOT NULL,
            currency VARCHAR,
            category VARCHAR,
            description VARCHAR,
            spent_at TIMESTAMP WITHOUT TIME ZONE,
            created_at TIMESTAMP WITHOUT TIME ZONE,
            CONSTRAINT expenses_trip_id_fkey
                FOREIGN KEY(trip_id) REFERENCES trips (id)
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_expenses_id ON expenses (id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_expenses_trip_id ON expenses (trip_id)")

    op.execute(
        """
        CREATE TABLE IF NOT EXISTS photos (
            id SERIAL PRIMARY KEY,
            trip_id INTEGER NOT NULL,
            s3_bucket VARCHAR NOT NULL,
            s3_key VARCHAR NOT NULL,
            status VARCHAR,
            content_type VARCHAR,
            size INTEGER,
            uploaded_at TIMESTAMP WITHOUT TIME ZONE,
            processed_at TIMESTAMP WITHOUT TIME ZONE,
            created_at TIMESTAMP WITHOUT TIME ZONE,
            CONSTRAINT photos_trip_id_fkey
                FOREIGN KEY(trip_id) REFERENCES trips (id)
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS ix_photos_id ON photos (id)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_photos_trip_id ON photos (trip_id)")

    op.execute(
        """
        INSERT INTO users (id, email, created_at)
        SELECT DISTINCT trips.user_id,
               'mvp-user-' || trips.user_id || '@example.com',
               NOW()
        FROM trips
        WHERE NOT EXISTS (
            SELECT 1 FROM users WHERE users.id = trips.user_id
        )
        """
    )

    op.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITHOUT TIME ZONE")
    op.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITHOUT TIME ZONE")

    op.execute("ALTER TABLE expenses ADD COLUMN IF NOT EXISTS currency VARCHAR")
    op.execute("UPDATE expenses SET currency = 'INR' WHERE currency IS NULL")
    op.execute("ALTER TABLE expenses ADD COLUMN IF NOT EXISTS description VARCHAR")
    op.execute("ALTER TABLE expenses ADD COLUMN IF NOT EXISTS spent_at TIMESTAMP WITHOUT TIME ZONE")

    op.execute("ALTER TABLE photos ADD COLUMN IF NOT EXISTS s3_bucket VARCHAR")
    op.execute("UPDATE photos SET s3_bucket = 'unknown' WHERE s3_bucket IS NULL")
    op.execute("ALTER TABLE photos ALTER COLUMN s3_bucket SET NOT NULL")
    op.execute("ALTER TABLE photos ADD COLUMN IF NOT EXISTS content_type VARCHAR")
    op.execute("ALTER TABLE photos ADD COLUMN IF NOT EXISTS size INTEGER")
    op.execute("ALTER TABLE photos ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMP WITHOUT TIME ZONE")
    op.execute("UPDATE photos SET uploaded_at = created_at WHERE uploaded_at IS NULL")

    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_constraint WHERE conname = 'trips_user_id_fkey'
            ) THEN
                ALTER TABLE trips
                ADD CONSTRAINT trips_user_id_fkey
                FOREIGN KEY (user_id) REFERENCES users (id);
            END IF;
        END $$;
        """
    )


def downgrade():
    op.execute("DROP TABLE IF EXISTS photos")
    op.execute("DROP TABLE IF EXISTS expenses")
    op.execute("DROP TABLE IF EXISTS trips")
    op.execute("DROP TABLE IF EXISTS users")
