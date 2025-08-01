import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// 格式化积分显示，隐藏小数点
export function formatPoints(points: number | string): string {
  const num = typeof points === 'string' ? parseFloat(points) : points
  if (isNaN(num)) return '0'
  
  // 总是显示为整数
  return Math.floor(num).toLocaleString('zh-CN')
}

// 积分比较函数，用于判断是否可以兑换
export function canAfford(userPoints: number | string, requiredPoints: number | string): boolean {
  const user = typeof userPoints === 'string' ? parseFloat(userPoints) : userPoints
  const required = typeof requiredPoints === 'string' ? parseFloat(requiredPoints) : requiredPoints
  
  if (isNaN(user) || isNaN(required)) return false
  
  return user >= required
}