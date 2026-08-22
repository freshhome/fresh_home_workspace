import React from "react";
import Link from "next/link";

interface LogoProps {
  className?: string;
  size?: "sm" | "md" | "lg";
}

export default function Logo({
  className = "",
  size = "md",
}: LogoProps) {
  const imgHeightClass =
    size === "sm" ? "h-7 sm:h-8" : size === "lg" ? "h-11 sm:h-12" : "h-9 sm:h-10";
  const framePadding =
    size === "sm" ? "px-2.5 py-1 rounded-xl" : size === "lg" ? "px-4 py-2.5 rounded-3xl" : "px-3.5 py-1.5 rounded-2xl";

  return (
    <Link href="/" className={`inline-flex items-center group ${className}`}>
      {/* Frame container in #F5F7FA */}
      <div
        className={`bg-[#F5F7FA] ${framePadding} border border-slate-200/90 shadow-sm flex items-center justify-center transition-all duration-300 group-hover:shadow-md group-hover:border-[#0091FF]/40 group-hover:scale-102`}
      >
        <img
          src="/images/fresh_home_logo.png"
          alt="Fresh Home فريش هوم"
          className={`${imgHeightClass} w-auto object-contain`}
        />
      </div>
    </Link>
  );
}
