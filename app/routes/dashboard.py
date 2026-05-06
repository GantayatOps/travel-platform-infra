from flask import Blueprint, render_template
from sqlalchemy import func
from sqlalchemy.orm import joinedload, selectinload

from db import SessionLocal
from models import Expense, Photo, Trip

dashboard_bp = Blueprint("dashboard", __name__)


def _as_float(value):
    return float(value or 0)


@dashboard_bp.route("/dashboard", methods=["GET"])
def dashboard():
    db = SessionLocal()
    try:
        trips = (
            db.query(Trip)
            .options(selectinload(Trip.expenses), selectinload(Trip.photos))
            .order_by(Trip.created_at.desc())
            .all()
        )
        recent_expenses = (
            db.query(Expense)
            .options(joinedload(Expense.trip))
            .order_by(Expense.created_at.desc())
            .limit(12)
            .all()
        )
        recent_photos = (
            db.query(Photo)
            .options(joinedload(Photo.trip))
            .order_by(Photo.created_at.desc())
            .limit(12)
            .all()
        )
        category_totals = (
            db.query(Expense.category, func.sum(Expense.amount).label("total"))
            .group_by(Expense.category)
            .order_by(func.sum(Expense.amount).desc())
            .all()
        )

        total_expense = db.query(func.coalesce(func.sum(Expense.amount), 0)).scalar()
        processed_photos = (
            db.query(func.count(Photo.id))
            .filter(Photo.status == "processed")
            .scalar()
        )
        pending_photos = (
            db.query(func.count(Photo.id))
            .filter(Photo.status == "pending")
            .scalar()
        )

        trip_summaries = []
        for trip in trips:
            trip_total = sum(_as_float(expense.amount) for expense in trip.expenses)
            trip_summaries.append(
                {
                    "trip": trip,
                    "expense_total": trip_total,
                    "expense_count": len(trip.expenses),
                    "photo_count": len(trip.photos),
                    "processed_photo_count": sum(
                        1 for photo in trip.photos if photo.status == "processed"
                    ),
                }
            )

        stats = {
            "trip_count": len(trips),
            "expense_count": sum(len(trip.expenses) for trip in trips),
            "photo_count": sum(len(trip.photos) for trip in trips),
            "total_expense": _as_float(total_expense),
            "processed_photos": processed_photos or 0,
            "pending_photos": pending_photos or 0,
        }

        return render_template(
            "dashboard.html",
            stats=stats,
            trip_summaries=trip_summaries,
            recent_expenses=recent_expenses,
            recent_photos=recent_photos,
            category_totals=category_totals,
        )
    finally:
        db.close()
