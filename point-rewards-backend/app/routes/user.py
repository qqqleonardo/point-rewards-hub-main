from flask import jsonify, request
from flask.blueprints import Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import User
from app import db

user_bp = Blueprint('user', __name__)

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

@user_bp.route('/me', methods=['GET'])
@jwt_required()
def get_me():
    try:
        user_id = int(get_jwt_identity())  # 转换为整数
        user = User.query.get(user_id)
        if not user:
            return error_response("用户不存在", 404)
        
        # 只返回经常变化的核心信息，减少数据传输
        user_data = {
            "points": user.points,  # 积分（经常变化）
            "addresses": user.addresses or []  # 地址（可能变化）
        }
        
        return success_response("获取用户信息成功", user_data)
    
    except Exception as e:
        return error_response(f"获取用户信息失败: {str(e)}", 500)

@user_bp.route('/address', methods=['PUT'])
@jwt_required()
def update_address():
    try:
        user_id = int(get_jwt_identity())  # 转换为整数
        user = User.query.get(user_id)
        if not user:
            return error_response("用户不存在", 404)

        data = request.get_json()
        new_address = data.get('address')

        if not new_address or not isinstance(new_address, str):
            return error_response("地址不能为空", 400)

        # 更新地址（这里简化为只存储一个地址字符串）
        user.addresses = [new_address]  # 存储为数组格式，方便以后扩展多地址
        db.session.commit()

        user_data = {
            "id": user.id,
            "nickname": user.nickname,
            "kuaishouId": user.kuaishouId,
            "phone": user.phone,
            "points": user.points,
            "addresses": user.addresses
        }

        return success_response("地址更新成功", user_data)
    
    except Exception as e:
        db.session.rollback()
        return error_response(f"地址更新失败: {str(e)}", 500)

# 保留原有的批量更新地址API（兼容性）
@user_bp.route('/addresses', methods=['PUT'])
@jwt_required()
def update_addresses():
    try:
        user_id = int(get_jwt_identity())  # 转换为整数
        user = User.query.get(user_id)
        if not user:
            return error_response("用户不存在", 404)

        data = request.get_json()
        new_addresses = data.get('addresses')

        if not isinstance(new_addresses, list):
            return error_response("地址格式无效，必须是一个列表", 400)

        user.addresses = new_addresses
        db.session.commit()

        user_data = {
            "id": user.id,
            "nickname": user.nickname,
            "kuaishouId": user.kuaishouId,
            "phone": user.phone,
            "points": user.points,
            "addresses": user.addresses
        }

        return success_response("地址更新成功", user_data)
    
    except Exception as e:
        db.session.rollback()
        return error_response(f"地址更新失败: {str(e)}", 500)
