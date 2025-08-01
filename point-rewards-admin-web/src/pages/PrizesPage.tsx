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
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { apiClient } from '@/lib/api'
import { formatNumber, formatPoints } from '@/lib/utils'
import { Prize } from '@/types'
import { Search, Gift, Package, Star, AlertTriangle, Edit, Save, X, Plus, ChevronUp, ChevronDown, ChevronsUpDown } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'
import ImageUpload from '@/components/ImageUpload'

export default function PrizesPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [editingPrize, setEditingPrize] = useState<Prize | null>(null)
  const [isAddingPrize, setIsAddingPrize] = useState(false)
  const [sortField, setSortField] = useState<'points' | 'stock' | 'status' | null>(null)
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc')
  const [editForm, setEditForm] = useState({
    name: '',
    description: '',
    points: 0,
    category: '',
    stock: 0,
    image: ''
  })
  const [addForm, setAddForm] = useState({
    name: '',
    description: '',
    points: 0,
    category: '',
    stock: 10,
    image: ''
  })
  const { toast } = useToast()
  const queryClient = useQueryClient()

  const { data: prizesResponse, isLoading } = useQuery({
    queryKey: ['prizes'],
    queryFn: () => apiClient.get<Prize[]>('/api/admin/prizes'),
  })

  const updatePrizeMutation = useMutation({
    mutationFn: ({ prizeId, prizeData }: { prizeId: number; prizeData: Partial<Prize> }) =>
      apiClient.put(`/api/admin/prizes/${prizeId}`, prizeData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prizes'] })
      toast({
        title: '更新成功',
        description: '奖品信息已更新'
      })
      setEditingPrize(null)
    },
    onError: (error: any) => {
      toast({
        title: '更新失败',
        description: error.response?.data?.message || '更新奖品信息时出现错误',
        variant: 'destructive'
      })
    }
  })

  const createPrizeMutation = useMutation({
    mutationFn: (prizeData: Omit<Prize, 'id'>) =>
      apiClient.post('/api/admin/prizes', prizeData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['prizes'] })
      toast({
        title: '创建成功',
        description: '新奖品已创建'
      })
      setIsAddingPrize(false)
      setAddForm({
        name: '',
        description: '',
        points: 0,
        category: '',
        stock: 10,
        image: ''
      })
    },
    onError: (error: any) => {
      toast({
        title: '创建失败',
        description: error.response?.data?.message || '创建奖品时出现错误',
        variant: 'destructive'
      })
    }
  })

  const prizes = prizesResponse?.data || []

  // 排序处理函数
  const handleSort = (field: 'points' | 'stock' | 'status') => {
    if (sortField === field) {
      if (sortOrder === 'asc') {
        setSortOrder('desc')
      } else {
        setSortField(null)
        setSortOrder('asc')
      }
    } else {
      setSortField(field)
      setSortOrder('asc')
    }
  }

  // 获取排序图标
  const getSortIcon = (field: 'points' | 'stock' | 'status') => {
    if (sortField !== field) {
      return <ChevronsUpDown className="h-4 w-4 ml-1" />
    }
    return sortOrder === 'asc' 
      ? <ChevronUp className="h-4 w-4 ml-1" />
      : <ChevronDown className="h-4 w-4 ml-1" />
  }

  // 获取奖品状态用于排序
  const getPrizeStatus = (prize: Prize) => {
    if (prize.stock === 0) return 0 // 已售罄
    if (prize.stock <= 5) return 1 // 库存不足
    return 2 // 充足
  }

  const handleEditPrize = (prize: Prize) => {
    setEditingPrize(prize)
    setEditForm({
      name: prize.name,
      description: prize.description || '',
      points: prize.points,
      category: prize.category || '',
      stock: prize.stock,
      image: prize.image || ''
    })
  }

  const handleSavePrize = () => {
    if (!editingPrize) return
    
    updatePrizeMutation.mutate({
      prizeId: editingPrize.id,
      prizeData: editForm
    })
  }

  const handleAddPrize = () => {
    if (!addForm.name || addForm.points <= 0) {
      toast({
        title: '验证失败',
        description: '请填写奖品名称和有效的积分值',
        variant: 'destructive'
      })
      return
    }

    createPrizeMutation.mutate(addForm)
  }

  const handleCancelEdit = () => {
    setEditingPrize(null)
    setEditForm({
      name: '',
      description: '',
      points: 0,
      category: '',
      stock: 0,
      image: ''
    })
  }

  const handleCancelAdd = () => {
    setIsAddingPrize(false)
    setAddForm({
      name: '',
      description: '',
      points: 0,
      category: '',
      stock: 10,
      image: ''
    })
  }

  const filteredPrizes = Array.isArray(prizes) ? prizes.filter(prize => {
    const matchesSearch = prize.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (prize.description && prize.description.toLowerCase().includes(searchTerm.toLowerCase()))
    const matchesCategory = selectedCategory === 'all' || prize.category === selectedCategory
    return matchesSearch && matchesCategory
  }).sort((a, b) => {
    if (!sortField) return 0
    
    let aValue: number
    let bValue: number
    
    switch (sortField) {
      case 'points':
        aValue = a.points
        bValue = b.points
        break
      case 'stock':
        aValue = a.stock
        bValue = b.stock
        break
      case 'status':
        aValue = getPrizeStatus(a)
        bValue = getPrizeStatus(b)
        break
      default:
        return 0
    }
    
    if (sortOrder === 'asc') {
      return aValue - bValue
    } else {
      return bValue - aValue
    }
  }) : []

  const categories = ['all', 'cash', 'voucher', 'gift']
  const categoryNames = {
    all: '全部',
    cash: '现金红包',
    voucher: '购物券',
    gift: '精美礼品'
  }

  const totalPrizes = Array.isArray(prizes) ? prizes.length : 0
  const totalStock = Array.isArray(prizes) && prizes.length > 0 ? prizes.reduce((sum, prize) => sum + (prize.stock || 0), 0) : 0
  const lowStockPrizes = Array.isArray(prizes) ? prizes.filter(prize => prize.stock <= 5).length : 0
  const totalValue = Array.isArray(prizes) && prizes.length > 0 ? prizes.reduce((sum, prize) => sum + ((prize.points || 0) * (prize.stock || 0)), 0) : 0

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
        <h1 className="text-3xl font-bold text-gray-900">奖品管理</h1>
        <p className="mt-2 text-sm text-gray-600">
          管理系统中的所有奖品
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-blue-100">
                <Gift className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">奖品总数</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(totalPrizes)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-green-100">
                <Package className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">总库存</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(totalStock)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-red-100">
                <AlertTriangle className="h-6 w-6 text-red-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">库存警告</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(lowStockPrizes)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0 p-3 rounded-lg bg-yellow-100">
                <Star className="h-6 w-6 text-yellow-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">总价值</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(totalValue)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Prizes Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>奖品列表</CardTitle>
              <CardDescription>
                所有可兑换奖品的详细信息
              </CardDescription>
            </div>
            <div className="flex items-center space-x-2">
              <Button 
                onClick={() => setIsAddingPrize(true)}
                className="bg-blue-600 hover:bg-blue-700"
              >
                <Plus className="h-4 w-4 mr-2" />
                添加新奖品
              </Button>
              
              {/* Category Filter */}
              <div className="flex space-x-1">
                {categories.map((category) => (
                  <Button
                    key={category}
                    variant={selectedCategory === category ? "default" : "outline"}
                    size="sm"
                    onClick={() => setSelectedCategory(category)}
                  >
                    {categoryNames[category as keyof typeof categoryNames]}
                  </Button>
                ))}
              </div>
              
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="搜索奖品..."
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
                <TableHead>名称</TableHead>
                <TableHead>描述</TableHead>
                <TableHead>分类</TableHead>
                <TableHead 
                  className="cursor-pointer hover:bg-gray-50 select-none"
                  onClick={() => handleSort('points')}
                >
                  <div className="flex items-center">
                    所需积分
                    {getSortIcon('points')}
                  </div>
                </TableHead>
                <TableHead 
                  className="cursor-pointer hover:bg-gray-50 select-none"
                  onClick={() => handleSort('stock')}
                >
                  <div className="flex items-center">
                    库存
                    {getSortIcon('stock')}
                  </div>
                </TableHead>
                <TableHead 
                  className="cursor-pointer hover:bg-gray-50 select-none"
                  onClick={() => handleSort('status')}
                >
                  <div className="flex items-center">
                    状态
                    {getSortIcon('status')}
                  </div>
                </TableHead>
                <TableHead>操作</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredPrizes.map((prize) => (
                <TableRow key={prize.id}>
                  <TableCell className="font-medium">{prize.id}</TableCell>
                  <TableCell className="max-w-xs">
                    <div className="flex items-center space-x-3">
                      {prize.image && (
                        <img 
                          src={prize.image.startsWith('/static') 
                            ? `http://127.0.0.1:5000${prize.image}` 
                            : prize.image} 
                          alt={prize.name}
                          className="w-10 h-10 rounded-lg object-cover"
                          onError={(e) => {
                            const target = e.target as HTMLImageElement;
                            target.style.display = 'none';
                          }}
                        />
                      )}
                      <span className="font-medium">{prize.name}</span>
                    </div>
                  </TableCell>
                  <TableCell className="max-w-xs">
                    <p className="text-sm text-gray-600 truncate">
                      {prize.description || '无描述'}
                    </p>
                  </TableCell>
                  <TableCell>
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {categoryNames[prize.category as keyof typeof categoryNames] || prize.category}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      <Star className="h-3 w-3 mr-1" />
                      {formatPoints(prize.points)}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                      prize.stock <= 5 
                        ? 'bg-red-100 text-red-800' 
                        : prize.stock <= 10 
                        ? 'bg-yellow-100 text-yellow-800' 
                        : 'bg-green-100 text-green-800'
                    }`}>
                      {formatNumber(prize.stock)}
                    </span>
                  </TableCell>
                  <TableCell>
                    {prize.stock === 0 ? (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                        已售罄
                      </span>
                    ) : prize.stock <= 5 ? (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        <AlertTriangle className="h-3 w-3 mr-1" />
                        库存不足
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        充足
                      </span>
                    )}
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="outline"  
                      size="sm"
                      onClick={() => handleEditPrize(prize)}
                      className="h-8 w-8 p-0"
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          {filteredPrizes.length === 0 && (
            <div className="text-center py-8">
              <p className="text-gray-500">没有找到匹配的奖品</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit Prize Dialog */}
      <Dialog open={!!editingPrize} onOpenChange={(open) => !open && handleCancelEdit()}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>编辑奖品信息</DialogTitle>
            <DialogDescription>
              修改奖品的基本信息和库存设置
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="name" className="text-right">
                名称
              </Label>
              <Input
                id="name"
                value={editForm.name}
                onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="description" className="text-right">
                描述
              </Label>
              <Textarea
                id="description"
                value={editForm.description}
                onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                className="col-span-3"
                rows={3}
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="category" className="text-right">
                分类
              </Label>
              <Select
                value={editForm.category}
                onValueChange={(value) => setEditForm({ ...editForm, category: value })}
              >
                <SelectTrigger className="col-span-3">
                  <SelectValue placeholder="选择分类" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">现金红包</SelectItem>
                  <SelectItem value="voucher">购物券</SelectItem>
                  <SelectItem value="gift">精美礼品</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="points" className="text-right">
                所需积分
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
              <Label htmlFor="stock" className="text-right">
                库存
              </Label>
              <Input
                id="stock"
                type="number"
                value={editForm.stock}
                onChange={(e) => setEditForm({ ...editForm, stock: parseInt(e.target.value) || 0 })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-start gap-4">
              <Label htmlFor="image" className="text-right mt-2">
                奖品图片
              </Label>
              <div className="col-span-3">
                <ImageUpload
                  value={editForm.image}
                  onChange={(url) => setEditForm({ ...editForm, image: url })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={handleCancelEdit}>
              <X className="h-4 w-4 mr-2" />
              取消
            </Button>
            <Button onClick={handleSavePrize} disabled={updatePrizeMutation.isPending}>
              <Save className="h-4 w-4 mr-2" />
              {updatePrizeMutation.isPending ? '保存中...' : '保存'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add Prize Dialog */}
      <Dialog open={isAddingPrize} onOpenChange={(open) => !open && handleCancelAdd()}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>添加新奖品</DialogTitle>
            <DialogDescription>
              创建一个新的奖品项目
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="add-name" className="text-right">
                名称 *
              </Label>
              <Input
                id="add-name"
                value={addForm.name}
                onChange={(e) => setAddForm({ ...addForm, name: e.target.value })}
                className="col-span-3"
                placeholder="请输入奖品名称"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="add-description" className="text-right">
                描述
              </Label>
              <Textarea
                id="add-description"
                value={addForm.description}
                onChange={(e) => setAddForm({ ...addForm, description: e.target.value })}
                className="col-span-3"
                rows={3}
                placeholder="请输入奖品描述"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="add-category" className="text-right">
                分类
              </Label>
              <Select
                value={addForm.category}
                onValueChange={(value) => setAddForm({ ...addForm, category: value })}
              >
                <SelectTrigger className="col-span-3">
                  <SelectValue placeholder="选择分类" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">现金红包</SelectItem>
                  <SelectItem value="voucher">购物券</SelectItem>
                  <SelectItem value="gift">精美礼品</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="add-points" className="text-right">
                所需积分 *
              </Label>
              <Input
                id="add-points"
                type="number"
                step="0.01"
                min="0"
                value={addForm.points}
                onChange={(e) => setAddForm({ ...addForm, points: parseFloat(e.target.value) || 0 })}
                className="col-span-3"
                placeholder="请输入所需积分"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="add-stock" className="text-right">
                库存
              </Label>
              <Input
                id="add-stock"
                type="number"
                value={addForm.stock}
                onChange={(e) => setAddForm({ ...addForm, stock: parseInt(e.target.value) || 0 })}
                className="col-span-3"
                placeholder="请输入库存数量"
                min="0"
              />
            </div>
            <div className="grid grid-cols-4 items-start gap-4">
              <Label htmlFor="add-image" className="text-right mt-2">
                奖品图片
              </Label>
              <div className="col-span-3">
                <ImageUpload
                  value={addForm.image}
                  onChange={(url) => setAddForm({ ...addForm, image: url })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={handleCancelAdd}>
              <X className="h-4 w-4 mr-2" />
              取消
            </Button>
            <Button onClick={handleAddPrize} disabled={createPrizeMutation.isPending}>
              <Save className="h-4 w-4 mr-2" />
              {createPrizeMutation.isPending ? '创建中...' : '创建奖品'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}