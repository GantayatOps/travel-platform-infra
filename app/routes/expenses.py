from flask import Blueprint, jsonify, request

from db import SessionLocal
from models import Expense, Trip

expenses_bp = Blueprint("expenses", __name__)


@expenses_bp.route("/expenses", methods=["POST"])
def create_expense():
    db = SessionLocal()
    try:
        data = request.get_json()

        if not data or "trip_id" not in data or "amount" not in data:
            return jsonify({"error": "trip_id and amount required"}), 400

        trip = db.query(Trip).filter(Trip.id == data.get("trip_id")).first()
        if not trip:
            return jsonify({"error": "trip not found"}), 404

        expense = Expense(
            trip_id=data.get("trip_id"),
            amount=data.get("amount"),
            category=data.get("category", "general"),
        )

        db.add(expense)
        db.commit()
        db.refresh(expense)

        return jsonify({"id": expense.id})
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()


@expenses_bp.route("/expenses/<int:trip_id>", methods=["GET"])
def get_expenses(trip_id):
    db = SessionLocal()
    try:
        expenses = db.query(Expense).filter(Expense.trip_id == trip_id).all()

        return jsonify(
            [
                {
                    "id": e.id,
                    "amount": e.amount,
                    "category": e.category,
                }
                for e in expenses
            ]
        )
    finally:
        db.close()
