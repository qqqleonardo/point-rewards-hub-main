import CryptoJS from 'crypto-js';

// 加密密钥 - 注意：这在前端是不安全的，仅用于满足你的需求
const SECRET_KEY = 'eternalmoon';

/**
 * 生成AES密钥 (与后端Python保持一致)
 */
function getKey(): CryptoJS.lib.WordArray {
  return CryptoJS.SHA256(SECRET_KEY);
}

/**
 * AES加密 (兼容Python后端的CBC模式)
 * @param text 要加密的文本
 * @returns 加密后的字符串
 */
export function encryptPassword(text: string): string {
  try {
    const key = getKey();
    const iv = CryptoJS.lib.WordArray.random(16); // 16字节IV
    
    const encrypted = CryptoJS.AES.encrypt(text, key, {
      iv: iv,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7
    });
    
    // 组合IV和加密数据，然后转换为base64
    const combined = iv.concat(encrypted.ciphertext);
    return CryptoJS.enc.Base64.stringify(combined);
  } catch (error) {
    console.error('加密失败:', error);
    throw new Error('密码加密失败');
  }
}

/**
 * AES解密 (兼容Python后端的CBC模式)
 * @param encryptedText 加密的文本
 * @returns 解密后的字符串
 */
export function decryptPassword(encryptedText: string): string {
  try {
    const key = getKey();
    
    // 解码base64
    const combined = CryptoJS.enc.Base64.parse(encryptedText);
    
    // 提取IV和加密数据
    const iv = CryptoJS.lib.WordArray.create(combined.words.slice(0, 4)); // 前16字节作为IV
    const encrypted = CryptoJS.lib.WordArray.create(combined.words.slice(4)); // 剩余作为加密数据
    
    const decrypted = CryptoJS.AES.decrypt(
      CryptoJS.lib.CipherParams.create({
        ciphertext: encrypted
      }),
      key,
      {
        iv: iv,
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7
      }
    );
    
    const decryptedText = decrypted.toString(CryptoJS.enc.Utf8);
    if (!decryptedText) {
      throw new Error('解密失败');
    }
    return decryptedText;
  } catch (error) {
    console.error('解密失败:', error);
    throw new Error('密码解密失败');
  }
}

/**
 * 判断密码是否已加密
 * @param password 密码字符串
 * @returns 是否已加密
 */
export function isEncryptedPassword(password: string): boolean {
  try {
    if (password.length < 20) {
      return false;
    }
    // 尝试base64解码
    CryptoJS.enc.Base64.parse(password);
    return true;
  } catch {
    return false;
  }
}