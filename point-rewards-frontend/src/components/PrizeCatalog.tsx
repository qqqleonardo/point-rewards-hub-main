import { useState, useEffect } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Gift, Star, ArrowRight } from 'lucide-react';
import { apiClient } from '@/lib/apiClient';
import { API_BASE_URL } from '@/lib/api';
import { useToast } from '@/hooks/use-toast';
import { formatPoints, canAfford } from '@/lib/utils';
import redEnvelopeImage from '@/assets/red-envelope.png';

interface Prize {
  id: string;
  name: string;
  points: number;
  image: string;
  category: string;
  stock: number;
  description: string;
}

interface PrizeCatalogProps {
  userPoints: number;
  userAddresses: string[];
  onRedeem: (prize: Prize) => void;
}

// 处理图片URL的辅助函数
const processImageUrl = (imageUrl: string | null | undefined): string => {
  if (!imageUrl) {
    return redEnvelopeImage;
  }
  
  // 如果是相对路径（以/static开头），构建完整URL
  if (imageUrl.startsWith('/static')) {
    return `${API_BASE_URL.replace('/api', '')}${imageUrl}`;
  }
  
  // 如果是开发时的占位符路径
  if (imageUrl.includes('/src/assets/red-envelope.png')) {
    return redEnvelopeImage;
  }
  
  // 如果是完整的HTTP(S) URL，直接返回
  if (imageUrl.startsWith('http')) {
    return imageUrl;
  }
  
  // 其它情况返回默认图片
  return redEnvelopeImage;
};

const PrizeCatalog = ({ userPoints, userAddresses, onRedeem }: PrizeCatalogProps) => {
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [isLoading, setIsLoading] = useState(true);
  const [prizes, setPrizes] = useState<Prize[]>([]);
  const { toast } = useToast();

  const fetchPrizes = async () => {
    try {
      // console.log('Fetching prizes from:', `${API_BASE_URL}/prizes`);
      const response = await apiClient.get<Prize[]>(`${API_BASE_URL}/prizes`, null);
      // console.log('API Response:', response);
      if (response.code === 200) {
        // 处理图片路径
        const processedPrizes = response.data.map((prize: any) => ({
          ...prize,
          id: prize.id.toString(),
          // 统一处理图片URL
          image: processImageUrl(prize.image)
        }));
        setPrizes(processedPrizes);
      } else {
        console.error('API Error Response:', response);
        toast({
          title: '获取奖品列表失败',
          description: response.message || '请稍后重试',
        });
      }
    } catch (error) {
      console.error('获取奖品列表失败:', error);
      // 对于不需要token的接口，显示网络错误提示
      toast({
        title: '获取奖品列表失败',
        description: '网络错误，请稍后重试',
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPrizes();
  }, []);


  const categories = [
    { id: 'all', name: '全部奖品' },
    { id: 'cash', name: '现金红包' },
    { id: 'voucher', name: '购物券' },
    { id: 'gift', name: '精美礼品' }
  ];

  const filteredPrizes = selectedCategory === 'all' 
    ? prizes 
    : prizes.filter(prize => prize.category === selectedCategory);

  const hasAddress = userAddresses && userAddresses.length > 0 && userAddresses[0] && userAddresses[0].trim() !== '';
  const canRedeem = (prize: Prize) => canAfford(userPoints, prize.points) && prize.stock > 0;
  
  // 处理兑换点击，包含地址验证
  const handleRedeemClick = (prize: Prize) => {
    if (!canRedeem(prize)) return;
    
    if (!hasAddress) {
      toast({
        title: '需要设置收货地址',
        description: '兑换实物奖品需要收货地址，请先在"我的"页面设置收货地址',
        variant: 'destructive'
      });
      return;
    }
    
    onRedeem(prize);
  };

  return (
    <div className="p-4 max-w-4xl mx-auto">
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold">奖品列表</h1>
          <div className="flex items-center space-x-2">
            <Star className="w-5 h-5 text-secondary" />
            <span className="font-semibold text-primary">{formatPoints(userPoints)}</span>
            <span className="text-muted-foreground text-sm">积分</span>
          </div>
        </div>

        {/* Category Filter */}
        <div className="flex space-x-2 overflow-x-auto">
          {categories.map((category) => (
            <Button
              key={category.id}
              variant={selectedCategory === category.id ? "default" : "outline"}
              onClick={() => setSelectedCategory(category.id)}
              className="whitespace-nowrap"
            >
              {category.name}
            </Button>
          ))}
        </div>
      </div>

      {/* Prize Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {isLoading
          ? Array.from({ length: 8 }).map((_, index) => (
              <Card key={index} className="bg-gradient-card shadow-soft">
                <CardContent className="p-4">
                  <Skeleton className="aspect-[3/4] mb-3 rounded-lg" />
                  <Skeleton className="h-5 w-3/4 mx-auto mb-3" />
                  <Skeleton className="h-4 w-1/2 mx-auto mb-3" />
                  <Skeleton className="h-8 w-full" />
                </CardContent>
              </Card>
            ))
          : filteredPrizes.map((prize) => (
              <Card key={prize.id} className="bg-gradient-card shadow-soft hover:shadow-medium transition-all duration-300 animate-fade-in">
                <CardContent className="p-4">
                  <div className="aspect-[3/4] mb-3 relative overflow-hidden rounded-lg">
                    <img
                      src={prize.image}
                      alt={prize.name}
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        // 图片加载失败时使用默认图片
                        const target = e.target as HTMLImageElement;
                        target.src = redEnvelopeImage;
                      }}
                      loading="lazy"
                    />
                    {prize.stock <= 5 && (
                      <Badge variant="destructive" className="absolute top-2 right-2 text-xs">
                        仅剩{prize.stock}个
                      </Badge>
                    )}
                  </div>
                  
                  <h3 className="font-semibold text-sm mb-2 text-center">{prize.name}</h3>
                  
                  <div className="flex items-center justify-center mb-3">
                    <div className="flex items-center space-x-1">
                      <Gift className="w-4 h-4 text-primary" />
                      <span className="font-bold text-primary">{formatPoints(prize.points)}</span>
                      <span className="text-xs text-muted-foreground">积分</span>
                    </div>
                  </div>

                  <Button
                    onClick={() => handleRedeemClick(prize)}
                    disabled={!canRedeem(prize)}
                    className="w-full h-8 text-xs"
                    variant={canRedeem(prize) ? "default" : "outline"}
                  >
                    {prize.stock === 0 ? '已抢完' : 
                     !canAfford(userPoints, prize.points) ? '积分不足' : 
                     '立即兑换'}
                    {canRedeem(prize) && <ArrowRight className="w-3 h-3 ml-1" />}
                  </Button>
                </CardContent>
              </Card>
            ))}
      </div>

      {filteredPrizes.length === 0 && (
        <div className="text-center py-12">
          <Gift className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
          <p className="text-muted-foreground">暂无相关奖品</p>
        </div>
      )}
    </div>
  );
};

export default PrizeCatalog;