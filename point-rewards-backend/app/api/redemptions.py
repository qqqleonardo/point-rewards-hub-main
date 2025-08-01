# -*- coding: utf-8 -*-
"""
API route for handling prize redemptions.
"""
from flask import request, jsonify
from . import api_bp
from app.models import User, Prize, Redemption, UserPoints, PointsHistory
from app.database import db

@api_bp.route('/redemptions', methods=['POST'])
def redeem_prize():
    """
    Handles a user's request to redeem a prize.
    Expects {'user_id': <id>, 'prize_id': <id>}.
    This is a transactional operation:
    1. Validates the request.
    2. Checks user points and prize stock.
    3. Creates a redemption record.
    4. Deducts user points.
    5. Logs the points change.
    6. Decrements prize stock.
    All steps must succeed, or none will.
    """
    data = request.get_json()
    if not data or 'user_id' not in data or 'prize_id' not in data:
        return jsonify({'error': 'Missing user_id or prize_id'}), 400

    user_id = data['user_id']
    prize_id = data['prize_id']

    # Use a transaction to ensure atomicity
    try:
        with db.session.begin_nested(): # Use nested transaction or savepoints
            # 1. Fetch and lock rows to prevent race conditions
            user_points = UserPoints.query.with_for_update().filter_by(user_id=user_id).one()
            prize = Prize.query.with_for_update().get(prize_id)

            # 2. Perform checks
            if not prize:
                return jsonify({'error': 'Prize not found'}), 404
            if not prize.is_active:
                return jsonify({'error': 'Prize is not available for redemption'}), 400
            if prize.stock <= 0:
                return jsonify({'error': 'Prize is out of stock'}), 400
            if user_points.points < prize.points:
                return jsonify({'error': 'Insufficient points'}), 400

            # 3. Create redemption record
            new_redemption = Redemption(
                user_id=user_id,
                prize_id=prize_id,
                points_spent=prize.points
            )
            db.session.add(new_redemption)
            db.session.flush() # To get the new_redemption.id

            # 4. Deduct user points
            user_points.points -= prize.points

            # 5. Log the points change
            points_history = PointsHistory(
                user_id=user_id,
                change_amount=-prize.points,
                reason='prize_redemption',
                related_id=new_redemption.id
            )
            db.session.add(points_history)

            # 6. Decrement prize stock
            prize.stock -= 1

        db.session.commit()

    except Exception as e:
        db.session.rollback()
        # Log the exception e
        return jsonify({'error': 'Redemption failed due to an internal error', 'details': str(e)}), 500

    return jsonify({'message': 'Redemption successful', 'new_points': user_points.points}), 200
