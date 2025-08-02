import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { LogIn } from 'lucide-react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { useToast } from "@/hooks/use-toast";
import { apiClient } from "@/lib/apiClient";
import { API_BASE_URL } from "@/lib/api";
import { encryptPassword } from "@/lib/encryption";

const CURRENT_USER_KEY = 'point-rewards-current-user';

const formSchema = z.object({
  phone: z.string().regex(/^1[3-9]\d{9}$/, { message: "请输入有效的11位手机号码" }),
  password: z.string().min(8, { message: "密码至少需要8个字符" }),
});

interface LoginData {
  id: number;
  nickname: string;
  kuaishouId: string;
  phone: string;
  points: number;
  addresses: string[];
  access_token: string;
}

const Login = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [searchParams] = useSearchParams();
  const inviter = searchParams.get('inviter');
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      phone: "",
      password: "",
    },
  });

  const handleLogin = async (data: z.infer<typeof formSchema>) => {
    try {
      // AES加密密码
      const encryptedPassword = encryptPassword(data.password);
      
      const response = await apiClient.post<LoginData>(
        `${API_BASE_URL}/auth/login`,
        {
          phone: data.phone,
          password: encryptedPassword, // 发送加密后的密码
        }
      );

      if (response.code === 200) {
        // 创建安全的用户数据副本，移除可能的敏感信息
        const safeUserData = {
          id: response.data.id,
          nickname: response.data.nickname,
          kuaishouId: response.data.kuaishouId,
          phone: response.data.phone,
          points: response.data.points,
          addresses: response.data.addresses,
          access_token: response.data.access_token
        };
        
        localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(safeUserData));
        
        toast({
          title: '登录成功',
          description: `欢迎回来, ${response.data.nickname}!`,
        });
        
        navigate('/');
      }
    } catch (error: any) {
      toast({
        title: '登录失败',
        description: error.message || '登录过程中发生错误',
        variant: 'destructive',
      });
    }
  };

  return (
    <div className="min-h-screen bg-background p-4 flex items-center justify-center">
      <div className="max-w-md w-full">
        <Card className="bg-gradient-card shadow-medium animate-fade-in">
          <CardHeader className="text-center">
            <div className="w-16 h-16 mx-auto mb-4 bg-gradient-primary rounded-full flex items-center justify-center">
              <LogIn className="w-8 h-8 text-primary-foreground" />
            </div>
            <CardTitle>欢迎回来</CardTitle>
          </CardHeader>
          
          <CardContent>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(handleLogin)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>手机号</FormLabel>
                      <FormControl>
                        <Input type="tel" placeholder="请输入您的手机号码" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>密码</FormLabel>
                      <FormControl>
                        <Input type="password" placeholder="请输入您的密码" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <Button
                  type="submit"
                  disabled={form.formState.isSubmitting}
                  className="w-full bg-gradient-primary hover:shadow-glow transition-all duration-300"
                  size="lg"
                >
                  {form.formState.isSubmitting ? '登录中...' : '登录'}
                </Button>
              </form>
            </Form>
          </CardContent>
        </Card>

        <div className="mt-6 text-center text-sm">
          <span className="text-muted-foreground">还没有账户？ </span>
          <Link 
            to={inviter ? `/register?inviter=${inviter}` : "/register"} 
            className="text-primary hover:underline"
          >
            立即注册
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Login;
