from flask import Blueprint, jsonify, request
from sqlalchemy import func

from db import SessionLocal
from models import Expense, Trip

trips_bp = Blueprint("trips", __name__)


@trips_bp.route("/trips", methods=["POST"])
def create_trip():
    db = SessionLocal()
    try:
        data = request.get_json()

        if not data or "name" not in data:
            return jsonify({"error": "name is required"}), 400

        trip = Trip(user_id=1, name=data.get("name"))

        db.add(trip)
        db.commit()
        db.refresh(trip)

        return jsonify({"id": trip.id})
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

        return jsonify([{"id": t.id, "name": t.name} for t in trips])
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
