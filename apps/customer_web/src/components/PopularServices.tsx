"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { Star, Check, Sparkles } from "lucide-react";
import { supabase } from "@/lib/supabase";

export default function PopularServices() {
  const [popularServices, setPopularServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchPopularServices() {
      try {
        const { data, error } = await supabase
          .from("services")
          .select("*")
          .eq("is_bookable", true)
          .eq("status", "active")
          .limit(4);

        if (error) throw error;
        setPopularServices(data || []);
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
            <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">خدماتنا الشائعة والمطلوبة</h2>
            <p className="text-slate-500 text-sm max-w-lg">
              الخدمات المفضلة لعملائنا في مصر. اطلب خدماتك الآن كضيف واستمتع بخصم فوري وتعيين أسرع للفنيين.
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
              // Deterministic fake ratings and reviews based on ID
              const charSum = sub.id.split("").reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0);
              const rating = (4.5 + (charSum % 5) / 10).toFixed(1);
              const reviews = 50 + (charSum % 100);

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
              let highlights = ["جودة وضمان معتمد", "أمان تام للعائلة", "تجهيز فني متكامل"];
              if (sub.details && Array.isArray(sub.details) && sub.details.length > 0) {
                highlights = sub.details.slice(0, 3).map((d: any) => typeof d === "string" ? d : d.ar || d.title || JSON.stringify(d));
              } else if (sub.price_config?.fields && sub.price_config.fields.length > 0) {
                highlights = sub.price_config.fields.slice(0, 3).map((f: any) => f.label?.ar || f.label);
              }

              const arTitle = sub.title?.ar || sub.title;

              return (
                <div 
                  key={sub.id}
                  className="bg-slate-50 rounded-2xl p-5 border border-slate-100 flex flex-col justify-between hover:bg-white hover:border-slate-200 transition-all duration-300 hover:shadow-lg hover:shadow-slate-100 group"
                >
                  <div className="space-y-4">
                    {/* Badge & Rating */}
                    <div className="flex justify-between items-center text-xs">
                      <span className="bg-primary/5 text-primary font-black px-2 py-0.5 rounded-md text-[10px]">
                        {badge}
                      </span>
                      <div className="flex items-center gap-1 text-amber-500 font-bold">
                        <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                        <span>{rating}</span>
                        <span className="text-slate-400 font-normal">({reviews})</span>
                      </div>
                    </div>

                    {/* Title */}
                    <h3 className="font-extrabold text-slate-800 text-sm leading-snug group-hover:text-primary transition-colors min-h-[40px] line-clamp-2">
                      {arTitle}
                    </h3>

                    {/* Highlights */}
                    <ul className="space-y-1.5 text-xs text-slate-500 border-t border-slate-200/60 pt-3">
                      {highlights.map((hl, i) => (
                        <li key={i} className="flex items-center gap-1.5">
                          <Check className="w-3 h-3 text-secondary shrink-0" />
                          <span className="line-clamp-1">{hl}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Price & CTA */}
                  <div className="mt-6 pt-4 border-t border-slate-200/60 flex items-center justify-between gap-2">
                    <div>
                      <span className="text-[10px] text-slate-400 block font-bold uppercase">السعر التقديري</span>
                      <span className="text-primary font-black text-sm block">{priceLabel}</span>
                    </div>
                    <Link 
                      href={`/booking?serviceId=${sub.parent_id}&subServiceId=${sub.id}`}
                      className="bg-primary hover:bg-primary/95 text-white font-bold px-4 py-2 rounded-xl text-xs shadow-md shadow-primary/10"
                    >
                      <span>احجز كضيف</span>
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
