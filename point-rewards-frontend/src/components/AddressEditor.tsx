import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { apiClient } from '@/lib/apiClient';
import { API_BASE_URL } from '@/lib/api';

interface AddressEditorProps {
  currentAddress: string;
  onSave: (userData: any) => void;
  onClose: () => void;
}

interface UserUpdateResponse {
  id: number;
  nickname: string;
  kuaishouId: string;
  phone: string;
  points: number;
  addresses: string[];
}

const AddressEditor = ({ currentAddress, onSave, onClose }: AddressEditorProps) => {
  const [address, setAddress] = useState(currentAddress);
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    setAddress(currentAddress);
  }, [currentAddress]);

  const handleSave = async () => {
    if (!address.trim()) {
      toast({
        title: '地址不能为空',
        description: '请输入有效的收货地址',
        variant: 'destructive',
      });
      return;
    }

    setIsLoading(true);
    
    try {
      // 从localStorage获取token
      const userData = localStorage.getItem('point-rewards-current-user');
      if (!userData) {
        throw new Error('用户未登录');
      }
      
      const user = JSON.parse(userData);
      const token = user.access_token;

      const response = await apiClient.put<UserUpdateResponse>(
        `${API_BASE_URL}/user/address`,
        { address: address.trim() },
        token
      );

      if (response.code === 200) {
        // 更新localStorage中的用户数据
        const updatedUserData = {
          ...user,
          ...response.data,
          address: response.data.addresses?.[0] || address.trim()
        };
        localStorage.setItem('point-rewards-current-user', JSON.stringify(updatedUserData));
        
        onSave(updatedUserData);
        
        toast({
          title: '地址保存成功',
          description: '您的收货地址已更新',
        });
        
        onClose();
      }
    } catch (error: any) {
      toast({
        title: '地址保存失败',
        description: error.message || '保存地址时发生错误',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="grid gap-4 py-4">
      <div className="space-y-2">
        <Label htmlFor="address">收货地址</Label>
        <Input
          id="address"
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          placeholder="请输入详细的收货地址"
          autoFocus
          disabled={isLoading}
        />
      </div>
      <Button 
        onClick={handleSave} 
        className="w-full mt-4"
        disabled={isLoading}
      >
        {isLoading ? '保存中...' : '保存地址'}
      </Button>
    </div>
  );
};

export default AddressEditor;
