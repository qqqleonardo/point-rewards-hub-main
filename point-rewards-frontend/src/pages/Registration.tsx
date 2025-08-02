import UserRegistration from "../components/UserRegistration";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import { UserData } from "../components/UserRegistration";
import { apiClient } from "@/lib/apiClient";
import { API_BASE_URL } from "@/lib/api";
import { encryptPassword } from "@/lib/encryption";
import { useEffect, useState } from "react";

interface RegisterResponse {
  id: number;
  nickname: string;
  kuaishouId: string;
  phone: string;
  points: number;
}

const RegistrationPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [searchParams] = useSearchParams();
  const [inviter, setInviter] = useState<string | null>(null);

  useEffect(() => {
    const inviterParam = searchParams.get('inviter');
    if (inviterParam && inviterParam !== 'default') {
      setInviter(inviterParam);
    }
  }, [searchParams]);

  const handleRegistrationComplete = async (data: UserData) => {
    try {
      // AES加密密码
      const encryptedPassword = encryptPassword(data.password!);
      
      const response = await apiClient.post<RegisterResponse>(
        `${API_BASE_URL}/auth/register`,
        {
          nickname: data.nickname,
          kuaishouId: data.kuaishouId,
          phone: data.phone,
          password: encryptedPassword,
          inviter: inviter, // 添加邀请者信息
        }
      );

      if (response.code === 201) {
        const successMessage = inviter 
          ? `欢迎, ${response.data.nickname}! 感谢通过好友邀请注册！请立即登录。`
          : `欢迎, ${response.data.nickname}! 请立即登录。`;
          
        toast({
          title: '注册成功',
          description: successMessage,
          duration: 6000,
        });
        navigate('/login');
      }
    } catch (error: any) {
      toast({
        title: '注册失败',
        description: error.message || '注册过程中发生错误',
        variant: 'destructive',
      });
    }
  };

  const handleBack = () => {
    navigate('/login');
  };

  return (
    <div>
      {inviter && (
        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4 mb-6 mx-4 mt-6">
          <div className="text-center">
            <h3 className="font-medium text-blue-800 mb-1">🎉 您正在通过好友邀请注册</h3>
            <p className="text-sm text-blue-700">
              欢迎加入我们的积分兑换平台！
            </p>
          </div>
        </div>
      )}
      <UserRegistration 
        onRegistrationComplete={handleRegistrationComplete} 
        onBack={handleBack} 
      />
    </div>
  );
};

export default RegistrationPage;
