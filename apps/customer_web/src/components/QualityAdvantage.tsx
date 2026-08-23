"use client";

import { Smartphone, ShieldCheck, Headphones, CalendarClock } from "lucide-react";

export default function QualityAdvantage() {
  const advantages = [
    {
      title: "حجز سريع وسهل",
      desc: "من أي وقت وفي أي مكان",
      icon: Smartphone,
    },
    {
      title: "متابعة طلبك لحظة بلحظة",
      desc: "تتبع حالة طلبك بكل سهولة",
      icon: ShieldCheck,
    },
    {
      title: "دعم عملاء متميز",
      desc: "نحن هنا لأي استفسار على مدار الساعة",
      icon: Headphones,
    },
    {
      title: "مرونة في المواعيد",
      desc: "اختار الوقت المناسب لجدول يومك",
      icon: CalendarClock,
    },
  ];

  return (
    <section id="why-us" className="py-16 bg-[#F8FAFC] dark:bg-[#060F2B] transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
          {/* Right Side: Headline and Narrative */}
          <div className="lg:col-span-5 text-right space-y-4">
            <span className="text-[11px] font-black tracking-wider uppercase px-3.5 py-1 rounded-full bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/60 inline-block mb-2">
              لماذا Fresh Home؟
            </span>
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-black text-slate-900 dark:text-white leading-tight">
              مش مجرد خدمة تنظيف...
              <br />
              <span className="text-[#0091FF] dark:text-[#22A5FC]">تجربة أضمن وأسهل.</span>
            </h2>
            <p className="text-xs sm:text-sm text-slate-600 dark:text-slate-300 font-medium leading-relaxed">
              نستخدم أفضل المعدات والمواد، ونلتزم بالتفاصيل عشان نوفرلك تجربة مريحة وتخليك راضي في كل خطوة من خطوات العمل.
            </p>
          </div>

          {/* Left Side: Living Room Image with 4 Feature Cards Beside/Over It */}
          <div className="lg:col-span-7 grid grid-cols-1 sm:grid-cols-12 gap-4 items-center">
            {/* Visual Living Room Box with Diagonal Accent */}
            <div className="sm:col-span-7 relative rounded-3xl overflow-hidden shadow-xl border border-slate-200/80 dark:border-blue-900/50 group">
              <img
                src="/images/quality_living_room.jpg"
                alt="تجربة تنظيف فاخرة مع فريش هوم"
                className="w-full h-[320px] object-cover group-hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute top-0 right-0 w-24 h-24 bg-[#0091FF]/80 -rotate-45 transform origin-top-right backdrop-blur-md" />
            </div>

            {/* 4 Feature Items Box */}
            <div className="sm:col-span-5 space-y-3">
              {advantages.map((item) => {
                const Icon = item.icon;
                return (
                  <div
                    key={item.title}
                    className="bg-white dark:bg-[#071739] p-3.5 rounded-2xl border border-slate-200/80 dark:border-blue-900/50 shadow-sm flex items-center gap-3 text-right hover:border-blue-300 dark:hover:border-[#0091FF]/50 transition-colors"
                  >
                    <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 flex items-center justify-center shrink-0">
                      <Icon className="w-5 h-5 stroke-[2]" />
                    </div>
                    <div>
                      <h4 className="text-xs font-black text-slate-900 dark:text-white">
                        {item.title}
                      </h4>
                      <p className="text-[10px] text-slate-500 dark:text-slate-400 font-medium mt-0.5">
                        {item.desc}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
