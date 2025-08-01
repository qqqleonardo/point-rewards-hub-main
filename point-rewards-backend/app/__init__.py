from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import Config
import sys

# 确保Python使用UTF-8编码
if sys.version_info[0] >= 3:
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())

# 初始化扩展
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # 解决中文乱码问题
    app.json.ensure_ascii = False

    # 将扩展与应用实例绑定
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    # 配置CORS，允许所有来源访问
    CORS(app, 
         origins=['*'],
         allow_headers=['Content-Type', 'Authorization'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

    # 注册蓝图（API路由）
    from app.routes.auth import auth_bp
    from app.routes.user import user_bp
    from app.routes.prizes import prizes_bp
    from app.routes.redemptions import redemptions_bp
    from app.routes.admin_api import admin_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(user_bp, url_prefix='/api/user')
    app.register_blueprint(prizes_bp, url_prefix='/api/prizes')
    app.register_blueprint(redemptions_bp, url_prefix='/api/redemptions')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')

    # 静态文件服务
    import os
    from flask import send_from_directory
    
    @app.route('/static/uploads/<filename>')
    def uploaded_file(filename):
        upload_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'static', 'uploads')
        return send_from_directory(upload_dir, filename)

    return app

# 导入模型，以便 Flask-Migrate 可以检测到它们
from app import models
