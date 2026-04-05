from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float
from sqlalchemy.orm import declarative_base
from datetime import datetime, timezone

Base = declarative_base()


class Trip(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer)
    name = Column(String)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True)
    trip_id = Column(Integer, ForeignKey("trips.id"))
    amount = Column(Float)
    category = Column(String)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Photo(Base):
    __tablename__ = "photos"

    id = Column(Integer, primary_key=True)
    trip_id = Column(Integer)
    s3_key = Column(String)
    status = Column(String, default="pending")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))