import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { QrCode, Scan } from 'lucide-react';

interface QRScannerProps {
  onScanComplete: () => void;
}

const QRScanner = ({ onScanComplete }: QRScannerProps) => {
  const [isScanning, setIsScanning] = useState(false);

  const handleScan = () => {
    setIsScanning(true);
    // Simulate QR scan completion after 2 seconds
    setTimeout(() => {
      setIsScanning(false);
      onScanComplete();
    }, 2000);
  };

  return (
    <div className="min-h-screen bg-gradient-primary flex flex-col items-center justify-center p-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-primary-foreground mb-2">积分兑换平台</h1>
        <p className="text-primary-foreground/80">扫描二维码进入活动</p>
      </div>

      <Card className="w-full max-w-sm bg-card/95 backdrop-blur-sm shadow-glow p-8">
        <div className="text-center">
          <div className="w-48 h-48 mx-auto mb-6 border-2 border-dashed border-muted-foreground/30 rounded-lg flex items-center justify-center bg-muted/50">
            {isScanning ? (
              <div className="animate-bounce-gentle">
                <Scan className="w-16 h-16 text-primary" />
              </div>
            ) : (
              <QrCode className="w-16 h-16 text-muted-foreground" />
            )}
          </div>
          
          <h2 className="text-xl font-semibold mb-2">扫描二维码</h2>
          <p className="text-muted-foreground mb-6">将设备摄像头对准二维码</p>
          
          <Button 
            onClick={handleScan}
            disabled={isScanning}
            className="w-full bg-gradient-primary hover:shadow-glow transition-all duration-300"
            size="lg"
          >
            {isScanning ? '正在扫描...' : '开始扫描'}
          </Button>
        </div>
      </Card>

      <div className="mt-8 text-center">
        <p className="text-primary-foreground/60 text-sm">
          或者点击上方按钮模拟扫描
        </p>
      </div>
    </div>
  );
};

export default QRScanner;