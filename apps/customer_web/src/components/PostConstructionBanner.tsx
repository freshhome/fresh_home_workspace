"use client";

import Link from "next/link";
import { ArrowLeft, Calculator, Trash2, Sparkles, UserCheck, CheckCircle2 } from "lucide-react";

export default function PostConstructionBanner() {
  return (
    <section className="py-8 bg-[#F8FAFC]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="rounded-3xl bg-[#071739] border border-blue-900/40 p-6 sm:p-8 lg:p-10 shadow-2xl text-white overflow-hidden relative">
          {/* Subtle ambient light effects */}
          <div className="absolute top-0 right-1/4 w-96 h-96 bg-[#0091FF]/10 rounded-full blur-3xl pointer-events-none" />

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center relative z-10">
            {/* Left Column: Visual Before / After Showcase */}
            <div className="lg:col-span-6 relative rounded-2xl overflow-hidden shadow-xl border border-white/10 group">
              <img
                src="/images/before_after_hallway.jpg"
                alt="تنظيف ما بعد التشطيب قبل وبعد"
                className="w-full h-[280px] sm:h-[340px] object-cover group-hover:scale-102 transition-transform duration-500"
              />

              {/* "Before" and "After" Floating Tags */}
              <div className="absolute top-4 left-4 z-10">
                <span className="px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-[11px] font-black border border-white/10">
                  قبل
                </span>
              </div>
              <div className="absolute top-4 right-4 z-10">
                <span className="px-3 py-1 rounded-full bg-[#0091FF]/80 backdrop-blur-md text-white text-[11px] font-black border border-white/20 shadow-md">
                  بعد
                </span>
              </div>

              {/* Bottom Subtle Bar */}
              <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 to-transparent p-3 text-center text-xs text-slate-300 font-bold">
                تحول كامل من موقع أعمال تشطيب إلى منزل فندقي فاخر
              </div>
            </div>

            {/* Right Column: Content & Features */}
            <div className="lg:col-span-6 text-right space-y-6">
              <div>
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-black text-white tracking-tight">
                  تنظيف ما بعد التشطيب
                </h2>
                <p className="text-sm sm:text-base text-slate-300 font-medium leading-relaxed mt-2.5">
                  خدمة متخصصة لإزالة مخلفات التشطيب والدهانات والأتربة الدقيقة لتسليم بيتك نظيف وجاهز للحياة.
                </p>
              </div>

              {/* 4 Feature Badges Grid */}
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div className="flex items-center gap-2.5 bg-white/5 border border-white/10 p-3 rounded-xl backdrop-blur-sm">
                  <Trash2 className="w-5 h-5 text-[#22A5FC] shrink-0" />
                  <span className="text-xs font-bold text-slate-200">
                    إزالة المخلفات والأتربة والدهانات
                  </span>
                </div>

                <div className="flex items-center gap-2.5 bg-white/5 border border-white/10 p-3 rounded-xl backdrop-blur-sm">
                  <Sparkles className="w-5 h-5 text-[#22A5FC] shrink-0" />
                  <span className="text-xs font-bold text-slate-200">
                    معدات غسيل وتلميع عصرية
                  </span>
                </div>

                <div className="flex items-center gap-2.5 bg-white/5 border border-white/10 p-3 rounded-xl backdrop-blur-sm">
                  <UserCheck className="w-5 h-5 text-[#22A5FC] shrink-0" />
                  <span className="text-xs font-bold text-slate-200">
                    عمالة احترافية وتخصصية
                  </span>
                </div>

                <div className="flex items-center gap-2.5 bg-white/5 border border-white/10 p-3 rounded-xl backdrop-blur-sm">
                  <CheckCircle2 className="w-5 h-5 text-[#2ECC71] shrink-0" />
                  <span className="text-xs font-bold text-slate-200">
                    جاهزية تامة للاستلام
                  </span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col sm:flex-row gap-3 pt-2">
                <Link
                  href="/booking"
                  className="py-3 px-8 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black glow-button flex items-center justify-center gap-2 shadow-lg"
                >
                  <span>احجز الآن</span>
                  <ArrowLeft className="w-4 h-4" />
                </Link>

                <Link
                  href="/booking"
                  className="py-3 px-6 rounded-xl bg-white/5 hover:bg-white/10 border border-white/15 text-white text-xs font-bold transition-colors flex items-center justify-center gap-2 backdrop-blur-md"
                >
                  <Calculator className="w-4 h-4 text-[#22A5FC]" />
                  <span>اعرف السعر المناسب لخدمتك</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
