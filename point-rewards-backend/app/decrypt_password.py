#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AES密码解密工具
用法: python decrypt_password.py <加密密码>
示例: python decrypt_password.py "h5jnvF+tfjLLWaCTIfpfw1ZBMY8zxGB5kPLb9LauVgA="
"""

import sys
import base64
import hashlib
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

def decrypt_password(encrypted_password):
    """
    解密AES加密的密码
    
    Args:
        encrypted_password (str): Base64编码的加密密码
    
    Returns:
        str: 解密后的明文密码
    """
    try:
        # 密钥 - 与前后端保持一致
        SECRET_KEY = 'eternalmoon'
        
        # 生成AES密钥 (SHA256)
        key = hashlib.sha256(SECRET_KEY.encode()).digest()
        
        # Base64解码
        encrypted_data = base64.b64decode(encrypted_password.encode())
        
        # 提取IV和密文
        iv = encrypted_data[:16]       # 前16字节作为IV
        ciphertext = encrypted_data[16:]  # 剩余作为密文
        
        # AES解密
        cipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted = cipher.decrypt(ciphertext)
        
        # 去除PKCS7填充
        plaintext = unpad(decrypted, AES.block_size).decode('utf-8')
        
        return plaintext
        
    except Exception as e:
        raise Exception(f"解密失败: {str(e)}")

def main():
    if len(sys.argv) != 2:
        print("用法:")
        print(f"  python {sys.argv[0]} <加密密码>")
        print()
        print("示例:")
        print(f'  python {sys.argv[0]} "h5jnvF+tfjLLWaCTIfpfw1ZBMY8zxGB5kPLb9LauVgA="')
        sys.exit(1)
    
    encrypted_password = sys.argv[1]
    
    try:
        print(f"加密密码: {encrypted_password}")
        print("解密中...")
        
        # 解密
        plain_password = decrypt_password(encrypted_password)
        
        print(f"解密成功!")
        print(f"明文密码: {plain_password}")
        
        # 显示详细信息
        print("\n=== 解密详情 ===")
        encrypted_data = base64.b64decode(encrypted_password.encode())
        iv = encrypted_data[:16]
        ciphertext = encrypted_data[16:]
        key = hashlib.sha256('eternalmoon'.encode()).digest()
        
        print(f"密钥 (hex): {key.hex()}")
        print(f"IV (hex):   {iv.hex()}")
        print(f"密文 (hex): {ciphertext.hex()}")
        print(f"算法:       AES-256-CBC")
        print(f"填充:       PKCS7")
        
    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()