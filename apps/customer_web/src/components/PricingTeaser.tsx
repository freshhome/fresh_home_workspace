"use client";

import Link from "next/link";
import { Home, SlidersHorizontal, FileSpreadsheet, ArrowLeft, ChevronLeft } from "lucide-react";

export default function PricingTeaser() {
  return (
    <section className="py-8 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="rounded-3xl bg-[#061536] border border-blue-900/40 p-6 sm:p-8 lg:p-10 text-white shadow-2xl overflow-hidden relative">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            {/* Left Side: 3 Connected Interactive Progress Cards */}
            <div className="lg:col-span-7 flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-2">
              {/* Card 1: Service */}
              <div className="flex-1 w-full bg-white/5 border border-white/10 rounded-2xl p-5 text-center flex flex-col items-center justify-center hover:bg-white/10 transition-colors">
                <div className="w-10 h-10 rounded-xl bg-blue-500/20 text-[#22A5FC] flex items-center justify-center mb-3">
                  <Home className="w-5 h-5" />
                </div>
                <h4 className="text-sm font-extrabold text-white mb-1">الخدمة</h4>
                <p className="text-[11px] text-slate-400 font-medium">اختر الخدمة المناسبة</p>
              </div>

              {/* Arrow Indicator */}
              <div className="hidden sm:flex text-blue-400/60">
                <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
              </div>

              {/* Card 2: Details */}
              <div className="flex-1 w-full bg-white/5 border border-white/10 rounded-2xl p-5 text-center flex flex-col items-center justify-center hover:bg-white/10 transition-colors">
                <div className="w-10 h-10 rounded-xl bg-blue-500/20 text-[#22A5FC] flex items-center justify-center mb-3">
                  <SlidersHorizontal className="w-5 h-5" />
                </div>
                <h4 className="text-sm font-extrabold text-white mb-1">التفاصيل</h4>
                <p className="text-[11px] text-slate-400 font-medium">حدد التفاصيل والاحتياجات</p>
              </div>

              {/* Arrow Indicator */}
              <div className="hidden sm:flex text-blue-400/60">
                <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
              </div>

              {/* Card 3: Final Price */}
              <div className="flex-1 w-full bg-white/5 border border-white/10 rounded-2xl p-5 text-center flex flex-col items-center justify-center hover:bg-white/10 transition-colors">
                <div className="w-10 h-10 rounded-xl bg-blue-500/20 text-[#22A5FC] flex items-center justify-center mb-3">
                  <FileSpreadsheet className="w-5 h-5" />
                </div>
                <h4 className="text-sm font-extrabold text-white mb-1">السعر النهائي</h4>
                <p className="text-[11px] text-slate-400 font-medium">اعرف التكلفة دون تعقيد</p>
              </div>
            </div>

            {/* Right Side: Headline & Direct CTA */}
            <div className="lg:col-span-5 text-right space-y-4">
              <div>
                <h2 className="text-2xl sm:text-3xl font-black text-white leading-tight">
                  اعرف تكلفة خدمتك
                  <br />
                  <span className="text-[#22A5FC]">قبل التنفيذ.</span>
                </h2>
                <p className="text-xs sm:text-sm text-slate-300 font-medium mt-2 leading-relaxed">
                  اختر خدمة وحدد التفاصيل التي تناسبك واعرف لك السعر النهائي بكل شفافية وبدون أي رسوم خفية.
                </p>
              </div>

              <div className="pt-2">
                <Link
                  href="/booking"
                  className="inline-flex items-center gap-3 px-8 py-3.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black glow-button shadow-lg"
                >
                  <span>جرب الآن</span>
                  <ArrowLeft className="w-4 h-4" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
