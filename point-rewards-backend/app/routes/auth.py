from flask import request, jsonify
from flask.blueprints import Blueprint
from app.models import User
from app import db
from flask_jwt_extended import create_access_token
from app.encryption import decrypt_password, is_encrypted_password

auth_bp = Blueprint('auth', __name__)

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

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # 参数验证
        required_fields = ['nickname', 'kuaishouId', 'phone', 'password']
        for field in required_fields:
            if not data.get(field):
                return error_response(f"缺少必填字段: {field}", 400)
        
        # 检查手机号或快手ID是否已存在
        if User.query.filter_by(phone=data['phone']).first():
            return error_response("该手机号已被注册", 400)
        if User.query.filter_by(kuaishouId=data['kuaishouId']).first():
            return error_response("该快手ID已被注册", 400)

        # 解密密码
        encrypted_password = data['password']
        try:
            if is_encrypted_password(encrypted_password):
                plain_password = decrypt_password(encrypted_password)
            else:
                plain_password = encrypted_password  # 如果不是加密的，直接使用
        except Exception as e:
            return error_response(f"密码解密失败: {str(e)}", 400)

        new_user = User(
            nickname=data['nickname'],
            kuaishouId=data['kuaishouId'],
            phone=data['phone'],
            addresses=[]
        )
        new_user.set_password(plain_password)  # 使用解密后的密码设置哈希
        db.session.add(new_user)
        db.session.commit()
        
        user_data = {
            "id": new_user.id,
            "nickname": new_user.nickname,
            "kuaishouId": new_user.kuaishouId,
            "phone": new_user.phone,
            "points": new_user.points
        }
        
        return success_response("用户注册成功", user_data, 201)
    
    except Exception as e:
        db.session.rollback()
        return error_response(f"注册失败: {str(e)}", 500)

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # 参数验证
        if not data.get('phone') or not data.get('password'):
            return error_response("手机号和密码不能为空", 400)
        
        user = User.query.filter_by(phone=data['phone']).first()
        
        if not user:
            return error_response("手机号或密码错误", 401)
        
        # 解密密码
        encrypted_password = data['password']
        try:
            if is_encrypted_password(encrypted_password):
                plain_password = decrypt_password(encrypted_password)
            else:
                plain_password = encrypted_password  # 如果不是加密的，直接使用
        except Exception as e:
            return error_response(f"密码解密失败: {str(e)}", 400)
        
        if user.check_password(plain_password):
            access_token = create_access_token(identity=str(user.id))  # 转换为字符串
            user_data = {
                "id": user.id,
                "nickname": user.nickname,
                "kuaishouId": user.kuaishouId,
                "phone": user.phone,
                "points": user.points,
                "addresses": user.addresses or [],
                "is_admin": user.is_admin,
                "access_token": access_token
            }
            return success_response("登录成功", user_data)
        
        return error_response("手机号或密码错误", 401)
    
    except Exception as e:
        return error_response(f"登录失败: {str(e)}", 500)
