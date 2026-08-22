"use client";

import { MapPin } from "lucide-react";

export default function LocationsSection() {
  return (
    <section className="py-16 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Title */}
        <div className="text-center mb-10">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            خدماتنا متاحة حاليًا في
          </h2>
        </div>

        {/* Locations Grid & Expansion Badge */}
        <div className="max-w-4xl mx-auto flex flex-col md:flex-row items-center justify-center gap-6">
          {/* Card 1: Cairo */}
          <div className="flex-1 w-full max-w-sm bg-white rounded-3xl border border-slate-100 shadow-lg p-6 flex items-center justify-between hover:border-blue-300 hover:shadow-xl transition-all group">
            {/* Architectural Line Illustration */}
            <div className="w-24 h-16 relative flex items-center justify-center opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all text-[#0091FF]">
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
              <h3 className="text-xl font-black text-slate-900 group-hover:text-[#0091FF] transition-colors">
                القاهرة
              </h3>
              <p className="text-xs text-slate-400 font-bold mt-1">تغطية شاملة لكافة الأحياء</p>
            </div>
          </div>

          {/* Card 2: Giza */}
          <div className="flex-1 w-full max-w-sm bg-white rounded-3xl border border-slate-100 shadow-lg p-6 flex items-center justify-between hover:border-blue-300 hover:shadow-xl transition-all group">
            {/* Pyramids Line Illustration */}
            <div className="w-24 h-16 relative flex items-center justify-center opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all text-[#0091FF]">
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
              <h3 className="text-xl font-black text-slate-900 group-hover:text-[#0091FF] transition-colors">
                الجيزة
              </h3>
              <p className="text-xs text-slate-400 font-bold mt-1">زايد، أكتوبر، وكافة المناطق</p>
            </div>
          </div>

          {/* Expansion Notice */}
          <div className="flex items-center gap-2 px-5 py-3 rounded-2xl bg-blue-50/80 border border-blue-100 text-[#0D327D] text-xs font-black shadow-sm">
            <MapPin className="w-4 h-4 text-[#0091FF]" />
            <span>نتوسع لمزيد من المناطق قريباً</span>
          </div>
        </div>
      </div>
    </section>
  );
}
