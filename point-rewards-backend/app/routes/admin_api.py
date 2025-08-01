#!/usr/bin/env python
# -*- coding: utf-8 -*-
from functools import wraps
from flask import jsonify, request, send_from_directory, current_app
from flask.blueprints import Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import User, Prize, Redemption
from app import db
import os
import uuid
import pandas as pd
from werkzeug.utils import secure_filename
from decimal import Decimal

admin_bp = Blueprint('admin', __name__)

def success_response(message="操作成功", data=None, code=200):
    return jsonify({"code": code, "message": message, "data": data or {}}), code

def error_response(message="操作失败", code=400):
    return jsonify({"code": code, "message": message}), code

# 管理员认证装饰器
def admin_required():
    def wrapper(fn):
        @wraps(fn)
        @jwt_required()
        def decorator(*args, **kwargs):
            user_id = get_jwt_identity()
            current_user = User.query.get(user_id)
            if not current_user or not current_user.is_admin:
                return error_response("管理员权限不足", 403)
            return fn(*args, **kwargs)
        return decorator
    return wrapper

# --- 用户管理 ---
@admin_bp.route('/users', methods=['GET'])
@admin_required()
def get_users():
    users = User.query.all()
    users_data = [{
        'id': u.id, 'nickname': u.nickname, 'kuaishouId': u.kuaishouId, 
        'phone': u.phone, 'points': u.points, 'is_admin': u.is_admin, 'addresses': u.addresses
    } for u in users]
    return success_response("获取用户列表成功", users_data)

@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@admin_required()
def update_user(user_id):
    try:
        data = request.get_json()
        user = User.query.get(user_id)
        
        if not user:
            return error_response("用户不存在", 404)
        
        # 更新用户信息
        if 'nickname' in data:
            user.nickname = data['nickname']
        if 'kuaishouId' in data:
            # 检查快手ID是否已被其他用户使用
            existing_user = User.query.filter(User.kuaishouId == data['kuaishouId'], User.id != user_id).first()
            if existing_user:
                return error_response("该快手ID已被其他用户使用", 400)
            user.kuaishouId = data['kuaishouId']
        if 'phone' in data:
            # 检查手机号是否已被其他用户使用
            existing_user = User.query.filter(User.phone == data['phone'], User.id != user_id).first()
            if existing_user:
                return error_response("该手机号已被其他用户使用", 400)
            user.phone = data['phone']
        if 'points' in data:
            user.points = data['points']
        if 'is_admin' in data:
            user.is_admin = data['is_admin']
        
        db.session.commit()
        
        user_data = {
            'id': user.id,
            'nickname': user.nickname,
            'kuaishouId': user.kuaishouId,
            'phone': user.phone,
            'points': user.points,
            'is_admin': user.is_admin
        }
        
        return success_response("用户信息更新成功", user_data)
        
    except Exception as e:
        db.session.rollback()
        return error_response(f"更新用户信息失败: {str(e)}", 500)

# --- 奖品管理 ---
@admin_bp.route('/prizes', methods=['GET'])
@admin_required()
def get_prizes():
    prizes = Prize.query.all()
    prizes_data = [{
        'id': p.id, 'name': p.name, 'description': p.description, 'points': p.points, 
        'category': p.category, 'stock': p.stock, 'image': p.image
    } for p in prizes]
    return success_response("获取奖品列表成功", prizes_data)

@admin_bp.route('/prizes', methods=['POST'])
@admin_required()
def create_prize():
    try:
        data = request.get_json()
        
        # 验证必需字段
        required_fields = ['name', 'points']
        for field in required_fields:
            if field not in data or not data[field]:
                return error_response(f"缺少必需字段: {field}", 400)
        
        # 创建新奖品
        new_prize = Prize(
            name=data['name'],
            description=data.get('description', ''),
            points=data['points'],
            category=data.get('category', ''),
            stock=data.get('stock', 10),  # 默认库存为10
            image=data.get('image', '')
        )
        
        db.session.add(new_prize)
        db.session.commit()
        
        prize_data = {
            'id': new_prize.id,
            'name': new_prize.name,
            'description': new_prize.description,
            'points': new_prize.points,
            'category': new_prize.category,
            'stock': new_prize.stock,
            'image': new_prize.image
        }
        
        return success_response("奖品创建成功", prize_data, 201)
        
    except Exception as e:
        db.session.rollback()
        return error_response(f"创建奖品失败: {str(e)}", 500)

@admin_bp.route('/prizes/<int:prize_id>', methods=['PUT'])
@admin_required()
def update_prize(prize_id):
    try:
        data = request.get_json()
        prize = Prize.query.get(prize_id)
        
        if not prize:
            return error_response("奖品不存在", 404)
        
        # 更新奖品信息
        if 'name' in data:
            prize.name = data['name']
        if 'description' in data:
            prize.description = data['description']
        if 'points' in data:
            prize.points = data['points']
        if 'category' in data:
            prize.category = data['category']
        if 'stock' in data:
            prize.stock = data['stock']
        if 'image' in data:
            prize.image = data['image']
        
        db.session.commit()
        
        prize_data = {
            'id': prize.id,
            'name': prize.name,
            'description': prize.description,
            'points': prize.points,
            'category': prize.category,
            'stock': prize.stock,
            'image': prize.image
        }
        
        return success_response("奖品信息更新成功", prize_data)
        
    except Exception as e:
        db.session.rollback()
        return error_response(f"更新奖品信息失败: {str(e)}", 500)

