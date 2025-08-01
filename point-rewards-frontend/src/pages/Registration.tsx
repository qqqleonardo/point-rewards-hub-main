import UserRegistration from "../components/UserRegistration";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import { UserData } from "../components/UserRegistration";
import { apiClient } from "@/lib/apiClient";
import { API_BASE_URL } from "@/lib/api";
import { encryptPassword } from "@/lib/encryption";

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
          password: encryptedPassword, // 发送加密后的密码
        }
      );

      if (response.code === 201) {
        toast({
          title: '注册成功',
          description: `欢迎, ${response.data.nickname}! 请立即登录。`,
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
    <UserRegistration 
      onRegistrationComplete={handleRegistrationComplete} 
      onBack={handleBack} 
    />
  );
};

export default RegistrationPage;
