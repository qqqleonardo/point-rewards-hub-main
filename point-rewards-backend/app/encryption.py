import base64
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import hashlib

# 与前端相同的密钥
SECRET_KEY = 'eternalmoon'

def get_key():
    """生成AES密钥"""
    return hashlib.sha256(SECRET_KEY.encode()).digest()

def encrypt_password(password: str) -> str:
    """
    AES加密密码
    注意：这个函数主要用于测试，生产环境应该在前端加密
    """
    try:
        key = get_key()
        cipher = AES.new(key, AES.MODE_CBC)
        
        # 填充数据
        padded_data = pad(password.encode(), AES.block_size)
        
        # 加密
        encrypted = cipher.encrypt(padded_data)
        
        # 组合IV和加密数据
        result = base64.b64encode(cipher.iv + encrypted).decode()
        return result
    except Exception as e:
        raise Exception(f"加密失败: {str(e)}")

def decrypt_password(encrypted_password: str) -> str:
    """
    AES解密密码
    """
    try:
        key = get_key()
        
        # 解码base64
        encrypted_data = base64.b64decode(encrypted_password.encode())
        
        # 提取IV和加密数据
        iv = encrypted_data[:16]
        encrypted = encrypted_data[16:]
        
        # 解密
        cipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted = cipher.decrypt(encrypted)
        
        # 去除填充
        password = unpad(decrypted, AES.block_size).decode()
        return password
    except Exception as e:
        raise Exception(f"解密失败: {str(e)}")

def is_encrypted_password(password: str) -> bool:
    """
    判断密码是否已加密
    简单判断：加密后的密码通常较长且包含base64字符
    """
    try:
        if len(password) < 20:  # 加密后的密码应该比较长
            return False
        # 尝试base64解码
        base64.b64decode(password.encode())
        return True
    except:
        return False