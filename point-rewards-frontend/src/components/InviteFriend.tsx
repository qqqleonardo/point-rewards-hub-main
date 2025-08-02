import React, { useState, useEffect } from 'react';
import QRCode from 'qrcode';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { UserPlus, Share2, Copy, Check } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface InviteFriendProps {
  userId?: string;
  className?: string;
}

const InviteFriend = ({ userId, className }: InviteFriendProps) => {
  const [qrCodeUrl, setQrCodeUrl] = useState<string>('');
  const [inviteLink, setInviteLink] = useState<string>('');
  const [copied, setCopied] = useState(false);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const { toast } = useToast();

  // 生成邀请链接
  const generateInviteLink = () => {
    const baseUrl = window.location.origin;
    const inviteUrl = `${baseUrl}/#/register?inviter=${userId || 'default'}`;
    setInviteLink(inviteUrl);
    return inviteUrl;
  };

  // 生成二维码
  const generateQRCode = async (url: string) => {
    try {
      const qrDataUrl = await QRCode.toDataURL(url, {
        width: 200,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#ffffff',
        },
      });
      setQrCodeUrl(qrDataUrl);
    } catch (error) {
      toast({
        title: '生成二维码失败',
        description: '请稍后重试',
        variant: 'destructive',
      });
    }
  };

  // 复制邀请链接
  const copyInviteLink = async () => {
    try {
      // 优先使用现代 Clipboard API
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(inviteLink);
        setCopied(true);
        toast({
          title: '复制成功',
          description: '邀请链接已复制到剪贴板',
        });
        setTimeout(() => setCopied(false), 2000);
        return;
      }

      // 备用方案：使用传统的 execCommand
      const textArea = document.createElement('textarea');
      textArea.value = inviteLink;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      textArea.style.top = '-999999px';
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();
      
      const successful = document.execCommand('copy');
      document.body.removeChild(textArea);
      
      if (successful) {
        setCopied(true);
        toast({
          title: '复制成功',
          description: '邀请链接已复制到剪贴板',
        });
        setTimeout(() => setCopied(false), 2000);
      } else {
        throw new Error('复制失败');
      }
    } catch (error) {
      toast({
        title: '复制失败',
        description: '请手动复制邀请链接',
        variant: 'destructive',
      });
    }
  };

  // 分享功能
  const shareInviteLink = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: '邀请您加入积分兑换平台',
          text: '快来加入我们的积分兑换平台，兑换精美奖品！',
          url: inviteLink,
        });
      } catch (error) {
        // 分享取消或失败，静默处理
      }
    } else {
      // 如果不支持 Web Share API，则复制链接
      copyInviteLink();
    }
  };

  // 当对话框打开时生成邀请链接和二维码
  useEffect(() => {
    if (isDialogOpen) {
      const link = generateInviteLink();
      generateQRCode(link);
    }
  }, [isDialogOpen, userId]);

  return (
    <div className="fixed bottom-24 right-4 z-50">
      {/* 悬浮按钮组 */}
      <div className="relative group">
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          {/* 主按钮 */}
          <DialogTrigger asChild>
            <Button
              className="w-14 h-14 rounded-full shadow-lg bg-gradient-to-r from-primary to-primary/80 hover:from-primary/90 hover:to-primary/70 border-2 border-background transition-all duration-300 hover:scale-110"
              size="icon"
            >
              <UserPlus className="w-6 h-6" />
            </Button>
          </DialogTrigger>
          
          {/* 悬浮提示 */}
          <div className="absolute right-16 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-all duration-300 pointer-events-none">
            <div className="bg-foreground text-background px-3 py-2 rounded-lg text-sm whitespace-nowrap shadow-lg">
              邀请好友
              <div className="absolute left-full top-1/2 -translate-y-1/2 w-0 h-0 border-l-4 border-l-foreground border-t-4 border-t-transparent border-b-4 border-b-transparent"></div>
            </div>
          </div>

          {/* 波纹效果 */}
          <div className="absolute inset-0 rounded-full bg-primary/20 scale-0 group-hover:scale-150 transition-transform duration-500 -z-10"></div>
          
          <DialogContent className="w-[90vw] max-w-[400px] rounded-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center space-x-2">
            <UserPlus className="w-5 h-5" />
            <span>邀请好友</span>
          </DialogTitle>
          <DialogDescription>
            邀请好友一起注册，分享精彩的积分兑换体验！
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* 二维码展示 */}
          <Card className="bg-gradient-to-br from-primary/5 to-secondary/5">
            <CardContent className="p-6 text-center">
              <div className="mb-4">
                <h3 className="font-medium mb-2">扫描二维码邀请好友</h3>
                <p className="text-sm text-muted-foreground">好友扫码即可直接注册</p>
              </div>
              
              {qrCodeUrl ? (
                <div className="flex justify-center mb-4">
                  <div className="p-4 bg-white rounded-lg shadow-sm">
                    <img 
                      src={qrCodeUrl} 
                      alt="邀请二维码" 
                      className="w-48 h-48"
                    />
                  </div>
                </div>
              ) : (
                <div className="flex justify-center mb-4">
                  <div className="w-48 h-48 bg-muted rounded-lg flex items-center justify-center">
                    <span className="text-muted-foreground">生成中...</span>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* 邀请说明 */}
          <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
            <CardContent className="p-4">
              <div className="text-center space-y-2">
                <h4 className="font-medium text-blue-800">💫 邀请好友</h4>
                <p className="text-sm text-blue-700">
                  分享二维码或链接，邀请好友一起体验精彩的积分兑换平台
                </p>
              </div>
            </CardContent>
          </Card>

          {/* 操作按钮 */}
          <div className="grid grid-cols-2 gap-3">
            <Button
              variant="outline"
              onClick={copyInviteLink}
              className="flex items-center space-x-2"
            >
              {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
              <span>{copied ? '已复制' : '复制链接'}</span>
            </Button>
            
            <Button
              onClick={shareInviteLink}
              className="flex items-center space-x-2"
            >
              <Share2 className="w-4 h-4" />
              <span>分享邀请</span>
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
      </div>
    </div>
  );
};

export default InviteFriend;