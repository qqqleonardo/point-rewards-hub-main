export interface User {
  id: number
  nickname: string
  kuaishouId: string
  phone: string
  points: number
  is_admin: boolean
  addresses?: string[]
  created_at?: string
}

export interface Prize {
  id: number
  name: string
  description?: string
  image?: string
  points: number
  category?: string
  stock: number
  created_at?: string
}

export interface Redemption {
  id: number
  user_id: number
  prize_id: number
  prize_name: string
  points_spent: number
  status: string
  shipping_address?: string
  created_at: string
}

export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
}

export interface LoginRequest {
  phone: string
  password: string
}

export interface LoginResponse {
  id: number
  nickname: string
  kuaishouId: string
  phone: string
  points: number
  addresses: string[]
  access_token: string
  is_admin: boolean
}

export interface DashboardStats {
  totalUsers: number
  totalPrizes: number
  totalRedemptions: number
  totalPoints: number
}