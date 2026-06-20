"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { Sparkles, Bug, Wrench, ChevronLeft } from "lucide-react";
import { supabase } from "@/lib/supabase";

const SERVICE_THEME_MAP: Record<string, { icon: any; color: string; iconBg: string; badge: string; englishTitle: string }> = {
  "FH-S-100001": {
    icon: Sparkles,
    color: "bg-teal-50 text-teal-600 border-teal-100 hover:border-teal-300",
    iconBg: "bg-teal-500/10 text-teal-600",
    badge: "الأكثر طلباً",
    englishTitle: "Cleaning & Upholstery"
  },
  "FH-S-100003": {
    icon: Bug,
    color: "bg-rose-50 text-rose-600 border-rose-100 hover:border-rose-300",
    iconBg: "bg-rose-500/10 text-rose-600",
    badge: "إبادة فورية بضمان",
    englishTitle: "Pest Control"
  },
  "FH-S-100002": {
    icon: Wrench,
    color: "bg-amber-50 text-amber-600 border-amber-100 hover:border-amber-300",
    iconBg: "bg-amber-500/10 text-amber-600",
    badge: "فنيون معتمدون",
    englishTitle: "Home Maintenance"
  }
};

export default function ServicesGrid() {
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchServices() {
      try {
        const { data, error } = await supabase
          .from("services")
          .select("*")
          .is("parent_id", null)
          .eq("status", "active")
          .order("sort_order", { ascending: true });

        if (error) throw error;
        setServices(data || []);
      } catch (e) {
        console.error("Error fetching main services:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchServices();
  }, []);

  return (
    <section id="services" className="py-16 bg-slate-50 scroll-mt-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section title */}
        <div className="text-center max-w-xl mx-auto mb-12 space-y-3">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">تصفح أقسام خدماتنا المنزلية</h2>
          <div className="w-12 h-1 bg-secondary mx-auto rounded-full"></div>
          <p className="text-slate-500 text-sm leading-relaxed">
            اختار القسم المناسب وسنقوم بحساب السعر لك وتعيين أقرب فني متخصص وحاصل على أعلى التقييمات في منطقتك الجغرافية بمصر.
          </p>
        </div>

        {/* Services Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {loading ? (
            // Loading Skeletons
            Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl border border-slate-100 p-6 shadow-sm space-y-6 animate-pulse">
                <div className="flex justify-between items-start">
                  <div className="w-12 h-12 bg-slate-200 rounded-xl"></div>
                  <div className="w-20 h-5 bg-slate-200 rounded-full"></div>
                </div>
                <div className="space-y-3">
                  <div className="w-1/2 h-5 bg-slate-200 rounded"></div>
                  <div className="w-1/4 h-3 bg-slate-200 rounded"></div>
                  <div className="w-full h-12 bg-slate-200 rounded"></div>
                </div>
              </div>
            ))
          ) : (
            services.map((serve) => {
              const theme = SERVICE_THEME_MAP[serve.id] || {
                icon: Sparkles,
                color: "bg-slate-50 text-slate-600 border-slate-100 hover:border-slate-350",
                iconBg: "bg-slate-500/10 text-slate-600",
                badge: "خدمة معتمدة",
                englishTitle: serve.title?.en || "Service"
              };
              const Icon = theme.icon;
              const arTitle = serve.title?.ar || serve.title;
              const arDesc = serve.description?.ar || serve.description;

              return (
                <div 
                  key={serve.id}
                  className="bg-white rounded-2xl border border-slate-100 p-6 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between group transform hover:-translate-y-1"
                >
                  <div className="space-y-4">
                    {/* Icon & Badge */}
                    <div className="flex justify-between items-start">
                      <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${theme.iconBg}`}>
                        <Icon className="w-6 h-6 stroke-[2]" />
                      </div>
                      <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full border ${theme.color}`}>
                        {theme.badge}
                      </span>
                    </div>

                    {/* Title & Desc */}
                    <div className="space-y-2">
                      <h3 className="text-lg font-extrabold text-slate-800 tracking-tight group-hover:text-primary transition-colors">
                        {arTitle}
                      </h3>
                      <span className="block text-[10px] text-slate-400 font-bold -mt-1 tracking-wider uppercase">
                        {theme.englishTitle}
                      </span>
                      <p className="text-slate-500 text-sm leading-relaxed line-clamp-3">
                        {arDesc}
                      </p>
                    </div>
                  </div>

                  {/* Quick CTA */}
                  <div className="mt-8 pt-4 border-t border-slate-50 flex items-center justify-between">
                    <span className="text-[11px] font-bold text-slate-400">حجز فوري كضيف</span>
                    <Link 
                      href={`/booking?serviceId=${serve.id}`}
                      className="flex items-center gap-1 text-sm font-bold text-primary group-hover:text-secondary transition-all"
                    >
                      <span>احجز الآن</span>
                      <ChevronLeft className="w-4 h-4 transform group-hover:-translate-x-1 transition-transform" />
                    </Link>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </section>
  );
}

