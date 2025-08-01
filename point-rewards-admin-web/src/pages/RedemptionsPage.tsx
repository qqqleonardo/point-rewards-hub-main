import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { apiClient } from '@/lib/api'
import { formatDate, formatNumber, formatPoints } from '@/lib/utils'
import { Redemption } from '@/types'
import { Search, History, CheckCircle, Clock, Star, MapPin } from 'lucide-react'

export default function RedemptionsPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const { data: redemptionsResponse, isLoading } = useQuery({
    queryKey: ['redemptions'],
    queryFn: () => apiClient.get<Redemption[]>('/api/admin/redemptions'),
  })

  const redemptions = redemptionsResponse?.data || []

  const filteredRedemptions = Array.isArray(redemptions) ? redemptions.filter(redemption => {
    const matchesSearch = redemption.prize_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         redemption.user_id.toString().includes(searchTerm) ||
                         redemption.id.toString().includes(searchTerm)
    const matchesStatus = statusFilter === 'all' || redemption.status === statusFilter
    return matchesSearch && matchesStatus
  }) : []

  const statusOptions = [
    { value: 'all', label: '全部状态' },
    { value: 'completed', label: '已完成' },
    { value: 'pending', label: '待处理' },
    { value: 'shipped', label: '已发货' },
  ]

  const totalRedemptions = Array.isArray(redemptions) ? redemptions.length : 0
  const completedRedemptions = Array.isArray(redemptions) ? redemptions.filter(r => r.status === 'completed').length : 0
  const pendingRedemptions = Array.isArray(redemptions) ? redemptions.filter(r => r.status === 'pending').length : 0
  const totalPointsSpent = Array.isArray(redemptions) && redemptions.length > 0 
    ? redemptions.reduce((sum, r) => sum + (r.points_spent || 0), 0) 
    : 0

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return (
          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
            <CheckCircle className="h-3 w-3 mr-1" />
            已完成
          </span>
        )
      case 'pending':
        return (
          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
            <Clock className="h-3 w-3 mr-1" />
            待处理
          </span>
        )
      case 'shipped':
        return (
          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            已发货
          </span>
        )
      default:
        return (
          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
            {status}
          </span>
        )
    }
  }

  const formatShippingAddress = (address: string | null) => {
    if (!address) {
      return (
        <div className="flex items-center text-gray-400 text-sm">
          <MapPin className="h-3 w-3 mr-1" />
          暂无地址
        </div>
      )
    }

    try {
      // 如果地址是JSON格式，尝试解析
      const addressObj = JSON.parse(address)
      if (addressObj && typeof addressObj === 'object') {
        const { name, phone, address: addr } = addressObj
        return (
          <div className="max-w-xs">
            <div className="flex items-start">
              <MapPin className="h-3 w-3 mr-1 mt-0.5 text-gray-400 flex-shrink-0" />
              <div className="text-sm">
                <div className="font-medium text-gray-900">{name}</div>
                <div className="text-gray-600">{phone}</div>
                <div className="text-gray-600 break-words">{addr}</div>
              </div>
            </div>
          </div>
        )
      }
    } catch (e) {
      // 如果不是JSON格式，直接显示文本
    }

    return (
      <div className="flex items-start max-w-xs">
        <MapPin className="h-3 w-3 mr-1 mt-0.5 text-gray-400 flex-shrink-0" />
        <div className="text-sm text-gray-600 break-words">{address}</div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p>加载中...</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">兑换记录管理</h1>
        <p className="mt-2 text-sm text-gray-600">
          管理系统中的所有兑换记录
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-blue-100">
                <History className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">总兑换数</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(totalRedemptions)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-green-100">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">已完成</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(completedRedemptions)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-yellow-100">
                <Clock className="h-6 w-6 text-yellow-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">待处理</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(pendingRedemptions)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-purple-100">
                <Star className="h-6 w-6 text-purple-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">消耗积分</p>
                <p className="text-2xl font-bold text-gray-900">{formatPoints(totalPointsSpent)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Redemptions Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>兑换记录</CardTitle>
              <CardDescription>
                所有用户的兑换记录详情
              </CardDescription>
            </div>
            <div className="flex items-center space-x-2">
              {/* Status Filter */}
              <div className="flex space-x-1">
                {statusOptions.map((option) => (
                  <Button
                    key={option.value}
                    variant={statusFilter === option.value ? "default" : "outline"}
                    size="sm"
                    onClick={() => setStatusFilter(option.value)}
                  >
                    {option.label}
                  </Button>
                ))}
              </div>
              
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="搜索记录..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 w-64"
                />
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>兑换ID</TableHead>
                <TableHead>用户ID</TableHead>
                <TableHead>奖品名称</TableHead>
                <TableHead>消耗积分</TableHead>
                <TableHead>状态</TableHead>
                <TableHead>收货地址</TableHead>
                <TableHead>兑换时间</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredRedemptions.map((redemption) => (
                <TableRow key={redemption.id}>
                  <TableCell className="font-medium">{redemption.id}</TableCell>
                  <TableCell>{redemption.user_id}</TableCell>
                  <TableCell className="font-medium">{redemption.prize_name}</TableCell>
                  <TableCell>
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      <Star className="h-3 w-3 mr-1" />
                      {formatPoints(redemption.points_spent)}
                    </span>
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(redemption.status)}
                  </TableCell>
                  <TableCell>
                    {formatShippingAddress(redemption.shipping_address)}
                  </TableCell>
                  <TableCell className="text-sm text-gray-600">
                    {formatDate(redemption.created_at)}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {filteredRedemptions.length === 0 && (
            <div className="text-center py-8">
              <p className="text-gray-500">没有找到匹配的兑换记录</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}