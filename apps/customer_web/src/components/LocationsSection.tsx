"use client";

import { MapPin } from "lucide-react";

export default function LocationsSection() {
  return (
    <section className="py-16 bg-white dark:bg-[#040A1C] transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Title */}
        <div className="text-center mb-10">
          <span className="text-[11px] font-black tracking-wider uppercase px-3.5 py-1 rounded-full bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/60 inline-block mb-2">
            نطاق التغطية
          </span>
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white tracking-tight">
            خدماتنا متاحة حاليًا في
          </h2>
        </div>

        {/* Locations Grid & Expansion Badge */}
        <div className="max-w-4xl mx-auto flex flex-col md:flex-row items-center justify-center gap-6">
          {/* Card 1: Cairo */}
          <div className="flex-1 w-full max-w-sm bg-[#F8FAFC] dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 shadow-sm p-6 flex items-center justify-between hover:border-blue-300 dark:hover:border-[#0091FF]/50 hover:shadow-md transition-all group">
            {/* Architectural Line Illustration */}
            <div className="w-24 h-16 relative flex items-center justify-center opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all text-[#0091FF] dark:text-[#22A5FC]">
              <svg viewBox="0 0 100 60" fill="none" className="w-full h-full stroke-current stroke-[1.8]">
                {/* Cairo Tower & Minaret Skyline */}
                <path d="M75 55V10h6v45M78 10V5M76 5h4" />
                <path d="M72 55V30h12v25" />
                <path d="M30 55V35l10-8 10 8v20" />
                <path d="M40 27V18m-2 0h4" />
                <path d="M10 55V40h15v15" />
                <path d="M5 55h90" />
              </svg>
            </div>
            <div className="text-right">
              <h3 className="text-xl font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors">
                القاهرة
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-bold mt-1">تغطية شاملة لكافة الأحياء</p>
            </div>
          </div>

          {/* Card 2: Giza */}
          <div className="flex-1 w-full max-w-sm bg-[#F8FAFC] dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 shadow-sm p-6 flex items-center justify-between hover:border-blue-300 dark:hover:border-[#0091FF]/50 hover:shadow-md transition-all group">
            {/* Pyramids Line Illustration */}
            <div className="w-24 h-16 relative flex items-center justify-center opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all text-[#0091FF] dark:text-[#22A5FC]">
              <svg viewBox="0 0 100 60" fill="none" className="w-full h-full stroke-current stroke-[1.8]">
                {/* Great Pyramids Skyline */}
                <path d="M45 55L65 15l25 40H45z" />
                <path d="M65 15v40" />
                <path d="M15 55L35 25l20 30H15z" />
                <path d="M35 25v30" />
                <path d="M5 55h90" />
              </svg>
            </div>
            <div className="text-right">
              <h3 className="text-xl font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors">
                الجيزة
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-bold mt-1">زايد، أكتوبر، وكافة المناطق</p>
            </div>
          </div>

          {/* Expansion Notice */}
          <div className="flex items-center gap-2 px-5 py-3 rounded-2xl bg-blue-50 dark:bg-blue-950/70 border border-blue-100 dark:border-blue-900/60 text-[#0D327D] dark:text-[#22A5FC] text-xs font-black shadow-sm">
            <MapPin className="w-4 h-4 text-[#0091FF]" />
            <span>نتوسع لمزيد من المناطق قريباً</span>
          </div>
        </div>
      </div>
    </section>
  );
}
