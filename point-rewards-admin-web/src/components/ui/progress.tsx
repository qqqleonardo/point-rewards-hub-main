import * as React from "react"
import { cn } from "@/lib/utils"

interface ProgressProps extends React.HTMLAttributes<HTMLDivElement> {
  value?: number
  max?: number
}

const Progress = React.forwardRef<HTMLDivElement, ProgressProps>(
  ({ className, value, max = 100, ...props }, ref) => {
    const percentage = value !== undefined ? Math.min(Math.max((value / max) * 100, 0), 100) : 0

    return (
      <div
        ref={ref}
        className={cn(
          "relative h-4 w-full overflow-hidden rounded-full bg-gray-200",
          className
        )}
        {...props}
      >
        <div
          className={cn(
            "h-full transition-all duration-500 ease-in-out rounded-full",
            value === undefined
              ? "bg-blue-600 animate-pulse" // 不确定进度时显示脉冲动画
              : "bg-blue-600"
          )}
          style={{
            width: value === undefined ? "100%" : `${percentage}%`,
          }}
        />
      </div>
    )
  }
)

Progress.displayName = "Progress"

export { Progress }