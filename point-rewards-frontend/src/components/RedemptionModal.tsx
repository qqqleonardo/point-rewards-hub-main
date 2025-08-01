import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Gift, Star, Check } from 'lucide-react';
import { formatPoints, canAfford } from '@/lib/utils';

interface Prize {
  id: string;
  name: string;
  points: number;
  image: string;
  category: string;
  stock: number;
  description: string;
}

export interface RedemptionHistory {
    id: string;
    prizeName: string;
    points: number;
    date: string;
    status: 'completed' | 'pending' | 'processing';
}

interface RedemptionModalProps {
  prize: Prize | null;
  userPoints: number;
  userAddresses: string[];
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (prize: Prize) => void;
}

const RedemptionModal = ({ prize, userPoints, userAddresses, isOpen, onClose, onConfirm }: RedemptionModalProps) => {
  const [isRedeeming, setIsRedeeming] = useState(false);
  const [isRedeemed, setIsRedeemed] = useState(false);

  if (!prize) return null;

  const hasAddress = userAddresses && userAddresses.length > 0 && userAddresses[0] && userAddresses[0].trim() !== '';
  const canRedeem = canAfford(userPoints, prize.points) && prize.stock > 0; // 地址验证已在点击时处理

  const handleConfirm = async () => {
    if (!canRedeem) return;
    
    setIsRedeeming(true);
    
    // Simulate redemption process
    setTimeout(() => {
      setIsRedeeming(false);
      setIsRedeemed(true);
      onConfirm(prize);
      
      // Auto close after showing success
      setTimeout(() => {
        setIsRedeemed(false);
        onClose();
      }, 2000);
    }, 1500);
  };

  const handleClose = () => {
    if (isRedeeming) return;
    setIsRedeemed(false);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-sm mx-auto">
        <DialogHeader>
          <DialogTitle className="text-center">
            {isRedeemed ? '兑换成功' : '确认兑换'}
          </DialogTitle>
          <DialogDescription asChild>
            <div className="text-center">
              {isRedeemed ? '恭喜您成功兑换奖品！' : '请确认兑换以下奖品'}
            </div>
          </DialogDescription>
        </DialogHeader>

        <div className="py-6">
          {isRedeemed ? (
            <div className="text-center animate-fade-in">
              <div className="w-16 h-16 mx-auto mb-4 bg-success rounded-full flex items-center justify-center">
                <Check className="w-8 h-8 text-success-foreground" />
              </div>
              <h3 className="text-lg font-semibold mb-2">{prize.name}</h3>
              <p className="text-sm text-muted-foreground">奖品将在3-5个工作日内发放</p>
            </div>
          ) : (
            <div className="text-center">
              <div className="w-32 h-40 mx-auto mb-4 rounded-lg overflow-hidden">
                <img
                  src={prize.image}
                  alt={prize.name}
                  className="w-full h-full object-cover"
                />
              </div>
              
              <h3 className="text-lg font-semibold mb-2">{prize.name}</h3>
              <p className="text-sm text-muted-foreground mb-4">{prize.description}</p>
              
              <div className="flex items-center justify-center space-x-4 mb-4">
                <div className="flex items-center space-x-1">
                  <Gift className="w-4 h-4 text-primary" />
                  <span className="font-bold text-primary">{formatPoints(prize.points)}</span>
                  <span className="text-sm text-muted-foreground">积分</span>
                </div>
                
                <div className="flex items-center space-x-1">
                  <Star className="w-4 h-4 text-secondary" />
                  <span className="font-bold">{formatPoints(userPoints)}</span>
                  <span className="text-sm text-muted-foreground">当前积分</span>
                </div>
              </div>

              {!canRedeem && (
                <div className="space-y-2">
                  {!canAfford(userPoints, prize.points) && (
                    <Badge variant="destructive">
                      积分不足
                    </Badge>
                  )}
                  {prize.stock <= 0 && (
                    <Badge variant="destructive">
                      库存不足
                    </Badge>
                  )}
                </div>
              )}

              {canRedeem && (
                <div className="text-sm text-muted-foreground">
                  兑换后剩余积分：{formatPoints(userPoints - prize.points)}
                </div>
              )}
            </div>
          )}
        </div>

        {!isRedeemed && (
          <DialogFooter className="flex space-x-3">
            <Button variant="outline" onClick={handleClose} className="flex-1">
              取消
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={!canRedeem || isRedeeming}
              className="flex-1 bg-gradient-primary"
            >
              {isRedeeming ? '兑换中...' : '确认兑换'}
            </Button>
          </DialogFooter>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default RedemptionModal;