from datetime import datetime

from flask import Blueprint, jsonify, request
from sqlalchemy import func

from db import SessionLocal
from models import Expense, Trip, User

trips_bp = Blueprint("trips", __name__)
MVP_USER_ID = 1
MVP_USER_EMAIL = "demo@example.com"


def _parse_datetime(value, field_name):
    if value in (None, ""):
        return None

    if isinstance(value, str):
        normalized = value.replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(normalized)
        except ValueError:
            raise ValueError(f"{field_name} must be a valid ISO 8601 datetime")

    raise ValueError(f"{field_name} must be a string")


def _serialize_trip(trip):
    return {
        "id": trip.id,
        "user_id": trip.user_id,
        "name": trip.name,
        "start_date": trip.start_date.isoformat() if trip.start_date else None,
        "end_date": trip.end_date.isoformat() if trip.end_date else None,
        "created_at": trip.created_at.isoformat() if trip.created_at else None,
    }


def _ensure_mvp_user(db):
    user = db.query(User).filter(User.id == MVP_USER_ID).first()
    if user:
        return user

    user = User(id=MVP_USER_ID, email=MVP_USER_EMAIL)
    db.add(user)
    db.flush()
    return user


@trips_bp.route("/trips", methods=["POST"])
def create_trip():
    db = SessionLocal()
    try:
        data = request.get_json()

        if not data or "name" not in data:
            return jsonify({"error": "name is required"}), 400

        try:
            start_date = _parse_datetime(data.get("start_date"), "start_date")
            end_date = _parse_datetime(data.get("end_date"), "end_date")
        except ValueError as e:
            return jsonify({"error": str(e)}), 400

        _ensure_mvp_user(db)
        trip = Trip(
            user_id=MVP_USER_ID,
            name=data.get("name"),
            start_date=start_date,
            end_date=end_date,
        )

        db.add(trip)
        db.commit()
        db.refresh(trip)

        return jsonify(_serialize_trip(trip)), 201
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()


@trips_bp.route("/trips", methods=["GET"])
def list_trips():
    db = SessionLocal()
    try:
        trips = db.query(Trip).all()

        return jsonify([_serialize_trip(t) for t in trips])
    finally:
        db.close()


@trips_bp.route("/trips/<int:trip_id>/total", methods=["GET"])
def get_trip_total(trip_id):
    db = SessionLocal()
    try:
        total = (
            db.query(func.sum(Expense.amount))
            .filter(Expense.trip_id == trip_id)
            .scalar()
        )

        return jsonify({"trip_id": trip_id, "total_expense": total or 0})
    finally:
        db.close()


@trips_bp.route("/trips/<int:trip_id>/category-summary", methods=["GET"])
def category_summary(trip_id):
    db = SessionLocal()
    try:
        results = (
            db.query(Expense.category, func.sum(Expense.amount))
            .filter(Expense.trip_id == trip_id)
            .group_by(Expense.category)
            .all()
        )

        return jsonify({category: total for category, total in results})
    finally:
        db.close()
