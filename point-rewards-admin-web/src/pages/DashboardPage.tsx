import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { apiClient } from '@/lib/api'
import { formatNumber, formatPoints } from '@/lib/utils'
import { Users, Gift, History, Star } from 'lucide-react'

export default function DashboardPage() {
  const { data: usersData } = useQuery({
    queryKey: ['users'],
    queryFn: () => apiClient.get('/api/admin/users'),
  })

  const { data: prizesData } = useQuery({
    queryKey: ['prizes'],
    queryFn: () => apiClient.get('/api/admin/prizes'),
  })

  const { data: redemptionsData } = useQuery({
    queryKey: ['redemptions'],
    queryFn: () => apiClient.get('/api/admin/redemptions'),
  })

  const users = usersData?.data || []
  const prizes = prizesData?.data || []
  const redemptions = redemptionsData?.data || []

  // 确保redemptions是数组且不为空时才计算总积分
  const totalPointsSpent = Array.isArray(redemptions) && redemptions.length > 0 
    ? redemptions.reduce((total: number, r: any) => total + (r.points_spent || 0), 0)
    : 0

  const stats = [
    {
      title: '总用户数',
      value: users.length,
      icon: Users,
      description: '注册用户总数',
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      title: '奖品总数',
      value: prizes.length,
      icon: Gift,
      description: '可兑换奖品数量',
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      title: '兑换记录',
      value: Array.isArray(redemptions) ? redemptions.length : 0,
      icon: History,
      description: '总兑换次数',
      color: 'text-purple-600',
      bgColor: 'bg-purple-100',
    },
    {
      title: '消耗积分',
      value: totalPointsSpent,
      icon: Star,
      description: '用户消耗的总积分',
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100',
    },
  ]

  const recentRedemptions = Array.isArray(redemptions) ? redemptions.slice(0, 5) : []

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">仪表板</h1>
        <p className="mt-2 text-sm text-gray-600">
          积分兑换系统总览
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardContent className="p-6">
              <div className="flex items-center">
                <div className={`flex-shrink-0 p-3 rounded-lg ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.color}`} />
                </div>
                <div className="ml-4 flex-1">
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {formatNumber(stat.value)}
                  </p>
                </div>
              </div>
              <p className="mt-2 text-xs text-gray-500">{stat.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>最近兑换记录</CardTitle>
            <CardDescription>用户最近的兑换活动</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentRedemptions.length > 0 ? (
                recentRedemptions.map((redemption: any) => (
                  <div key={redemption.id} className="flex items-center justify-between border-b pb-2">
                    <div>
                      <p className="text-sm font-medium">{redemption.prize_name}</p>
                      <p className="text-xs text-gray-500">用户ID: {redemption.user_id}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium">{formatPoints(redemption.points_spent)} 积分</p>
                      <p className="text-xs text-gray-500">
                        {new Date(redemption.created_at).toLocaleDateString('zh-CN')}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-sm text-gray-500">暂无兑换记录</p>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>系统状态</CardTitle>
            <CardDescription>当前系统运行状态</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">系统状态</span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  正常运行
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">数据库状态</span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  连接正常
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">缓存状态</span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  运行中
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}