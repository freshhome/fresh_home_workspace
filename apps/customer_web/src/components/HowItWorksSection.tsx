"use client";

import { SlidersHorizontal, Settings2, Tag, Home, ChevronLeft } from "lucide-react";

export default function HowItWorksSection() {
  const steps = [
    {
      number: "1",
      title: "اختار خدمتك",
      desc: "حدد الخدمة التي تحتاجها",
      icon: SlidersHorizontal,
    },
    {
      number: "2",
      title: "حدد التفاصيل",
      desc: "اكتب التفاصيل على مقاس بيتك",
      icon: Settings2,
    },
    {
      number: "3",
      title: "اعرف السعر واحجز",
      desc: "اعرف السعر النهائي واحجز بسهولة",
      icon: Tag,
    },
    {
      number: "4",
      title: "نوصلك لحد باب بيتك",
      desc: "تنفيذ الخدمة باحترافية تامة",
      icon: Home,
    },
  ];

  return (
    <section id="how-it-works" className="py-16 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Title */}
        <div className="text-center mb-14">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            أسهل طريقة للحجز
          </h2>
        </div>

        {/* 4 Steps Row with Connecting Line */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 relative">
          {steps.map((step, idx) => {
            const Icon = step.icon;
            const isLast = idx === steps.length - 1;

            return (
              <div key={step.number} className="relative flex flex-col items-center">
                {/* Connecting Dotted Indicator for desktop */}
                {!isLast && (
                  <div className="hidden lg:flex items-center absolute -left-4 top-1/2 -translate-y-1/2 z-0 text-blue-300">
                    <ChevronLeft className="w-5 h-5 text-blue-300" />
                  </div>
                )}

                {/* Step Card */}
                <div className="w-full bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-md p-6 flex flex-col items-center text-center transition-all hover:-translate-y-1 relative z-10">
                  {/* Top Floating Step Number Badge */}
                  <div className="w-7 h-7 rounded-full bg-[#0091FF] text-white text-xs font-black flex items-center justify-center -mt-9 mb-3 shadow-md shadow-blue-500/20 border-2 border-white">
                    {step.number}
                  </div>

                  {/* Icon */}
                  <div className="w-12 h-12 rounded-2xl bg-blue-50 text-[#0091FF] flex items-center justify-center mb-4">
                    <Icon className="w-6 h-6 stroke-[2]" />
                  </div>

                  {/* Title & Desc */}
                  <h3 className="text-base font-extrabold text-slate-900 mb-1.5">
                    {step.title}
                  </h3>
                  <p className="text-xs text-slate-500 font-medium">
                    {step.desc}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
