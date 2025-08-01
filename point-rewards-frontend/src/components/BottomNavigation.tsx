import { Button } from '@/components/ui/button';
import { Gift, User } from 'lucide-react';

interface BottomNavigationProps {
  activeTab: 'prizes' | 'profile';
  onTabChange: (tab: 'prizes' | 'profile') => void;
}

const BottomNavigation = ({ activeTab, onTabChange }: BottomNavigationProps) => {
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-card border-t border-border shadow-medium">
      <div className="flex">
        <Button
          variant={activeTab === 'prizes' ? 'default' : 'ghost'}
          onClick={() => onTabChange('prizes')}
          className="flex-1 h-16 rounded-none flex-col space-y-1"
        >
          <Gift className="w-5 h-5" />
          <span className="text-sm">奖品</span>
        </Button>
        
        <Button
          variant={activeTab === 'profile' ? 'default' : 'ghost'}
          onClick={() => onTabChange('profile')}
          className="flex-1 h-16 rounded-none flex-col space-y-1"
        >
          <User className="w-5 h-5" />
          <span className="text-sm">我的</span>
        </Button>
      </div>
    </div>
  );
};

export default BottomNavigation;