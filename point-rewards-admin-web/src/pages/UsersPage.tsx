import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
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
import { User } from '@/types'
import { Search, Shield, User as UserIcon, Edit, Save, X, MapPin, Eye } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'

export default function UsersPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [editingUser, setEditingUser] = useState<User | null>(null)
  const [viewingAddresses, setViewingAddresses] = useState<User | null>(null)
  const [editForm, setEditForm] = useState({
    nickname: '',
    kuaishouId: '',
    phone: '',
    points: 0,
    is_admin: false
  })
  const { toast } = useToast()
  const queryClient = useQueryClient()

  const { data: usersResponse, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: () => apiClient.get<User[]>('/api/admin/users'),
  })

  const updateUserMutation = useMutation({
    mutationFn: ({ userId, userData }: { userId: number; userData: Partial<User> }) =>
      apiClient.put(`/api/admin/users/${userId}`, userData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      toast({
        title: '更新成功',
        description: '用户信息已更新'
      })
      setEditingUser(null)
    },
    onError: (error: any) => {
      toast({
        title: '更新失败',
        description: error.response?.data?.message || '更新用户信息时出现错误',
        variant: 'destructive'
      })
    }
  })

  const users = usersResponse?.data || []

  const filteredUsers = Array.isArray(users) ? users.filter(user =>
    user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.phone.includes(searchTerm) ||
    user.kuaishouId.toLowerCase().includes(searchTerm.toLowerCase())
  ) : []

  const handleEditUser = (user: User) => {
    setEditingUser(user)
    setEditForm({
      nickname: user.nickname,
      kuaishouId: user.kuaishouId,
      phone: user.phone,
      points: user.points,
      is_admin: user.is_admin
    })
  }

  const handleSaveUser = () => {
    if (!editingUser) return
    
    updateUserMutation.mutate({
      userId: editingUser.id,
      userData: editForm
    })
  }

  const handleCancelEdit = () => {
    setEditingUser(null)
    setEditForm({
      nickname: '',
      kuaishouId: '',
      phone: '',
      points: 0,
      is_admin: false
    })
  }

  const handleViewAddresses = (user: User) => {
    setViewingAddresses(user)
  }

  const formatAddress = (address: any) => {
    if (typeof address === 'string') {
      try {
        const parsed = JSON.parse(address)
        return parsed
      } catch {
        return { address }
      }
    }
    return address
  }

  const totalUsers = users.length
  const adminUsers = users.filter(user => user.is_admin).length
  const totalPoints = users.reduce((sum, user) => sum + user.points, 0)

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
        <h1 className="text-3xl font-bold text-gray-900">用户管理</h1>
        <p className="mt-2 text-sm text-gray-600">
          管理系统中的所有用户
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-blue-100">
                <UserIcon className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">总用户数</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(totalUsers)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-green-100">
                <Shield className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">管理员数</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(adminUsers)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-yellow-100">
                <span className="text-yellow-600 font-bold text-lg">★</span>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">总积分</p>
                <p className="text-2xl font-bold text-gray-900">{formatPoints(totalPoints)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>用户列表</CardTitle>
              <CardDescription>
                所有注册用户的详细信息
              </CardDescription>
            </div>
            <div className="flex items-center space-x-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="搜索用户..."
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
                <TableHead>ID</TableHead>
                <TableHead>昵称</TableHead>
                <TableHead>快手ID</TableHead>
                <TableHead>手机号</TableHead>
                <TableHead>积分</TableHead>
                <TableHead>角色</TableHead>
                <TableHead>操作</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">{user.id}</TableCell>
                  <TableCell>{user.nickname}</TableCell>
                  <TableCell>{user.kuaishouId}</TableCell>
                  <TableCell>{user.phone}</TableCell>
                  <TableCell>
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      {formatPoints(user.points)}
                    </span>
                  </TableCell>
                  <TableCell>
                    {user.is_admin ? (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        <Shield className="h-3 w-3 mr-1" />
                        管理员
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                        普通用户
                      </span>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleViewAddresses(user)}
                        className="h-8 px-2"
                      >
                        <Eye className="h-3 w-3 mr-1" />
                        地址
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEditUser(user)}
                        className="h-8 w-8 p-0"
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {filteredUsers.length === 0 && (
            <div className="text-center py-8">
              <p className="text-gray-500">没有找到匹配的用户</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit User Dialog */}
      <Dialog open={!!editingUser} onOpenChange={(open) => !open && handleCancelEdit()}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>编辑用户信息</DialogTitle>
            <DialogDescription>
              修改用户的基本信息和权限设置
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="nickname" className="text-right">
                昵称
              </Label>
              <Input
                id="nickname"
                value={editForm.nickname}
                onChange={(e) => setEditForm({ ...editForm, nickname: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="kuaishouId" className="text-right">
                快手ID
              </Label>
              <Input
                id="kuaishouId"
                value={editForm.kuaishouId}
                onChange={(e) => setEditForm({ ...editForm, kuaishouId: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="phone" className="text-right">
                手机号
              </Label>
              <Input
                id="phone"
                value={editForm.phone}
                onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="points" className="text-right">
                积分
              </Label>
              <Input
                id="points"
                type="number"
                step="0.01"
                min="0"
                value={editForm.points}
                onChange={(e) => setEditForm({ ...editForm, points: parseFloat(e.target.value) || 0 })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="is_admin" className="text-right">
                管理员权限
              </Label>
              <div className="col-span-3">
                <Switch
                  id="is_admin"
                  checked={editForm.is_admin}
                  onCheckedChange={(checked) => setEditForm({ ...editForm, is_admin: checked })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={handleCancelEdit}>
              <X className="h-4 w-4 mr-2" />
              取消
            </Button>
            <Button onClick={handleSaveUser} disabled={updateUserMutation.isPending}>
              <Save className="h-4 w-4 mr-2" />
              {updateUserMutation.isPending ? '保存中...' : '保存'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* View Addresses Dialog */}
      <Dialog open={!!viewingAddresses} onOpenChange={(open) => !open && setViewingAddresses(null)}>
        <DialogContent className="sm:max-w-[600px] max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center">
              <MapPin className="h-5 w-5 mr-2" />
              用户地址信息
            </DialogTitle>
            <DialogDescription>
              {viewingAddresses?.nickname} 的收货地址列表
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            {viewingAddresses?.addresses && viewingAddresses.addresses.length > 0 ? (
              <div className="space-y-4">
                {viewingAddresses.addresses.map((address, index) => {
                  const formattedAddress = formatAddress(address)
                  return (
                    <Card key={index}>
                      <CardContent className="p-4">
                        <div className="flex items-start space-x-3">
                          <div className="flex-shrink-0 p-2 rounded-lg bg-blue-50">
                            <MapPin className="h-4 w-4 text-blue-600" />
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center justify-between mb-2">
                              <h4 className="font-medium text-gray-900">
                                地址 {index + 1}
                              </h4>
                            </div>
                            {formattedAddress.name && (
                              <p className="text-sm font-medium text-gray-900 mb-1">
                                收件人：{formattedAddress.name}
                              </p>
                            )}
                            {formattedAddress.phone && (
                              <p className="text-sm text-gray-600 mb-2">
                                电话：{formattedAddress.phone}
                              </p>
                            )}
                            <p className="text-sm text-gray-700">
                              地址：{formattedAddress.address || address}
                            </p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            ) : (
              <div className="text-center py-8">
                <MapPin className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">该用户暂无收货地址</p>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setViewingAddresses(null)}>
              关闭
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}