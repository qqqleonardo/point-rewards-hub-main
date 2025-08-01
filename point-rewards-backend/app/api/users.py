# -*- coding: utf-8 -*-
"""
API routes for user-related actions.
- User registration
- Fetching user profile
- Updating user profile
"""
from flask import request, jsonify
from . import api_bp
from app.models import User, UserPoints, PointsHistory
from app.database import db

@api_bp.route('/users/register', methods=['POST']) 
def register_user():
    """
    Registers a new user.
    Expects a JSON payload with 'nickname' and optional 'phone_number'.
    Creates a user, gives them initial points, and logs the transaction.
    """
    data = request.get_json()
    if not data or 'nickname' not in data:
        return jsonify({'error': 'Missing nickname'}), 400

    # Check if phone number is provided and if it already exists
    if 'phone_number' in data and data['phone_number']:
        if User.query.filter_by(phone_number=data['phone_number']).first():
            return jsonify({'error': 'Phone number already registered'}), 409

    # Create new user
    new_user = User(
        nickname=data['nickname'],
        phone_number=data.get('phone_number'),
        address=data.get('address')
    )
    db.session.add(new_user)
    db.session.flush() # Flush to get the new_user.id for foreign key relations

    # Assign initial points (e.g., 100 points for signing up)
    initial_points = 100
    user_points = UserPoints(user_id=new_user.id, points=initial_points)
    db.session.add(user_points)

    # Log the initial points transaction
    points_history = PointsHistory(
        user_id=new_user.id,
        change_amount=initial_points,
        reason='initial_registration'
    )
    db.session.add(points_history)

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to register user', 'details': str(e)}), 500

    return jsonify(new_user.to_dict()), 201

@api_bp.route('/users/<int:user_id>/profile', methods=['GET'])
def get_user_profile(user_id):
    """Fetches a user's profile by their ID."""
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())

@api_bp.route('/users/<int:user_id>/profile', methods=['PATCH'])
def update_user_profile(user_id):
    """
    Updates a user's profile, e.g., their address.
    Expects a JSON payload with fields to update, like 'address'.
    """
    user = User.query.get_or_404(user_id)
    data = request.get_json()

    if not data:
        return jsonify({'error': 'No data provided'}), 400

    if 'address' in data:
        user.address = data['address']
    
    # Add other fields to update as needed
    # if 'nickname' in data:
    #     user.nickname = data['nickname']

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to update profile', 'details': str(e)}), 500

    return jsonify(user.to_dict())
