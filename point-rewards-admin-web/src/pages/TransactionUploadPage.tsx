import { useState, useRef } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Progress } from '@/components/ui/progress'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { apiClient } from '@/lib/api'
import { useToast } from '@/hooks/use-toast'
import { Upload, FileSpreadsheet, CheckCircle, AlertTriangle, X, Download } from 'lucide-react'

interface UploadResult {
  updated_count: number
  not_found_count: number
  total_processed: number
  error_records: Array<{
    row: number
    kuaishou_id: string
    reason: string
  }>
}

export default function TransactionUploadPage() {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [uploadResult, setUploadResult] = useState<UploadResult | null>(null)
  const [isDragOver, setIsDragOver] = useState(false)
  const [showAllErrors, setShowAllErrors] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()
  const queryClient = useQueryClient()

  const uploadMutation = useMutation({
    mutationFn: (file: File) => {
      const formData = new FormData()
      formData.append('file', file)
      return apiClient.post('/api/admin/upload-transaction', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        }
      })
    },
    onSuccess: (response) => {
      setUploadResult(response.data)
      setShowAllErrors(false) // 重置展开状态
      toast({
        title: '上传成功',
        description: `成功更新 ${response.data.updated_count} 个用户的积分信息`
      })
      // 刷新用户数据
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setSelectedFile(null)
    },
    onError: (error: any) => {
      toast({
        title: '上传失败',
        description: error.response?.data?.message || '处理文件时出现错误',
        variant: 'destructive'
      })
    }
  })

  const handleFileSelect = (file: File) => {
    if (!file.name.toLowerCase().endsWith('.xlsx') && !file.name.toLowerCase().endsWith('.xls')) {
      toast({
        title: '文件格式错误',
        description: '请选择 Excel 文件 (.xlsx 或 .xls)',
        variant: 'destructive'
      })
      return
    }
    setSelectedFile(file)
    setUploadResult(null)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
    const files = Array.from(e.dataTransfer.files)
    if (files.length > 0) {
      handleFileSelect(files[0])
    }
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
  }

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files
    if (files && files.length > 0) {
      handleFileSelect(files[0])
    }
  }

  const handleUpload = () => {
    if (selectedFile) {
      uploadMutation.mutate(selectedFile)
    }
  }

  const resetUpload = () => {
    setSelectedFile(null)
    setUploadResult(null)
    setShowAllErrors(false) // 重置展开状态
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const downloadTemplate = async () => {
    try {
      // 创建下载链接
      const token = localStorage.getItem('admin_token')
      const link = document.createElement('a')
      link.href = `http://localhost:5000/api/admin/download-template?token=${token}`
      link.target = '_blank'
      
      // 使用fetch下载文件
      const response = await fetch(`http://localhost:5000/api/admin/download-template`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (response.ok) {
        const blob = await response.blob()
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '积分流水模板.xlsx'
        document.body.appendChild(a)
        a.click()
        window.URL.revokeObjectURL(url)
        document.body.removeChild(a)
        
        toast({
          title: '下载成功',
          description: '模板文件已开始下载'
        })
      } else {
        throw new Error('下载失败')
      }
    } catch (error) {
      toast({
        title: '下载失败',
        description: '无法下载模板文件，请稍后重试',
        variant: 'destructive'
      })
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">流水上传</h1>
        <p className="mt-2 text-sm text-gray-600">
          上传员工流水Excel文件，系统将自动计算积分并更新用户数据
        </p>
      </div>

      {/* 使用说明 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <FileSpreadsheet className="h-5 w-5 mr-2" />
            使用说明
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h3 className="font-medium text-gray-900 mb-2">Excel文件格式要求：</h3>
              <ul className="text-sm text-gray-600 space-y-1">
                <li>• 第1列：快手ID（必填）</li>
                <li>• 第2列：主播名称（可选）</li>
                <li>• 第3列：流水金额（必填）</li>
                <li>• 积分计算：积分 = 流水 ÷ 10</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium text-gray-900 mb-2">处理规则：</h3>
              <ul className="text-sm text-gray-600 space-y-1">
                <li>• 直接覆盖用户当前积分</li>
                <li>• 仅更新已注册用户的数据</li>
                <li>• 支持 .xlsx 和 .xls 格式</li>
                <li>• 自动跳过空行和无效数据</li>
              </ul>
            </div>
          </div>
          <div className="pt-4 border-t">
            <Button variant="outline" onClick={downloadTemplate} className="flex items-center">
              <Download className="h-4 w-4 mr-2" />
              下载模板文件
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* 文件上传区域 */}
      <Card>
        <CardHeader>
          <CardTitle>上传Excel文件</CardTitle>
          <CardDescription>
            拖拽文件到下方区域或点击选择文件
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div
            className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
              isDragOver
                ? 'border-blue-400 bg-blue-50'
                : selectedFile
                ? 'border-green-400 bg-green-50'
                : 'border-gray-300 hover:border-gray-400'
            }`}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
          >
            {selectedFile ? (
              <div className="space-y-4">
                <CheckCircle className="h-12 w-12 text-green-500 mx-auto" />
                <div>
                  <p className="text-lg font-medium text-gray-900">{selectedFile.name}</p>
                  <p className="text-sm text-gray-500">
                    文件大小: {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
                <div className="flex justify-center space-x-4">
                  <Button
                    onClick={handleUpload}
                    disabled={uploadMutation.isPending}
                    className="bg-green-600 hover:bg-green-700"
                  >
                    {uploadMutation.isPending ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        处理中...
                      </>
                    ) : (
                      <>
                        <Upload className="h-4 w-4 mr-2" />
                        开始处理
                      </>
                    )}
                  </Button>
                  <Button variant="outline" onClick={resetUpload} disabled={uploadMutation.isPending}>
                    <X className="h-4 w-4 mr-2" />
                    重新选择
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-4">
                <Upload className="h-12 w-12 text-gray-400 mx-auto" />
                <div>
                  <p className="text-lg font-medium text-gray-900">拖拽Excel文件到这里</p>
                  <p className="text-sm text-gray-500">或者点击下方按钮选择文件</p>
                </div>
                <Button
                  variant="outline"
                  onClick={() => fileInputRef.current?.click()}
                  className="mx-auto"
                >
                  <FileSpreadsheet className="h-4 w-4 mr-2" />
                  选择文件
                </Button>
              </div>
            )}
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept=".xlsx,.xls"
            className="hidden"
            onChange={handleFileInputChange}
          />
        </CardContent>
      </Card>

      {/* 处理进度 */}
      {uploadMutation.isPending && (
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">正在处理文件...</span>
              </div>
              <Progress value={undefined} className="w-full" />
              <p className="text-xs text-gray-500 text-center">
                请耐心等待，正在读取Excel文件并更新用户积分数据
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* 处理结果 */}
      {uploadResult && (
        <div className="space-y-4">
          {/* 处理成功的总体情况 */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <CheckCircle className="h-5 w-5 mr-2 text-green-500" />
                处理完成
              </CardTitle>
              <CardDescription>
                文件处理已完成，以下是详细统计结果
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                  <div className="text-2xl font-bold text-blue-600">{uploadResult.total_processed}</div>
                  <div className="text-sm text-blue-700 font-medium">总处理行数</div>
                  <div className="text-xs text-blue-600 mt-1">Excel文件中的数据行数</div>
                </div>
                <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                  <div className="text-2xl font-bold text-green-600">{uploadResult.updated_count}</div>
                  <div className="text-sm text-green-700 font-medium">成功更新用户</div>
                  <div className="text-xs text-green-600 mt-1">积分已更新到用户账户</div>
                </div>
                <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
                  <div className="text-2xl font-bold text-orange-600">{uploadResult.not_found_count}</div>
                  <div className="text-sm text-orange-700 font-medium">用户不存在</div>
                  <div className="text-xs text-orange-600 mt-1">快手ID未在系统中注册</div>
                </div>
              </div>

              {/* 成功率显示 */}
              <div className="mt-6 p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">处理成功率</span>
                  <span className="text-sm font-bold text-gray-900">
                    {uploadResult.total_processed > 0 
                      ? Math.round((uploadResult.updated_count / uploadResult.total_processed) * 100) 
                      : 0}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-green-500 h-2 rounded-full transition-all duration-500"
                    style={{
                      width: `${uploadResult.total_processed > 0 
                        ? Math.round((uploadResult.updated_count / uploadResult.total_processed) * 100) 
                        : 0}%`
                    }}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* 错误记录详情 */}
          {uploadResult.error_records && uploadResult.error_records.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-orange-600">
                  <AlertTriangle className="h-5 w-5 mr-2" />
                  处理失败的记录 ({uploadResult.error_records.length} 条)
                </CardTitle>
                <CardDescription>
                  以下记录未能成功处理，请检查数据并修正后重新上传
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {/* 显示错误记录 */}
                  {(showAllErrors ? uploadResult.error_records : uploadResult.error_records.slice(0, 5)).map((error, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-orange-50 rounded-lg border border-orange-200">
                      <div className="flex-1">
                        <div className="flex items-center space-x-2">
                          <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-orange-100 text-orange-800">
                            第 {error.row} 行
                          </span>
                          <span className="font-medium text-gray-900">快手ID: {error.kuaishou_id}</span>
                        </div>
                        <p className="text-sm text-orange-700 mt-1">{error.reason}</p>
                      </div>
                    </div>
                  ))}
                  
                  {/* 展开/收起按钮 */}
                  {uploadResult.error_records.length > 5 && (
                    <div className="text-center py-3 border-t border-orange-200">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setShowAllErrors(!showAllErrors)}
                        className="text-orange-600 hover:text-orange-700 hover:bg-orange-50"
                      >
                        {showAllErrors ? (
                          <>收起错误记录</>
                        ) : (
                          <>还有 {uploadResult.error_records.length - 5} 条记录未显示，点击展开</>
                        )}
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* 操作建议 */}
          <Card>
            <CardContent className="pt-6">
              <div className="bg-blue-50 p-4 rounded-lg">
                <h4 className="font-medium text-blue-900 mb-2">📋 处理建议</h4>
                <ul className="text-sm text-blue-800 space-y-1">
                  {uploadResult.updated_count > 0 && (
                    <li>✅ {uploadResult.updated_count} 个用户的积分已成功更新</li>
                  )}
                  {uploadResult.not_found_count > 0 && (
                    <li>⚠️ {uploadResult.not_found_count} 个快手ID在系统中不存在，需要用户先注册</li>
                  )}
                  <li>💡 您可以在"用户管理"页面查看更新后的积分情况</li>
                  <li>🔄 如需重新处理，请修正Excel文件后再次上传</li>
                </ul>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}