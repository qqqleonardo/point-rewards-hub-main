# -*- coding: utf-8 -*-
"""
API routes for prize-related actions.
- Fetching all prizes
- (Optional) Adding new prizes
"""
from flask import jsonify, request
from . import api_bp
from app.models import Prize
from app.database import db

@api_bp.route('/prizes', methods=['GET'])
def get_prizes():
    """Returns a list of all active prizes."""
    prizes = Prize.query.filter_by(is_active=True).order_by(Prize.points).all()
    return jsonify([prize.to_dict() for prize in prizes])

# Example of a route to add a new prize (for admin purposes)
@api_bp.route('/prizes', methods=['POST'])
def add_prize():
    """
    Adds a new prize to the catalog.
    This is a sample route, likely for admin use in a real app.
    """
    data = request.get_json()
    if not data or not all(k in data for k in ['name', 'points', 'stock']):
        return jsonify({'error': 'Missing required fields: name, points, stock'}), 400

    new_prize = Prize(
        name=data['name'],
        description=data.get('description'),
        points=data['points'],
        stock=data['stock'],
        image_url=data.get('image_url'),
        category=data.get('category')
    )
    db.session.add(new_prize)
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to add prize', 'details': str(e)}), 500

    return jsonify(new_prize.to_dict()), 201
