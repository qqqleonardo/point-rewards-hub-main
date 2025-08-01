import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date) {
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(date))
}

export function formatNumber(num: number) {
  return new Intl.NumberFormat('zh-CN').format(num)
}

export function formatPoints(points: number | string) {
  const num = typeof points === 'string' ? parseFloat(points) : points
  if (isNaN(num)) return '0'
  
  // 如果是整数，不显示小数点
  if (num % 1 === 0) {
    return new Intl.NumberFormat('zh-CN').format(num)
  }
  
  // 如果有小数，最多显示2位小数
  return new Intl.NumberFormat('zh-CN', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  }).format(num)
}