
// API响应统一格式
export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data: T;
}

// Token过期处理
const handleTokenExpired = () => {
  // 清除本地存储的用户数据
  localStorage.removeItem('point-rewards-current-user');
  // 重定向到登录页面
  window.location.href = '#/login';
};

export const apiClient = {
  async get<T>(url: string, token: string | null): Promise<ApiResponse<T>> {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
      },
    });
    
    const data = await response.json();
    
    // 检查token过期
    if ((response.status === 401 || (data.code === 401)) && token) {
      handleTokenExpired();
      throw new Error('Token expired, redirecting to login');
    }
    
    if (!response.ok) {
      throw new Error(data.message || 'Network response was not ok');
    }
    
    return data;
  },

  async post<T>(url: string, body: any, token: string | null = null): Promise<ApiResponse<T>> {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
      },
      body: JSON.stringify(body),
    });
    
    const data = await response.json();
    
    // 检查token过期
    if ((response.status === 401 || (data.code === 401)) && token) {
      handleTokenExpired();
      throw new Error('Token expired, redirecting to login');
    }
    
    if (!response.ok) {
      throw new Error(data.message || 'Failed to post data');
    }
    
    return data;
  },

  async put<T>(url: string, body: any, token: string | null): Promise<ApiResponse<T>> {
    const response = await fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
      },
      body: JSON.stringify(body),
    });
    
    const data = await response.json();
    
    // 检查token过期
    if ((response.status === 401 || (data.code === 401)) && token) {
      handleTokenExpired();
      throw new Error('Token expired, redirecting to login');
    }
    
    if (!response.ok) {
      throw new Error(data.message || 'Failed to update data');
    }
    
    return data;
  },
};
