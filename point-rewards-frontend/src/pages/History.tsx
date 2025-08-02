import { Skeleton } from "@/components/ui/skeleton";
import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { ArrowLeft, Gift } from 'lucide-react';
import { apiClient } from '@/lib/apiClient';
import { API_BASE_URL } from '@/lib/api';
import { useToast } from '@/hooks/use-toast';
import { formatPoints } from '@/lib/utils';

const CURRENT_USER_KEY = 'point-rewards-current-user';

interface RedemptionHistoryAPI {
  id: number;
  prize_name: string;
  points_spent: number;
  status: string;
  created_at: string;
  shipping_address: string;
}



const getStatusBadge = (status: string) => {
  switch (status) {
    case 'completed':
      return <Badge variant="outline" className="text-green-600 border-green-600">已完成</Badge>;
    case 'pending':
      return <Badge variant="outline" className="text-yellow-600 border-yellow-600">待处理</Badge>;
    case 'processing':
      return <Badge variant="outline" className="text-blue-600 border-blue-600">处理中</Badge>;
    default:
      return <Badge variant="outline">未知</Badge>;
  }
};

const HistoryPage = () => {
  const [history, setHistory] = useState<RedemptionHistoryAPI[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();
  const navigate = useNavigate();

  const fetchHistory = async () => {
    try {
      const savedUserData = localStorage.getItem(CURRENT_USER_KEY);
      if (!savedUserData) {
        navigate('/login');
        return;
      }
      
      const userData = JSON.parse(savedUserData);
      // console.log('Fetching history with token:', userData.access_token);
        const response = await apiClient.get<Redemption[]>(`${API_BASE_URL}/redemptions/history`, userData.access_token);
        // console.log('History API Response:', response);
        if (response.code === 200) {
          // 确保response.data是数组后再设置历史记录
          const historyData = Array.isArray(response.data) ? response.data : [];
          setHistory(historyData);
          // console.log('History data set:', response.data);
        } else {
        console.error('API Error:', response);
        toast({
          title: '获取历史记录失败',
          description: response.message || '请稍后重试',
        });
      }
    } catch (error) {
      console.error('获取历史记录失败:', error);
      // token过期的情况会在apiClient中自动处理重定向，这里只处理其他错误
      const errorMessage = error instanceof Error ? error.message : '请稍后重试';
      if (!errorMessage.includes('Token expired')) {
        toast({
          title: '获取历史记录失败',
          description: `网络错误: ${errorMessage}`,
        });
      }
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  return (
    <div className="p-4 max-w-2xl mx-auto">
      <div className="flex items-center mb-4">
        <Button asChild variant="ghost" size="icon">
          <Link to="/">
            <ArrowLeft className="w-5 h-5" />
          </Link>
        </Button>
        <h1 className="text-xl font-bold text-center flex-1">全部兑换记录</h1>
      </div>

      <Card className="bg-gradient-card shadow-soft">
        <CardHeader>
          <CardTitle>共 {history.length} 条记录</CardTitle>
        </CardHeader>
        <CardContent>
          <ScrollArea className="h-[75vh]">
            {isLoading ? (
              <div className="space-y-4 pr-4">
                {[...Array(10)].map((_, i) => (
                  <div key={i} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Skeleton className="w-10 h-10 rounded-lg" />
                      <div className="space-y-2">
                        <Skeleton className="h-4 w-32" />
                        <Skeleton className="h-3 w-20" />
                      </div>
                    </div>
                    <div className="text-right space-y-2">
                      <Skeleton className="h-4 w-20" />
                      <Skeleton className="h-4 w-16" />
                    </div>
                  </div>
                ))}
              </div>
            ) : history.length > 0 ? (
              <div className="space-y-4 pr-4">
                {history.map((redemption) => (
                  <div key={redemption.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-primary/10 rounded-lg flex items-center justify-center">
                        <Gift className="w-5 h-5 text-primary" />
                      </div>
                      <div>
                        <p className="font-medium text-sm">{redemption.prize_name}</p>
                        <p className="text-xs text-muted-foreground">{new Date(redemption.created_at).toLocaleDateString('zh-CN')}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium">-{formatPoints(redemption.points_spent)} 积分</p>
                      {getStatusBadge(redemption.status)}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-20">
                <Gift className="w-16 h-16 mx-auto mb-6 text-muted-foreground" />
                <h3 className="text-lg font-semibold">暂无记录</h3>
                <p className="text-muted-foreground text-sm mt-2">您还没有兑换过任何奖品。</p>
              </div>
            )}
          </ScrollArea>
        </CardContent>
      </Card>
    </div>
  );
};

export default HistoryPage;