# --- 兑换记录 ---
@admin_bp.route('/redemptions', methods=['GET'])
@admin_required()
def get_redemptions():
    redemptions = Redemption.query.order_by(Redemption.created_at.desc()).all()
    redemptions_data = [{
        'id': r.id, 'user_id': r.user_id, 'prize_id': r.prize_id, 'prize_name': r.prize.name,
        'points_spent': r.points_spent, 'status': r.status, 'shipping_address': r.shipping_address,
        'created_at': r.created_at.isoformat()
    } for r in redemptions]
    return success_response("获取兑换记录成功", redemptions_data)

# --- 文件上传 ---
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'xlsx', 'xls'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@admin_bp.route('/upload', methods=['POST'])
@admin_required()
def upload_file():
    try:
        if 'file' not in request.files:
            return error_response("没有选择文件", 400)
        
        file = request.files['file']
        if file.filename == '':
            return error_response("没有选择文件", 400)
        
        if not allowed_file(file.filename):
            return error_response("不支持的文件格式，仅支持: png, jpg, jpeg, gif, webp, xlsx, xls", 400)
        
        # 生成唯一文件名
        filename = secure_filename(file.filename)
        file_extension = filename.rsplit('.', 1)[1].lower()
        unique_filename = f"{uuid.uuid4().hex}.{file_extension}"
        
        # 确保上传目录存在
        upload_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'static', 'uploads')
        os.makedirs(upload_dir, exist_ok=True)
        
        # 保存文件
        file_path = os.path.join(upload_dir, unique_filename)
        file.save(file_path)
        
        # 返回文件URL
        file_url = f"/static/uploads/{unique_filename}"
        
        return success_response("文件上传成功", {"url": file_url, "filename": unique_filename})
        
    except Exception as e:
        return error_response(f"文件上传失败: {str(e)}", 500)

# --- 流水上传处理 ---
@admin_bp.route('/download-template', methods=['GET'])
@admin_required()
def download_template():
    """下载Excel模板文件"""
    try:
        # 获取模板文件路径
        template_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '上传模板.xlsx')
        
        # 检查文件是否存在
        if not os.path.exists(template_path):
            return error_response("模板文件不存在", 404)
        
        # 直接返回文件
        return send_from_directory(
            os.path.dirname(template_path),
            '上传模板.xlsx',
            as_attachment=True,
            download_name='积分流水模板.xlsx'
        )
        
    except Exception as e:
        return error_response(f"下载模板文件失败: {str(e)}", 500)

@admin_bp.route('/upload-transaction', methods=['POST'])
@admin_required()
def upload_transaction():
    try:
        if 'file' not in request.files:
            return error_response("没有选择文件", 400)
        
        file = request.files['file']
        if file.filename == '':
            return error_response("没有选择文件", 400)
        
        # 检查文件格式
        if not file.filename.lower().endswith(('.xlsx', '.xls')):
            return error_response("仅支持Excel文件格式(.xlsx, .xls)", 400)
        
        # 读取Excel文件
        try:
            df = pd.read_excel(file, header=0)
        except Exception as e:
            return error_response(f"读取Excel文件失败: {str(e)}", 400)
        
        # 验证Excel格式
        if len(df.columns) < 3:
            return error_response("Excel文件格式不正确，需要至少3列：快手ID、主播名称、流水", 400)
        
        # 重命名列名以便处理
        df.columns = ['kuaishou_id', 'anchor_name', 'transaction', *df.columns[3:]]
        
        # 数据处理统计
        updated_count = 0
        not_found_count = 0
        error_records = []
        
        for index, row in df.iterrows():
            try:
                kuaishou_id = str(row['kuaishou_id']).strip()
                transaction = float(row['transaction']) if pd.notna(row['transaction']) else 0
                
                # 跳过空的快手ID行
                if not kuaishou_id or kuaishou_id == 'nan':
                    continue
                
                # 计算积分：流水 / 10
                points = Decimal(str(transaction / 10))
                
                # 查找用户
                user = User.query.filter_by(kuaishouId=kuaishou_id).first()
                if user:
                    # 更新用户积分（直接覆盖）
                    user.points = points
                    updated_count += 1
                else:
                    not_found_count += 1
                    error_records.append({
                        'row': index + 2,  # Excel行号（从2开始，因为有标题行）
                        'kuaishou_id': kuaishou_id,
                        'reason': '用户不存在'
                    })
                    
            except Exception as e:
                error_records.append({
                    'row': index + 2,
                    'kuaishou_id': str(row.get('kuaishou_id', '未知')),
                    'reason': f'数据处理错误: {str(e)}'
                })
        
        # 提交数据库更改
        db.session.commit()
        
        # 返回处理结果
        result = {
            'updated_count': updated_count,
            'not_found_count': not_found_count,
            'total_processed': len(df),
            'error_records': error_records  # 返回所有错误记录
        }
        
        return success_response("流水数据处理完成", result)
        
    except Exception as e:
        db.session.rollback()
        return error_response(f"处理流水数据失败: {str(e)}", 500)

@admin_bp.route('/static/uploads/<filename>')
def uploaded_file(filename):
    """提供上传文件的访问"""
    upload_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'static', 'uploads')
    return send_from_directory(upload_dir, filename)
