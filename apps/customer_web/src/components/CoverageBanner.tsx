"use client";

import { useState, useEffect } from "react";
import { MapPin, X, Sparkles } from "lucide-react";
import ExpansionModal from "@/components/ExpansionModal";

const STORAGE_KEY = "fresh_home_coverage_banner_dismissed";

export default function CoverageBanner() {
  const [isVisible, setIsVisible] = useState(false);
  const [detectedCity, setDetectedCity] = useState<string | null>(null);
  const [showExpansionModal, setShowExpansionModal] = useState(false);

  useEffect(() => {
    // Check if dismissed previously in localStorage
    try {
      const isDismissed = localStorage.getItem(STORAGE_KEY);
      if (isDismissed === "true") {
        return;
      }
    } catch {
      // ignore
    }

    // Call lightweight IP Geolocation check
    async function checkGeo() {
      try {
        const res = await fetch("/api/geo-check");
        if (!res.ok) return;
        const data = await res.json();

        if (data.isOutsideCoverage) {
          setIsVisible(true);
          if (data.city) {
            setDetectedCity(data.city);
          }
        }
      } catch (e) {
        // Non-blocking fail-safe: ignore network errors
      }
    }

    checkGeo();
  }, []);

  const handleDismiss = () => {
    setIsVisible(false);
    try {
      localStorage.setItem(STORAGE_KEY, "true");
    } catch {
      // ignore
    }
  };

  if (!isVisible) return null;

  return (
    <>
      <div 
        className="relative z-60 bg-gradient-to-r from-blue-700 via-sky-600 to-blue-800 text-white text-xs font-bold px-3 sm:px-4 py-2 sm:py-2.5 shadow-md transition-all duration-300"
        dir="rtl"
      >
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 flex-1 flex-wrap">
            <span className="flex items-center justify-center w-5 h-5 rounded-full bg-white/20 text-white shrink-0">
              <MapPin className="w-3.5 h-3.5" />
            </span>
            <p className="text-[11px] sm:text-xs leading-tight font-medium">
              {detectedCity ? (
                <>
                  أهلاً بك زائرنا في <span className="underline font-black">{detectedCity}</span>! 
                </>
              ) : (
                <>مرحباً بك! </>
              )}
              {" "}خدمات فريش هوم متاحة حالياً داخل <strong className="font-black text-amber-200">القاهرة والجيزة</strong> فقط، ونتوسع قريباً لكافة المحافظات.
            </p>
            <button
              type="button"
              onClick={() => setShowExpansionModal(true)}
              className="inline-flex items-center gap-1 text-[11px] font-black underline hover:text-amber-200 transition-colors cursor-pointer mr-1"
            >
              <Sparkles className="w-3 h-3 text-amber-200" />
              <span>اطلب توفير الخدمة في منطقتك ←</span>
            </button>
          </div>

          {/* Dismiss button */}
          <button
            type="button"
            onClick={handleDismiss}
            aria-label="إغلاق التنبيه"
            className="p-1 rounded-lg text-white/80 hover:text-white hover:bg-white/10 transition-colors shrink-0 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Expansion Modal */}
      <ExpansionModal
        isOpen={showExpansionModal}
        onClose={() => setShowExpansionModal(false)}
        initialCity={detectedCity || ""}
      />
    </>
  );
}
