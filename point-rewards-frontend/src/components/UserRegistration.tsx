import { Link } from 'react-router-dom';
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
import { UserPlus, ArrowLeft } from 'lucide-react';
import { Checkbox } from "./ui/checkbox";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
  } from "@/components/ui/alert-dialog";

interface UserRegistrationProps {
  onRegistrationComplete: (userData: UserData) => Promise<void>;
  onBack: () => void;
}

export interface UserData {
  nickname: string;
  kuaishouId: string;
  phone: string;
  points: number;
  password?: string;
  addresses?: string[];
}

const formSchema = z.object({
    nickname: z.string().min(1, { message: "主播昵称不能为空" }),
    kuaishouId: z.string().min(1, { message: "快手ID不能为空" }),
    phone: z.string().regex(/^1[3-9]\d{9}$/, { message: "请输入有效的11位手机号码" }),
    password: z.string().min(8, { message: "密码至少需要8个字符" }),
    confirmPassword: z.string().min(8, { message: "密码至少需要8个字符" }),
    privacyPolicy: z.boolean().refine((val) => val === true, {
      message: "您必须同意隐私协议才能注册",
    }),
  }).refine((data) => data.password === data.confirmPassword, {
    message: "两次输入的密码不一致",
    path: ["confirmPassword"], // Set the error on the confirmPassword field
  });

const UserRegistration = ({ onRegistrationComplete, onBack }: UserRegistrationProps) => {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      nickname: "",
      kuaishouId: "",
      phone: "",
      password: "",
      confirmPassword: "",
      privacyPolicy: false,
    },
  });

  const onSubmit = async (values: z.infer<typeof formSchema>) => {
    const userData: UserData = {
        nickname: values.nickname,
        kuaishouId: values.kuaishouId,
        phone: values.phone,
        password: values.password,
        points: 1000, // 默认初始积分
      };
    await onRegistrationComplete(userData);
  };

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-md mx-auto">
        <div className="flex items-center mb-6">
          <Button variant="ghost" onClick={onBack} className="mr-2">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="text-2xl font-bold">主播信息登记</h1>
        </div>

        <Card className="bg-gradient-card shadow-medium animate-fade-in">
          <CardHeader className="text-center">
            <div className="w-16 h-16 mx-auto mb-4 bg-gradient-primary rounded-full flex items-center justify-center">
              <UserPlus className="w-8 h-8 text-primary-foreground" />
            </div>
            <CardTitle>绑定主播个人信息</CardTitle>
          </CardHeader>
          
          <CardContent>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="nickname"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>主播快手ID昵称 <span className="text-red-500">*</span></FormLabel>
                      <FormControl>
                        <Input placeholder="请输入您的快手昵称" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="kuaishouId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>主播快手ID账号 <span className="text-red-500">*</span></FormLabel>
                      <FormControl>
                        <Input placeholder="请输入您的快手ID" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>主播手机号 <span className="text-red-500">*</span></FormLabel>
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
                      <FormLabel>密码 <span className="text-red-500">*</span></FormLabel>
                      <FormControl>
                        <Input type="password" placeholder="请输入至少8位的密码" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="confirmPassword"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>确认密码 <span className="text-red-500">*</span></FormLabel>
                      <FormControl>
                        <Input type="password" placeholder="请再次输入密码" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="privacyPolicy"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-4 shadow">
                        <FormControl>
                            <Checkbox
                            checked={field.value}
                            onCheckedChange={field.onChange}
                            />
                        </FormControl>
                        <div className="space-y-1 leading-none">
                            <FormLabel>
                            同意我们的
                            <AlertDialog>
                                <AlertDialogTrigger asChild>
                                <span className="text-blue-500 hover:underline cursor-pointer">隐私协议</span>
                                </AlertDialogTrigger>
                                <AlertDialogContent className="max-w-sm rounded-lg">
                                <AlertDialogHeader>
                                    <AlertDialogTitle>隐私协议</AlertDialogTitle>
                                    <AlertDialogDescription className="max-h-60 overflow-y-auto pr-4">
                                        <p className="mb-4">更新日期：2024年7月29日</p>
                                        <p className="mb-4">欢迎您使用我们的服务！我们非常重视您的隐私保护和个人信息安全。本隐私协议旨在向您说明我们如何收集、使用、存储和保护您的个人信息，以及您享有的权利。</p>
                                        <h3 className="font-bold mb-2">一、我们如何收集和使用您的个人信息</h3>
                                        <p className="mb-4">为了向您提供积分兑换服务，我们会收集和使用您的以下信息：</p>
                                        <ul className="list-disc list-inside mb-4">
                                            <li><strong>注册信息：</strong>当您注册时，我们会收集您的昵称、快手ID、手机号码。此信息用于创建您的账户并与您联系。</li>
                                            <li><strong>设备信息：</strong>我们可能会收集您的设备型号、操作系统版本等信息，以保障您的账户安全和优化我们的服务。</li>
                                            <li><strong>日志信息：</strong>当您使用我们的服务时，我们会自动收集您的某些日志信息，例如IP地址、访问日期和时间等。</li>
                                        </ul>
                                        <h3 className="font-bold mb-2">二、我们如何保护您的个人信息</h3>
                                        <p className="mb-4">我们采用符合业界标准的安全技术和措施来保护您的个人信息，防止数据丢失、滥用、未经授权的访问或泄露。我们会对数据进行加密传输，并使用加密技术对您的个人敏感信息进行加密保存。</p>
                                        <h3 className="font-bold mb-2">三、您的权利</h3>
                                        <p className="mb-4">您有权访问、更正、删除您的个人信息。您也可以随时注销您的账户。如果您想行使这些权利，请通过我们的客服渠道与我们联系。</p>
                                        <h3 className="font-bold mb-2">四、协议的更新</h3>
                                        <p className="mb-4">我们可能会不时更新本隐私协议。当协议发生重大变更时，我们会通过推送通知、弹窗等形式向您展示变更后的协议。请您注意，只有在您确认同意后，我们才会按照更新后的协议处理您的个人信息。</p>
                                        <p>感谢您的信任！</p>
                                    </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                    <AlertDialogAction>我已阅读并同意</AlertDialogAction>
                                </AlertDialogFooter>
                                </AlertDialogContent>
                            </AlertDialog>
                            </FormLabel>
                            <FormMessage />
                        </div>
                    </FormItem>
                  )}
                />
                <Button
                  type="submit"
                  disabled={form.formState.isSubmitting}
                  className="w-full bg-gradient-primary hover:shadow-glow transition-all duration-300"
                  size="lg"
                >
                  {form.formState.isSubmitting ? '注册中...' : '确认注册'}
                </Button>
              </form>
            </Form>
          </CardContent>
        </Card>

        <div className="mt-6 text-center text-sm">
          <span className="text-muted-foreground">已有账户？ </span>
          <Link to="/login" className="text-primary hover:underline">
            立即登录
          </Link>
        </div>
      </div>
    </div>
  );
};

export default UserRegistration;