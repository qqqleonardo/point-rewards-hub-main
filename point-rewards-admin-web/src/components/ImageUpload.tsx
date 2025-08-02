import { useState, useRef, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Upload, X, Loader2 } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'

interface ImageUploadProps {
  value?: string
  onChange: (url: string) => void
  className?: string
}

export default function ImageUpload({ value, onChange, className }: ImageUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  // 处理初始值，如果是相对路径则转换为完整URL用于预览
  const initialPreviewUrl = value 
    ? (value.startsWith('/static') ? `http://localhost:5000${value}` : value)
    : ''
  const [previewUrl, setPreviewUrl] = useState(initialPreviewUrl)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()

  // 当value属性变化时更新预览URL
  useEffect(() => {
    const newPreviewUrl = value 
      ? (value.startsWith('/static') ? `http://localhost:5000${value}` : value)
      : ''
    setPreviewUrl(newPreviewUrl)
  }, [value])

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // 验证文件类型
    const allowedTypes = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      toast({
        title: '文件格式不支持',
        description: '请选择 PNG、JPG、JPEG、GIF 或 WEBP 格式的图片',
        variant: 'destructive'
      })
      return
    }

    // 验证文件大小 (5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: '文件过大',
        description: '请选择小于 5MB 的图片',
        variant: 'destructive'
      })
      return
    }

    setIsUploading(true)

    try {
      const formData = new FormData()
      formData.append('file', file)

      const token = localStorage.getItem('admin_token')
      const response = await fetch('http://localhost:5000/api/admin/upload', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      })

      const result = await response.json()

      if (response.ok && result.code === 200) {
        const imageUrl = result.data.url
        // 如果返回的是相对路径，转换为完整URL用于预览
        const fullImageUrl = imageUrl.startsWith('/static') 
          ? `http://localhost:5000${imageUrl}`
          : imageUrl
        setPreviewUrl(fullImageUrl)
        onChange(imageUrl) // 保存相对路径到数据库
        toast({
          title: '上传成功',
          description: '图片已成功上传'
        })
      } else {
        throw new Error(result.message || '上传失败')
      }
    } catch (error) {
      console.error('上传失败:', error)
      toast({
        title: '上传失败',
        description: error instanceof Error ? error.message : '图片上传失败，请重试',
        variant: 'destructive'
      })
    } finally {
      setIsUploading(false)
      // 清空文件输入
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    }
  }

  const handleUrlChange = (url: string) => {
    // 预览显示完整URL，但保存相对路径
    const fullUrl = url.startsWith('/static') ? `http://localhost:5000${url}` : url
    setPreviewUrl(fullUrl)
    onChange(url)
  }

  const handleRemoveImage = () => {
    setPreviewUrl('')
    onChange('')
  }

  const handleUploadClick = () => {
    fileInputRef.current?.click()
  }

  return (
    <div className={className}>
      <div className="space-y-4">
        {/* 图片预览区 */}
        {previewUrl && (
          <div className="relative inline-block">
            <img
              src={previewUrl}
              alt="预览"
              className="w-32 h-32 object-cover rounded-lg border border-gray-200"
              onError={() => {
                // 图片加载失败时隐藏预览
                console.error('预览图片加载失败:', previewUrl);
                toast({
                  title: '图片预览失败',
                  description: '无法加载图片预览，请检查图片URL是否正确',
                  variant: 'destructive'
                });
              }}
              onLoad={() => {
                // 图片加载成功
              }}
            />
            <Button
              type="button"
              variant="destructive"
              size="sm"
              className="absolute -top-2 -right-2 h-6 w-6 p-0 rounded-full"
              onClick={handleRemoveImage}
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        )}

        {/* 上传按钮 */}
        <div className="flex flex-col space-y-2">
          <div className="flex space-x-2">
            <Button
              type="button"
              variant="outline"
              onClick={handleUploadClick}
              disabled={isUploading}
              className="flex-1"
            >
              {isUploading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  上传中...
                </>
              ) : (
                <>
                  <Upload className="h-4 w-4 mr-2" />
                  选择图片
                </>
              )}
            </Button>
          </div>
          
          {/* 隐藏的文件输入 */}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/png,image/jpg,image/jpeg,image/gif,image/webp"
            onChange={handleFileSelect}
            className="hidden"
          />
        </div>

        {/* 或者输入URL */}
        <div className="space-y-2">
          <Label className="text-sm text-gray-600">或者输入图片URL</Label>
          <Input
            type="url"
            placeholder="https://example.com/image.jpg"
            value={value || ''}
            onChange={(e) => handleUrlChange(e.target.value)}
          />
        </div>

        {/* 提示文本 */}
        <p className="text-xs text-gray-500">
          支持 PNG、JPG、JPEG、GIF、WEBP 格式，文件大小不超过 5MB
        </p>
      </div>
    </div>
  )
}