"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { Star, Check, Sparkles, ChevronLeft } from "lucide-react";
import { supabase } from "@/lib/supabase";

export default function PopularServices() {
  const [popularServices, setPopularServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchPopularServices() {
      try {
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("*")
          .eq("is_bookable", true)
          .limit(4);

        if (error) throw error;

        // Fetch real ratings and review counts from reviews table
        const subIds = (data || []).map((s: any) => s.id);
        const ratingsMap: Record<string, { avg: number; count: number }> = {};
        if (subIds.length > 0) {
          const { data: revs } = await supabase
            .from("reviews")
            .select("service_id, rating_value")
            .eq("status", "published")
            .in("service_id", subIds);
          
          if (revs) {
            const tempMap: Record<string, { sum: number; count: number }> = {};
            revs.forEach((r: any) => {
              if (!tempMap[r.service_id]) {
                tempMap[r.service_id] = { sum: 0, count: 0 };
              }
              tempMap[r.service_id].sum += r.rating_value;
              tempMap[r.service_id].count += 1;
            });
            Object.keys(tempMap).forEach(k => {
              ratingsMap[k] = {
                avg: Number((tempMap[k].sum / tempMap[k].count).toFixed(1)),
                count: tempMap[k].count
              };
            });
          }
        }

        const updatedServices = (data || []).map((s: any) => ({
          ...s,
          rating: ratingsMap[s.id]?.avg ?? 5.0,
          reviewsCount: ratingsMap[s.id]?.count ?? 0
        }));
        setPopularServices(updatedServices);
      } catch (e) {
        console.error("Error fetching popular services:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchPopularServices();
  }, []);

  return (
    <section className="py-16 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section header */}
        <div className="flex flex-col sm:flex-row justify-between items-end gap-4 mb-10 pb-6 border-b border-slate-100">
          <div className="space-y-2 text-right">
            <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">الخدمات الأكثر طلبًا</h2>
            <p className="text-slate-500 text-sm max-w-lg">
              تعرف على الخدمات الأكثر اختيارًا من عملائنا، واحجز الخدمة المناسبة بكل سهولة.
            </p>
          </div>
          <Link 
            href="/booking" 
            className="text-primary hover:text-secondary font-bold text-sm flex items-center gap-1 shrink-0"
          >
            <span>احجز خدمة مخصصة</span>
          </Link>
        </div>

        {/* Popular list grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {loading ? (
            // Loading Skeletons
            Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="bg-slate-50 rounded-2xl p-5 border border-slate-100 space-y-6 animate-pulse">
                <div className="flex justify-between items-center">
                  <div className="w-16 h-4 bg-slate-200 rounded"></div>
                  <div className="w-12 h-4 bg-slate-200 rounded"></div>
                </div>
                <div className="w-3/4 h-5 bg-slate-200 rounded"></div>
                <div className="space-y-2 border-t border-slate-200/60 pt-3">
                  <div className="w-full h-3 bg-slate-200 rounded"></div>
                  <div className="w-5/6 h-3 bg-slate-200 rounded"></div>
                </div>
                <div className="pt-4 border-t border-slate-200/60 flex justify-between">
                  <div className="w-16 h-8 bg-slate-200 rounded"></div>
                  <div className="w-20 h-8 bg-slate-200 rounded"></div>
                </div>
              </div>
            ))
          ) : (
            popularServices.map((sub) => {
              const charSum = sub.id.split("").reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0);
              // Real reviews info
              const rating = sub.rating;
              const reviews = sub.reviewsCount;

              // Badge calculation
              const badges = ["الأكثر مبيعاً", "عروض ممتازة", "سرعة تنفيذ", "فنيون معتمدون"];
              const badge = badges[charSum % badges.length];

              // Price Label Calculation
              let priceLabel = "تبدأ من 250 ج.م";
              const priceConfig = sub.price_config || {};
              const minPrice = priceConfig.min_price || sub.min_price;
              const value = priceConfig.value;

              if (minPrice && minPrice > 0) {
                priceLabel = `تبدأ من ${minPrice} ج.م`;
              } else if (value && value > 0) {
                priceLabel = `تبدأ من ${value} ج.م`;
              } else if (priceConfig.fields && priceConfig.fields.length > 0) {
                const firstField = priceConfig.fields[0];
                const mod = firstField.price_modifier;
                if (mod && mod > 0) {
                  priceLabel = `تبدأ من ${mod} ج.م`;
                }
              }

              // Highlights selection
              let highlights = ["فحص وتشخيص دقيق", "تنفيذ احترافي وسريع", "ضمان جودة الخدمة"];
              const serviceTitle = (sub.title?.ar || sub.title || "").toLowerCase();
              
              if (serviceTitle.includes("كهرباء")) {
                highlights = ["تشخيص الأعطال وصيانتها", "تركيب واستبدال المكونات", "فحص السلامة قبل الإنهاء"];
              } else if (serviceTitle.includes("سباكة")) {
                highlights = ["كشف وتصليح التسريبات", "تركيب الخلطات والأدوات الصحية", "تسليك وصيانة شبكات الصرف"];
              } else if (serviceTitle.includes("تنظيف") || serviceTitle.includes("نظافة") || serviceTitle.includes("غسيل")) {
                highlights = ["إزالة الأتربة والبقع الصعبة", "تطهير وتعقيم كامل للأسطح", "استخدام مواد آمنة وصديقة للبيئة"];
              } else if (serviceTitle.includes("حشرات") || serviceTitle.includes("إبادة") || serviceTitle.includes("آفات")) {
                highlights = ["إبادة فورية بضمان ممتد", "استخدام أمصال آمنة وبدون رائحة", "مكافحة النمل، الصراصير والقوارض"];
              } else if (serviceTitle.includes("تكييف") || serviceTitle.includes("تكييفات")) {
                highlights = ["تنظيف الفلاتر والوحدات", "فحص وشحن مستوى الفريون", "كشف الأعطال وتحسين الكفاءة"];
              }

              if (sub.details && Array.isArray(sub.details) && sub.details.length > 0) {
                highlights = sub.details.slice(0, 3).map((d: any) => typeof d === "string" ? d : (d.ar?.title || d.title?.ar || d.title || JSON.stringify(d)));
              } else if (sub.price_config?.fields && sub.price_config.fields.length > 0) {
                highlights = sub.price_config.fields.slice(0, 3).map((f: any) => f.label?.ar || f.label);
              }

              const arTitle = sub.title?.ar || sub.title;

              return (
                <Link 
                  key={sub.id}
                  href={`/services/details?serviceId=${sub.parent_id}&subServiceId=${sub.id}`}
                  data-track="service-card-popular"
                  className="bg-white rounded-[20px] border border-slate-100/60 hover:border-secondary shadow-[0_8px_40px_rgba(0,0,0,0.05)] hover:shadow-lg transition-all duration-300 flex flex-col justify-between group overflow-hidden transform hover:-translate-y-1 text-right block"
                >
                  {/* Top Image Container */}
                  <div className="relative h-[140px] w-full bg-service-bg border-b border-primary/5 flex items-center justify-center p-4">
                    {sub.image ? (
                      <img 
                        src={sub.image} 
                        alt={arTitle} 
                        className="w-20 h-20 object-contain transition-transform duration-300 group-hover:scale-105"
                      />
                    ) : (
                      <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-primary/45">
                        <Sparkles className="w-6 h-6" />
                      </div>
                    )}
                    
                    {/* Badge Overlay */}
                    <span className="absolute top-3 right-3 bg-primary/90 text-white font-extrabold px-2 py-0.5 rounded-md text-[9px] shadow-xs">
                      {badge}
                    </span>

                    {/* Rating Overlay */}
                    <div className="absolute top-3 left-3 bg-white/90 text-amber-500 font-extrabold px-2 py-0.5 rounded-md text-[9px] flex items-center gap-1 shadow-xs">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      <span>{rating}</span>
                    </div>
                  </div>

                  {/* Card Content */}
                  <div className="p-5 flex-1 flex flex-col justify-between">
                    <div className="space-y-2">
                      <h3 className="font-extrabold text-slate-800 text-sm leading-snug group-hover:text-primary transition-colors min-h-[40px] line-clamp-2">
                        {arTitle}
                      </h3>

                      {/* Highlights */}
                      <ul className="space-y-1 text-[11px] text-slate-500 pt-2 font-sans font-light">
                        {highlights.map((hl, i) => (
                          <li key={i} className="flex items-center gap-1.5">
                            <Check className="w-3.5 h-3.5 text-secondary shrink-0" />
                            <span className="line-clamp-1">{hl}</span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    {/* Price & CTA */}
                    <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between gap-2">
                      <div>
                        <span className="text-[9px] text-slate-400 block font-bold uppercase">السعر التقديري</span>
                        <span className="text-secondary font-black text-sm block">{priceLabel}</span>
                      </div>
                      <span 
                        className="text-xs font-bold text-primary group-hover:text-secondary flex items-center gap-1 transition-colors"
                      >
                        <span>التفاصيل</span>
                        <ChevronLeft className="w-3.5 h-3.5 transform group-hover:-translate-x-0.5 transition-transform" />
                      </span>
                    </div>
                  </div>
                </Link>
              );
            })
          )}
        </div>
      </div>
    </section>
  );
}
