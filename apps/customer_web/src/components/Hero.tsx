"use client";

import Link from "next/link";
import { ArrowLeft, Calculator, ShieldCheck, Users, Lock, FileText } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative min-h-[640px] lg:min-h-[720px] flex flex-col justify-between pt-28 sm:pt-36 pb-12 overflow-hidden bg-[#06112c]">
      {/* Background Transformation Image with Vignette Overlay */}
      <div className="absolute inset-0 z-0">
        <img
          src="/images/hero_transformation.jpg"
          alt="من آثار التشطيب لبيت جاهز للحياة - Fresh Home"
          className="w-full h-full object-cover object-center scale-105 filter brightness-75 contrast-110"
        />
        {/* Deep dark gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#06112c] via-[#06112c]/80 to-[#06112c]/65" />
        <div className="absolute inset-0 bg-radial from-transparent via-[#06112c]/40 to-[#06112c]" />
      </div>

      {/* Hero Content Container */}
      <div className="relative z-10 max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center my-auto">
        {/* Main Headline */}
        <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black text-white leading-tight sm:leading-tight lg:leading-tight tracking-tight mb-5">
          من آثار التشطيب...
          <br />
          <span className="text-[#22A5FC] drop-shadow-[0_0_25px_rgba(34,165,252,0.45)]">
            لبيت جاهز للحياة.
          </span>
        </h1>

        {/* Sub-headline */}
        <p className="text-sm sm:text-base lg:text-lg text-slate-200/90 max-w-2xl mx-auto leading-relaxed font-medium mb-8">
          Fresh Home تقدم خدمات تنظيف وصيانة ومكافحة حشرات
          <br className="hidden sm:inline" />
          احترافية توصلك لحد باب بيتك.
        </p>

        {/* Actions Box */}
        <div className="flex flex-col items-center gap-3.5 max-w-md mx-auto">
          {/* Main Book Now Button */}
          <Link
            href="/booking"
            className="w-full sm:w-80 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-[#0091FF] via-[#0080FF] to-[#0066E6] hover:opacity-95 text-white font-black text-base glow-button flex items-center justify-center gap-3 shadow-xl transition-transform active:scale-98"
          >
            <span className="w-7 h-7 rounded-full bg-white/20 flex items-center justify-center">
              <ArrowLeft className="w-4 h-4 text-white stroke-[2.5]" />
            </span>
            <span>احجز الآن</span>
          </Link>

          {/* Two Secondary Buttons */}
          <div className="flex items-center gap-3 w-full justify-center">
            <Link
              href="#services"
              className="flex-1 max-w-[190px] py-2.5 px-4 rounded-xl bg-white/10 hover:bg-white/15 border border-white/15 text-white text-xs font-bold transition-colors flex items-center justify-center gap-2 backdrop-blur-md"
            >
              <span>تصفح الخدمات</span>
              <ArrowLeft className="w-3.5 h-3.5 text-slate-300" />
            </Link>

            <Link
              href="/booking"
              className="flex-1 max-w-[210px] py-2.5 px-4 rounded-xl bg-[#0B1E48]/80 hover:bg-[#0B1E48] border border-[#22A5FC]/30 text-white text-xs font-bold transition-colors flex items-center justify-center gap-2 backdrop-blur-md"
            >
              <Calculator className="w-3.5 h-3.5 text-[#22A5FC]" />
              <span>اعرف السعر لخدمتك</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Floating Trust Bar (White Card Attached to Hero) */}
      <div className="relative z-20 max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 w-full mt-10">
        <div className="bg-white rounded-2xl sm:rounded-3xl shadow-2xl border border-slate-100 p-4 sm:p-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 divide-y sm:divide-y-0 lg:divide-x lg:divide-x-reverse divide-slate-100">
          {/* Trust Item 1 */}
          <div className="flex items-center gap-3.5 pt-3 sm:pt-0 sm:px-2">
            <div className="w-11 h-11 rounded-2xl bg-blue-50 text-[#0091FF] flex items-center justify-center shrink-0">
              <Users className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900">فنيون موثوقون</h4>
              <p className="text-[11px] text-slate-500 font-medium">فريق مدرب ومعتمد لضمان أفضل خدمة</p>
            </div>
          </div>

          {/* Trust Item 2 */}
          <div className="flex items-center gap-3.5 pt-3 sm:pt-0 sm:px-2">
            <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-[#2ECC71] flex items-center justify-center shrink-0">
              <ShieldCheck className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900">ضمان جودة الخدمة</h4>
              <p className="text-[11px] text-slate-500 font-medium">نلتزم بأعلى معايير الجودة في كل طلب</p>
            </div>
          </div>

          {/* Trust Item 3 */}
          <div className="flex items-center gap-3.5 pt-3 sm:pt-0 sm:px-2">
            <div className="w-11 h-11 rounded-2xl bg-sky-50 text-[#22A5FC] flex items-center justify-center shrink-0">
              <Lock className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900">أمان منزلك</h4>
              <p className="text-[11px] text-slate-500 font-medium">نهتم بسلامة أغراضك وممتلكاتك</p>
            </div>
          </div>

          {/* Trust Item 4 */}
          <div className="flex items-center gap-3.5 pt-3 sm:pt-0 sm:px-2">
            <div className="w-11 h-11 rounded-2xl bg-indigo-50 text-[#0D327D] flex items-center justify-center shrink-0">
              <FileText className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <h4 className="text-sm font-extrabold text-slate-900">أسعار واضحة</h4>
              <p className="text-[11px] text-slate-500 font-medium">اعرف تكلفة خدمتك قبل التنفيذ</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
