from flask import jsonify
from flask.blueprints import Blueprint
from app.models import Prize

prizes_bp = Blueprint('prizes', __name__)

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

@prizes_bp.route('', methods=['GET'])
@prizes_bp.route('/', methods=['GET'])
def get_prizes():
    try:
        prizes = Prize.query.all()
        prizes_list = [
            {
                "id": prize.id,
                "name": prize.name,
                "description": prize.description,
                "image": prize.image,
                "points": prize.points,
                "category": prize.category,
                "stock": prize.stock
            } for prize in prizes
        ]
        return success_response("获取奖品列表成功", prizes_list)
    except Exception as e:
        return error_response(f"获取奖品列表失败: {str(e)}", 500)
