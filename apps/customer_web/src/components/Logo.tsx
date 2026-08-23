"use client";

import React, { useRef, useEffect, useState } from "react";
import Link from "next/link";

interface LogoProps {
  className?: string;
  size?: "sm" | "md" | "lg" | "xl";
  animated?: boolean;
  href?: string;
}

export default function Logo({
  className = "",
  size = "md",
  animated = true,
  href = "/",
}: LogoProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [animLoaded, setAnimLoaded] = useState(false);

  useEffect(() => {
    let anim: any = null;
    let isMounted = true;

    if (animated) {
      import("lottie-web").then((lottieModule) => {
        if (!isMounted || !containerRef.current) return;
        const lottie = lottieModule.default || lottieModule;
        anim = lottie.loadAnimation({
          container: containerRef.current,
          renderer: "svg",
          loop: true,
          autoplay: true,
          path: "/animations/anim_splash_logo.json",
        });
        anim.addEventListener("DOMLoaded", () => {
          if (isMounted) setAnimLoaded(true);
        });
      }).catch((err) => {
        console.warn("Failed to load Lottie animation:", err);
      });
    }

    return () => {
      isMounted = false;
      if (anim) {
        anim.destroy();
      }
    };
  }, [animated]);

  const lottieDimensions =
    size === "sm" 
      ? "w-12 h-7 sm:w-14 sm:h-8" 
      : size === "lg" 
        ? "w-24 h-13" 
        : size === "xl"
          ? "w-36 h-20"
          : "w-14 h-8 sm:w-16 sm:h-9";

  const imgHeight =
    size === "sm" ? "h-6" : size === "lg" ? "h-9" : size === "xl" ? "h-14" : "h-7 sm:h-8";

  return (
    <Link href={href} className={`inline-flex items-center group ${className}`}>
      <div className="flex items-center justify-center transition-all duration-300 group-hover:scale-[1.03] relative">
        {animated && (
          <div
            ref={containerRef}
            className={`${lottieDimensions} flex items-center justify-center pointer-events-none ${
              animLoaded ? "opacity-100" : "opacity-0 absolute inset-0"
            } transition-opacity duration-300`}
          />
        )}
        
        {(!animated || !animLoaded) && (
          <img
            src="/images/fresh_home_logo_brand.svg"
            alt="Fresh Home فريش هوم"
            className={`${imgHeight} w-auto object-contain object-center block dark:brightness-110`}
          />
        )}
      </div>
    </Link>
  );
}
