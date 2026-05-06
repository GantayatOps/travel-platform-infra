from datetime import datetime
from math import isfinite

from flask import Blueprint, jsonify, request

from db import SessionLocal
from models import Expense, Trip

expenses_bp = Blueprint("expenses", __name__)


def _serialize_expense(expense):
    return {
        "id": expense.id,
        "trip_id": expense.trip_id,
        "amount": expense.amount,
        "currency": expense.currency,
        "category": expense.category,
        "description": expense.description,
        "spent_at": expense.spent_at.isoformat() if expense.spent_at else None,
        "created_at": expense.created_at.isoformat() if expense.created_at else None,
    }


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


def _parse_positive_amount(value):
    if isinstance(value, bool):
        raise ValueError("amount must be a number greater than 0")

    try:
        amount = float(value)
    except (TypeError, ValueError):
        raise ValueError("amount must be a number greater than 0")

    if not isfinite(amount) or amount <= 0:
        raise ValueError("amount must be a number greater than 0")

    return amount


def _create_expense_for_trip(trip_id):
    db = SessionLocal()
    try:
        data = request.get_json()

        if not data or "amount" not in data:
            return jsonify({"error": "amount is required"}), 400

        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            return jsonify({"error": "trip not found"}), 404

        try:
            amount = _parse_positive_amount(data.get("amount"))
            spent_at = _parse_datetime(data.get("spent_at"), "spent_at")
        except ValueError as e:
            return jsonify({"error": str(e)}), 400

        expense = Expense(
            trip_id=trip_id,
            amount=amount,
            currency=data.get("currency", "INR"),
            category=data.get("category", "general"),
            description=data.get("description"),
            spent_at=spent_at,
        )

        db.add(expense)
        db.commit()
        db.refresh(expense)

        return jsonify(_serialize_expense(expense)), 201
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()


def _list_expenses_for_trip(trip_id):
    db = SessionLocal()
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            return jsonify({"error": "trip not found"}), 404

        expenses = db.query(Expense).filter(Expense.trip_id == trip_id).all()

        return jsonify([_serialize_expense(e) for e in expenses])
    finally:
        db.close()


@expenses_bp.route("/trips/<int:trip_id>/expenses", methods=["POST"])
def create_trip_expense(trip_id):
    return _create_expense_for_trip(trip_id)


@expenses_bp.route("/trips/<int:trip_id>/expenses", methods=["GET"])
def list_trip_expenses(trip_id):
    return _list_expenses_for_trip(trip_id)


@expenses_bp.route("/expenses", methods=["POST"])
def create_expense():
    data = request.get_json()
    if not data or "trip_id" not in data:
        return jsonify({"error": "trip_id is required"}), 400

    return _create_expense_for_trip(data.get("trip_id"))


@expenses_bp.route("/expenses/<int:trip_id>", methods=["GET"])
def get_expenses(trip_id):
    return _list_expenses_for_trip(trip_id)
