import { useState, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';
import { UserData } from '@/components/UserRegistration';
import PrizeCatalog from '@/components/PrizeCatalog';
import UserProfile from '@/components/UserProfile';
import BottomNavigation from '@/components/BottomNavigation';
import RedemptionModal, { RedemptionHistory } from '@/components/RedemptionModal';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { User, Gift, History, LogOut, MapPin, RefreshCw, ChevronRight, Loader2 } from 'lucide-react';
import { apiClient } from '@/lib/apiClient';
import { API_BASE_URL } from '@/lib/api';
import { formatPoints } from '@/lib/utils';

interface Prize {
  id: string;
  name: string;
  points: number;
  image: string;
  category: string;
  stock: number;
  description: string;
}

const CURRENT_USER_KEY = 'point-rewards-current-user';

const Index = () => {
  const [userData, setUserData] = useState<UserData | null>(null);
  const [activeTab, setActiveTab] = useState<'prizes' | 'profile'>('prizes');
  const [selectedPrize, setSelectedPrize] = useState<Prize | null>(null);
  const [isRedemptionModalOpen, setIsRedemptionModalOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();
  const navigate = useNavigate();

  // 获取最新用户信息的函数
  const fetchUserInfo = async (token: string) => {
    try {
      const response = await apiClient.get<{points: number, addresses: string[]}>(
        `${API_BASE_URL}/user/me`,
        token
      );
      
      if (response.code === 200) {
        // 只更新动态信息，保留原有的基本信息
        const updatedUserData = {
          ...userData!,
          points: response.data.points,
          addresses: response.data.addresses,
          access_token: token
        };
        
        // 更新localStorage和状态
        localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(updatedUserData));
        setUserData(updatedUserData);
        
        return updatedUserData;
      }
    } catch (error) {
      console.error('获取用户信息失败:', error);
      // token过期会在apiClient中自动处理重定向
    }
    return null;
  };

  useEffect(() => {
    const initializeUser = async () => {
      try {
        const savedUserData = localStorage.getItem(CURRENT_USER_KEY);
        if (savedUserData) {
          const parsedData: UserData = JSON.parse(savedUserData);
          setUserData(parsedData);
          
          // 只在特定情况下才刷新用户信息（比如数据可能过期时）
          // 这里可以根据需要添加时间戳判断或其他条件
          
          setActiveTab('profile'); // Redirect to profile page after login
        } else {
          navigate('/login');
        }
      } catch (error) {
        console.error("Failed to parse user data from localStorage", error);
        navigate('/login');
      } finally {
        setTimeout(() => setIsLoading(false), 500);
      }
    };

    initializeUser();
  }, [navigate]);

  // 刷新用户信息的函数（供其他组件调用）
  const refreshUserInfo = async () => {
    if (userData?.access_token) {
      const updatedUser = await fetchUserInfo(userData.access_token);
      return updatedUser;
    }
    return null;
  };

  const handlePrizeRedeem = (prize: Prize) => {
    setSelectedPrize(prize);
    setIsRedemptionModalOpen(true);
  };

  const handleRedemptionConfirm = async (prize: Prize) => {
    if (!userData) return;

    try {
      // 调用后端API进行兑换
      const response = await apiClient.post(
        `${API_BASE_URL}/redemptions/redeem`,
        {
          prize_id: prize.id,
          shipping_address: userData.addresses?.[0] || '' // 使用用户的第一个地址
        },
        userData.access_token
      );

      if (response.code === 200) {
        // 兑换成功，先显示提示
        toast({
          title: '兑换成功',
          description: `成功兑换 ${prize.name}，消耗 ${formatPoints(prize.points)} 积分`,
          duration: 7000, // 持续7秒
        });

        // 刷新用户信息以获取最新积分
        await refreshUserInfo();
        
        // 延迟2秒后重新加载页面，以刷新奖品库存等信息
        setTimeout(() => {
          window.location.reload();
        }, 2000);
      } else {
        toast({
          title: '兑换失败',
          description: response.message || '兑换过程中发生错误',
        });
      }
    } catch (error) {
      console.error('兑换失败:', error);
      // token过期会在apiClient中自动处理重定向，这里只处理其他错误
      const errorMessage = error instanceof Error ? error.message : '请稍后重试';
      if (!errorMessage.includes('Token expired')) {
        toast({
          title: '兑换失败',
          description: '网络错误，请稍后重试',
        });
      }
    }
  };

  const handleCloseRedemptionModal = () => {
    setIsRedemptionModalOpen(false);
    setSelectedPrize(null);
  };
  
  const handleLogout = () => {
    localStorage.removeItem(CURRENT_USER_KEY);
    setUserData(null);
    navigate('/login');
    toast({
      title: '已退出',
      description: '您已成功退出登录。',
    });
  };

  const handleAddressUpdate = (updatedUserData: any) => {
    setUserData(updatedUserData);
    // localStorage更新已在AddressEditor中处理
  };

  if (isLoading || !userData) {
    return (
      <div className="min-h-screen w-full flex items-center justify-center bg-background">
        <Loader2 className="w-12 h-12 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      {activeTab === 'prizes' ? (
        <PrizeCatalog
          userPoints={userData.points}
          userAddresses={userData.addresses || []}
          onRedeem={handlePrizeRedeem}
        />
      ) : (
        <UserProfile
          userData={userData}
          isLoading={isLoading}
          onLogout={handleLogout}
          onAddressUpdate={handleAddressUpdate}
          onRefreshUserInfo={refreshUserInfo}
        />
      )}

      <BottomNavigation
        activeTab={activeTab}
        onTabChange={setActiveTab}
      />

      <RedemptionModal
        prize={selectedPrize}
        userPoints={userData?.points || 0}
        userAddresses={userData?.addresses || []}
        isOpen={isRedemptionModalOpen}
        onClose={handleCloseRedemptionModal}
        onConfirm={handleRedemptionConfirm}
      />
    </div>
  );
};

export default Index;