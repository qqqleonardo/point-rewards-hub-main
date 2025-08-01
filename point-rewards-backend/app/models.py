from app import db
from datetime import datetime
from app.encryption import encrypt_password, decrypt_password

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nickname = db.Column(db.String(80), nullable=False)
    kuaishouId = db.Column(db.String(80), unique=True, nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    password_encrypted = db.Column(db.Text, nullable=False)  # 存储加密后的密码
    points = db.Column(db.DECIMAL(10, 2), nullable=False, default=10.00)  # 支持小数点积分，初始给10积分
    addresses = db.Column(db.JSON, nullable=True, default=[])
    is_admin = db.Column(db.Boolean, nullable=False, default=False) # 管理员标识
    redemptions = db.relationship('Redemption', backref='user', lazy=True)

    def set_password(self, plain_password):
        """设置密码（存储加密后的密码）"""
        self.password_encrypted = encrypt_password(plain_password)

    def check_password(self, plain_password):
        """验证密码"""
        try:
            stored_password = decrypt_password(self.password_encrypted)
            return stored_password == plain_password
        except:
            return False
    
    def get_decrypted_password(self):
        """管理员用：获取解密后的密码"""
        try:
            return decrypt_password(self.password_encrypted)
        except:
            return None

class Prize(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    image = db.Column(db.String(200), nullable=True)
    points = db.Column(db.DECIMAL(10, 2), nullable=False)  # 支持小数点积分
    category = db.Column(db.String(50), nullable=True)
    stock = db.Column(db.Integer, nullable=False, default=10) # 默认库存10

class Redemption(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    prize_id = db.Column(db.Integer, db.ForeignKey('prize.id'), nullable=False)
    points_spent = db.Column(db.DECIMAL(10, 2), nullable=False)  # 支持小数点积分
    status = db.Column(db.String(50), nullable=False, default='completed') # 默认状态为完成
    shipping_address = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    prize = db.relationship('Prize')
