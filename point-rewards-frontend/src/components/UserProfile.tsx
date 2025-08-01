import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Link } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from '@/components/ui/separator';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { User, Award, Gift, MapPin, Phone, Mail, History, ArrowRight, LogOut, BadgeInfo, RefreshCw } from 'lucide-react';
import { UserData } from './UserRegistration';
import AddressEditor from './AddressEditor';
import { useState, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';
import { apiClient } from '@/lib/apiClient';
import { API_BASE_URL } from '@/lib/api';
import { formatPoints } from '@/lib/utils';

interface UserProfileProps {
  userData: UserData | null;
  isLoading: boolean;
  onLogout: () => void;
  onAddressUpdate: (userData: any) => void;
  onRefreshUserInfo?: () => Promise<any>;
}

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

const UserProfile = ({ userData, isLoading, onLogout, onAddressUpdate, onRefreshUserInfo }: UserProfileProps) => {
  const [isAddressModalOpen, setIsAddressModalOpen] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [recentRedemptions, setRecentRedemptions] = useState<RedemptionHistoryAPI[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(true);
  const { toast } = useToast();

  const fetchRecentHistory = async () => {
    if (!userData?.access_token) return;
    
    try {
      const response = await apiClient.get<RedemptionHistoryAPI[]>(
        `${API_BASE_URL}/redemptions/history`,
        userData.access_token
      );
      
      if (response.code === 200) {
        // 只显示最近3条记录
        setRecentRedemptions(response.data.slice(0, 3));
      }
    } catch (error) {
      console.error('获取兑换历史失败:', error);
      // token过期会在apiClient中自动处理重定向
    } finally {
      setIsLoadingHistory(false);
    }
  };

  useEffect(() => {
    if (userData?.access_token) {
      fetchRecentHistory();
    }
  }, [userData?.access_token]);

  const handleRefreshUserInfo = async () => {
    if (!onRefreshUserInfo) return;
    
    setIsRefreshing(true);
    try {
      const updatedUser = await onRefreshUserInfo();
      if (updatedUser) {
        toast({
          title: '信息已更新',
          description: `当前积分: ${formatPoints(updatedUser.points)}`,
        });
      }
    } catch (error) {
      toast({
        title: '刷新失败',
        description: '获取最新信息时发生错误',
        variant: 'destructive',
      });
    } finally {
      setIsRefreshing(false);
    }
  };

  if (isLoading || !userData) {
    return (
      <div className="p-4 max-w-2xl mx-auto space-y-6">
        {/* User Info Card Skeleton */}
        <Card className="bg-gradient-card shadow-medium">
          <CardHeader className="text-center pb-4">
            <Skeleton className="w-20 h-20 mx-auto mb-4 rounded-full" />
            <Skeleton className="h-6 w-32 mx-auto mb-2" />
            <Skeleton className="h-4 w-24 mx-auto" />
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center p-4 bg-gradient-secondary/10 rounded-lg">
              <Skeleton className="h-8 w-24 mx-auto mb-2" />
              <Skeleton className="h-4 w-16 mx-auto" />
            </div>
            <Separator />
            <div className="space-y-3">
              <div className="flex items-center space-x-3 text-sm">
                <Skeleton className="w-4 h-4" />
                <Skeleton className="h-4 w-40" />
              </div>
              <div className="flex items-center space-x-3 text-sm">
                <Skeleton className="w-4 h-4" />
                <Skeleton className="h-4 w-48" />
              </div>
              <div className="flex items-center space-x-3 text-sm">
                <Skeleton className="w-4 h-4" />
                <Skeleton className="h-4 w-full" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Redemption History Skeleton */}
        <Card className="bg-gradient-card shadow-soft">
          <CardHeader>
            <Skeleton className="h-6 w-40" />
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <Skeleton className="w-10 h-10 rounded-lg" />
                    <div className="space-y-2">
                      <Skeleton className="h-4 w-24" />
                      <Skeleton className="h-3 w-16" />
                    </div>
                  </div>
                  <div className="text-right space-y-2">
                    <Skeleton className="h-4 w-16" />
                    <Skeleton className="h-4 w-12" />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-2xl mx-auto space-y-6">
      {/* User Info Card */}
      <Card className="bg-gradient-card shadow-medium">
        <CardHeader className="text-center pb-4">
          <div className="w-20 h-20 mx-auto mb-4 bg-gradient-primary rounded-full flex items-center justify-center">
            <User className="w-10 h-10 text-primary-foreground" />
          </div>
          <CardTitle className="text-xl">{userData.nickname}</CardTitle>
          <p className="text-muted-foreground">积分会员</p>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {/* Points Display */}
          <div className="text-center p-4 bg-gradient-secondary/10 rounded-lg">
            <div className="flex items-center justify-center space-x-2 mb-1">
              <Award className="w-5 h-5 text-primary" />
              <span className="text-2xl font-bold text-primary">{formatPoints(userData.points)}</span>
              {onRefreshUserInfo && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleRefreshUserInfo}
                  disabled={isRefreshing}
                  className="ml-2 h-8 w-8 p-0"
                >
                  <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
                </Button>
              )}
            </div>
            <p className="text-sm text-muted-foreground">当前积分</p>
          </div>

          <Separator />

          {/* Contact Info */}
          <div className="space-y-3">
            <div className="flex items-center space-x-3 text-sm">
              <Phone className="w-4 h-4 text-muted-foreground" />
              <span>{userData.phone}</span>
            </div>

            <div className="flex items-center space-x-3 text-sm">
              <BadgeInfo className="w-4 h-4 text-muted-foreground" />
              <span>{userData.kuaishouId}</span>
            </div>

            {/* 显示收货地址 */}
            <div className="flex items-center space-x-3 text-sm">
              <MapPin className="w-4 h-4 text-muted-foreground" />
              <span className="flex-1">
                {userData.address || userData.addresses?.[0] || '暂未设置收货地址'}
              </span>
            </div>
            
            {userData.email && (
              <div className="flex items-center space-x-3 text-sm">
                <Mail className="w-4 h-4 text-muted-foreground" />
                <span>{userData.email}</span>
              </div>
            )}
          </div>

          
        </CardContent>
      </Card>

      {/* Redemption History */}
      <Card className="bg-gradient-card shadow-soft">
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <History className="w-5 h-5" />
            <span>兑换历史</span>
          </CardTitle>
        </CardHeader>
        
        <CardContent>
          {isLoadingHistory ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <Skeleton className="w-10 h-10 rounded-lg" />
                    <div className="space-y-2">
                      <Skeleton className="h-4 w-24" />
                      <Skeleton className="h-3 w-16" />
                    </div>
                  </div>
                  <div className="text-right space-y-2">
                    <Skeleton className="h-4 w-16" />
                    <Skeleton className="h-4 w-12" />
                  </div>
                </div>
              ))}
            </div>
          ) : recentRedemptions.length > 0 ? (
            <div className="space-y-4">
              {recentRedemptions.map((redemption) => (
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
              <Button asChild variant="outline" className="w-full">
                <Link to="/history">
                  查看全部记录
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Link>
              </Button>
            </div>
          ) : (
            <div className="text-center py-8">
              <Gift className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">暂无兑换记录</p>
              <Button asChild variant="link" className="mt-2">
                <Link to="/history">查看全部历史</Link>
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-4">
        <Dialog>
          <DialogTrigger asChild>
            <Button variant="outline" className="h-16 flex-col space-y-1">
              <Award className="w-5 h-5" />
              <span className="text-sm">积分规则</span>
            </Button>
          </DialogTrigger>
          <DialogContent className="w-[90vw] max-w-[425px] rounded-lg">
            <DialogHeader>
              <DialogTitle>积分规则说明</DialogTitle>
              <DialogDescription>
                了解如何获取和使用您的积分，创造更多价值。
              </DialogDescription>
            </DialogHeader>
            <ScrollArea className="h-[60vh] pr-4">
              <div className="prose prose-sm max-w-none">
                <h4>一、总则</h4>
                <p>本积分规则旨在为“积分兑换平台”的忠实用户提供回馈。所有用户在平台的活动均受本规则约束。平台保留对本规则的最终解释权和随时修改的权利。</p>

                <h4>二、如何获得积分？</h4>
                <ul>
                  <li><strong>参与推广活动：</strong>成功邀请好友注册并完成首次兑换，您和好友均可获得200积分的奖励。每位用户最多可通过邀请获得2000积分。</li>
                  <li><strong>完成特定任务：</strong>平台会不定期发布线上任务，如“完善个人资料”、“首次分享奖品”等。每完成一项任务，即可根据任务难度获得50至500不等的积分奖励。</li>
                  <li><strong>消费返点计划：</strong>在指定的线上及线下合作商户处消费，通过本平台支付或出示会员身份，每消费1元人民币即可累积1积分。特殊商品或活动期间返点比例可能更高。</li>
                  <li><strong>反馈与建议：</strong>我们鼓励用户提供宝贵的反馈。若您提交的关于平台功能或体验的建议被采纳，将一次性获得100-500积分的感谢奖励。</li>
                </ul>

                <h4>三、积分如何使用？</h4>
                <ul>
                  <li><strong>兑换虚拟奖品：</strong>积分可用于在“奖品列表”中兑换现金红包、各类购物代金券、视频网站会员等虚拟商品。兑换成功后，相应凭证将直接发放到您的账户。</li>
                  <li><strong>兑换实物奖品：</strong>您也可以使用积分兑换我们精心挑选的实物礼品。兑换时请务必确认您的收货地址准确无误。实物奖品一经发出，非质量问题不予退换。</li>
                  <li><strong>参与抽奖活动：</strong>平台会定期举办积分抽奖活动，您可使用少量积分参与，赢取高价值的惊喜大奖。</li>
                </ul>

                <h4>四、重要须知</h4>
                <ul>
                  <li>积分是本平台的专属奖励，不可在用户之间转让，亦不可兑换为人民币现金。</li>
                  <li>所有通过正常途径获得的积分，有效期为自获得之日起的365天。逾期未使用的积分将自动作废。</li>
                  <li>任何通过非正当手段（如使用作弊软件、恶意刷分等）获取的积分，一经查实，将被立即清零，并可能导致账户被永久封禁。</li>
                  <li>关于积分的所有争议，最终解释权归本平台所有。</li>
                </ul>
              </div>
            </ScrollArea>
          </DialogContent>
        </Dialog>

        <Dialog open={isAddressModalOpen} onOpenChange={setIsAddressModalOpen}>
          <DialogTrigger asChild>
            <Button variant="outline" className="h-16 flex-col space-y-1">
              <MapPin className="w-5 h-5" />
              <span className="text-sm">收货地址</span>
            </Button>
          </DialogTrigger>
          <DialogContent className="w-[90vw] max-w-[425px] rounded-lg">
            <DialogHeader>
              <DialogTitle>管理收货地址</DialogTitle>
              <DialogDescription>
                修改您的收货地址，我们将使用它来邮寄您兑换的实物奖品。
              </DialogDescription>
            </DialogHeader>
            <AddressEditor
              currentAddress={userData.address || userData.addresses?.[0] || ''}
              onSave={onAddressUpdate}
              onClose={() => setIsAddressModalOpen(false)}
            />
          </DialogContent>
        </Dialog>
      </div>
      
      {/* Logout Button */}
      <Button variant="destructive" className="w-full" onClick={onLogout}>
        <LogOut className="w-4 h-4 mr-2" />
        退出登录
      </Button>
    </div>
  );
};

export default UserProfile;