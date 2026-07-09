import logo from "@/assets/dartonic-logo.png";
import { cn } from "@/lib/utils";

export function Logo({ className, withText = true }: { className?: string; withText?: boolean }) {
  return (
    <div className={cn("flex items-center gap-2", className)}>
      <img src={logo} alt="Dartonic logo" className="h-7 w-7" />
      {withText && (
        <span className="text-base font-semibold tracking-tight">Dartonic</span>
      )}
    </div>
  );
}