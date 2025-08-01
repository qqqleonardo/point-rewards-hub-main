from flask import request, jsonify
from flask.blueprints import Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Redemption, User, Prize

redemptions_bp = Blueprint('redemptions', __name__)

def success_response(message="操作成功", data=None, code=200):
    """统一成功响应格式"""
    response = {
        "code": code,
        "message": message,
        "data": data or {}
    }
    return jsonify(response), code, {'Content-Type': 'application/json; charset=utf-8'}

def error_response(message="操作失败", code=400, data=None):
    """统一错误响应格式"""
    response = {
        "code": code,
        "message": message,
        "data": data or {}
    }
    return jsonify(response), code, {'Content-Type': 'application/json; charset=utf-8'}

@redemptions_bp.route('/redeem', methods=['POST'])
@jwt_required()
def redeem_prize():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        prize_id = data.get('prize_id')
        shipping_address = data.get('shipping_address')

        user = User.query.get(user_id)
        prize = Prize.query.get(prize_id)

        if not prize:
            return error_response("奖品不存在", 404)

        if prize.stock <= 0:
            return error_response("奖品库存不足", 400)

        if user.points < prize.points:
            return error_response("用户积分不足", 400)

        # 执行兑换
        user.points -= prize.points
        prize.stock -= 1
        
        new_redemption = Redemption(
            user_id=user.id,
            prize_id=prize.id,
            points_spent=prize.points,
            shipping_address=shipping_address
        )
        
        db.session.add(new_redemption)
        db.session.commit()

        return success_response("兑换成功")
    except Exception as e:
        db.session.rollback()
        return error_response(f"兑换失败: {str(e)}", 500)


@redemptions_bp.route('/history', methods=['GET'])
@jwt_required()
def get_history():
    try:
        user_id = get_jwt_identity()
        redemptions = Redemption.query.filter_by(user_id=user_id).order_by(Redemption.created_at.desc()).all()
        
        history_list = [
            {
                "id": r.id,
                "prize_name": r.prize.name,
                "points_spent": r.points_spent,
                "status": r.status,
                "created_at": r.created_at.isoformat(),
                "shipping_address": r.shipping_address
            } for r in redemptions
        ]
        
        return success_response("获取兑换历史成功", history_list)
    except Exception as e:
        return error_response(f"获取兑换历史失败: {str(e)}", 500)
