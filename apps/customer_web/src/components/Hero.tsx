"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { ShieldCheck, Sparkles, Check, ChevronLeft, ArrowRight, Search, X, Wrench, KeyRound, Home, Bug, Shield } from "lucide-react";
import { supabase } from "@/lib/supabase";

const FLOATING_ITEMS = [
  { Icon: Sparkles, top: "10%", duration: "25s", delay: "0s", scale: 0.6, opacity: 0.12 },
  { Icon: Wrench, top: "25%", duration: "35s", delay: "-5s", scale: 0.8, opacity: 0.18 },
  { Icon: KeyRound, top: "45%", duration: "40s", delay: "-12s", scale: 0.5, opacity: 0.15 },
  { Icon: Home, top: "60%", duration: "30s", delay: "-8s", scale: 0.7, opacity: 0.14 },
  { Icon: Bug, top: "75%", duration: "28s", delay: "-15s", scale: 0.9, opacity: 0.20 },
  { Icon: Shield, top: "15%", duration: "32s", delay: "-3s", scale: 0.75, opacity: 0.16 },
  { Icon: Sparkles, top: "50%", duration: "22s", delay: "-18s", scale: 0.85, opacity: 0.22 },
  { Icon: Wrench, top: "80%", duration: "38s", delay: "-10s", scale: 0.55, opacity: 0.13 },
];

export default function Hero() {
  const [sliders, setSliders] = useState<any[]>([]);
  const [currentSlide, setCurrentSlide] = useState(0);
  const [loading, setLoading] = useState(true);
  const [services, setServices] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    async function fetchAllServices() {
      try {
        const { data, error } = await supabase
          .from("services")
          .select("id, title, description, parent_id, status, is_bookable")
          .eq("status", "active");
        if (error) throw error;
        setServices(data || []);
      } catch (e) {
        console.error("Error fetching all services for search:", e);
      }
    }
    fetchAllServices();
  }, []);

  const mainServicesLookup = services.reduce((acc: Record<string, any>, item) => {
    if (!item.parent_id) {
      acc[item.id] = item;
    }
    return acc;
  }, {});

  const cleanQuery = searchQuery.trim().toLowerCase();
  const searchResults = cleanQuery
    ? services.filter((s) => {
        const titleAr = (s.title?.ar || s.title || "").toLowerCase();
        const descAr = (s.description?.ar || s.description || "").toLowerCase();
        const titleEn = (s.title?.en || s.title || "").toLowerCase();
        const descEn = (s.description?.en || s.description || "").toLowerCase();
        return (
          titleAr.includes(cleanQuery) ||
          descAr.includes(cleanQuery) ||
          titleEn.includes(cleanQuery) ||
          descEn.includes(cleanQuery)
        );
      })
    : [];

  useEffect(() => {
    async function fetchSliders() {
      try {
        const { data, error } = await supabase
          .from("home_content")
          .select("sliders")
          .eq("type", "sliders")
          .single();

        if (error) throw error;
        if (data && data.sliders) {
          const sorted = [...data.sliders].sort((a: any, b: any) => (a.order || 0) - (b.order || 0));
          setSliders(sorted);
        }
      } catch (e) {
        console.error("Error fetching sliders:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchSliders();
  }, []);

  // Auto-play interval
  useEffect(() => {
    if (sliders.length <= 1) return;
    const interval = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % sliders.length);
    }, 4500);
    return () => clearInterval(interval);
  }, [sliders]);

  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-primary via-primary/95 to-slate-900 text-white py-20 lg:py-28">
      {isFocused && (
        <div 
          className="fixed inset-0 z-20 cursor-default" 
          onClick={() => setIsFocused(false)}
        />
      )}
      {/* Background decoration elements */}
      <div className="absolute top-0 right-0 w-96 h-96 rounded-full bg-secondary/10 blur-3xl -mr-20 -mt-20"></div>
      <div className="absolute bottom-0 left-0 w-96 h-96 rounded-full bg-blue-500/10 blur-3xl -ml-20 -mb-20"></div>

      {/* Animated Floating Background Icons (Drifting from Right to Left) */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
        <style dangerouslySetInnerHTML={{__html: `
          @keyframes floatLeft {
            0% {
              transform: translateX(0) rotate(0deg);
            }
            100% {
              transform: translateX(-120vw) rotate(-360deg);
            }
          }
          .floating-icon-item {
            position: absolute;
            animation: floatLeft linear infinite;
            will-change: transform;
          }
        `}} />
        
        {FLOATING_ITEMS.map((item, idx) => {
          const ItemIcon = item.Icon;
          return (
            <div
              key={idx}
              className="floating-icon-item"
              style={{
                top: item.top,
                left: "100%",
                animationDuration: item.duration,
                animationDelay: item.delay,
                opacity: item.opacity,
                transform: `scale(${item.scale})`,
              }}
            >
              <ItemIcon className="w-12 h-12 text-[#B3E5FC]" />
            </div>
          );
        })}
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-20">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Main Info */}
          <div className="lg:col-span-7 space-y-6 text-center lg:text-right">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/10 backdrop-blur-md border border-white/10 text-xs font-bold text-secondary">
              <Sparkles className="w-3.5 h-3.5" />
              <span>خدمات صيانة وتنظيف منزلية بضمان الجودة في مصر</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black leading-tight sm:leading-tight lg:leading-none tracking-tight">
              منزلك في أيدٍ أمينة مع محترفي <span className="text-secondary">فريش هوم</span>
            </h1>
            
            <p className="text-base sm:text-lg text-slate-100 max-w-xl mx-auto lg:mx-0 leading-relaxed font-normal font-sans">
              احجز خدمات التنظيف العميق، مكافحة الآفات، وصيانة التكييفات والسباكة في دقائق معدودة. احصل على تسعير فوري ودقيق دون مفاجآت وبدون اشتراط تسجيل الدخول المسبق.
            </p>

            {/* Search Bar */}
            <div className="relative max-w-xl mx-auto lg:mx-0 z-30">
              <div className="relative flex items-center bg-white/10 backdrop-blur-md rounded-2xl border border-white/20 shadow-lg transition-all focus-within:border-secondary focus-within:bg-white/15 focus-within:ring-2 focus-within:ring-secondary/20">
                <Search className="absolute right-4 w-5 h-5 text-slate-400" />
                <input
                  type="text"
                  placeholder="ما هي الخدمة التي تبحث عنها اليوم؟ (تنظيف، تكييف، سباكة...)"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onFocus={() => setIsFocused(true)}
                  className="w-full bg-transparent text-white placeholder-slate-400 text-xs font-bold py-4 pr-12 pl-4 rounded-2xl outline-none border-none text-right font-sans focus:ring-0"
                />
                {searchQuery && (
                  <button
                    onClick={() => setSearchQuery("")}
                    className="absolute left-4 p-1 hover:bg-white/10 rounded-full transition-colors text-slate-300 hover:text-white"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>

              {/* Search Results Dropdown */}
              {isFocused && searchQuery && (
                <div className="absolute top-full mt-2 w-full bg-white rounded-2xl border border-slate-100 shadow-[0_10px_40px_rgba(0,0,0,0.12)] overflow-hidden text-right z-40 text-slate-800">
                  {searchResults.length > 0 ? (
                    <div className="py-2">
                      <div className="px-4 py-2 border-b border-slate-50 text-[10px] font-black text-slate-400">
                        نتائج البحث ({searchResults.length})
                      </div>
                      <div className="max-h-[260px] overflow-y-auto divide-y divide-slate-50">
                        {searchResults.map((serve) => {
                          const isSubService = !!serve.parent_id;
                          const arTitle = serve.title?.ar || serve.title;
                          const arDesc = serve.description?.ar || serve.description;
                          
                          // Parent category info
                          const parentName = isSubService && mainServicesLookup[serve.parent_id]
                            ? (mainServicesLookup[serve.parent_id].title?.ar || mainServicesLookup[serve.parent_id].title)
                            : null;

                          const href = isSubService
                            ? `/services/details?serviceId=${serve.parent_id}&subServiceId=${serve.id}`
                            : `/services?serviceId=${serve.id}`;

                          return (
                            <Link
                              key={serve.id}
                              href={href}
                              onClick={() => {
                                setIsFocused(false);
                                setSearchQuery("");
                              }}
                              className="block px-4 py-3 hover:bg-primary/5 transition-colors group"
                            >
                              <div className="flex items-center justify-between gap-3">
                                <div className="flex-1">
                                  <div className="flex items-center gap-2">
                                    <span className="font-extrabold text-xs text-slate-800 group-hover:text-primary transition-colors">
                                      {arTitle}
                                    </span>
                                    {parentName && (
                                      <span className="text-[9px] font-black text-secondary bg-secondary/10 px-2 py-0.5 rounded-full">
                                        قسم {parentName}
                                      </span>
                                    )}
                                    {!isSubService && (
                                      <span className="text-[9px] font-black text-primary bg-primary/10 px-2 py-0.5 rounded-full">
                                        قسم رئيسي
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-[10px] text-slate-400 mt-1 font-light line-clamp-1 leading-normal font-sans">
                                    {arDesc}
                                  </p>
                                </div>
                                <ChevronLeft className="w-4 h-4 text-slate-350 group-hover:text-primary transition-transform transform group-hover:-translate-x-1" />
                              </div>
                            </Link>
                          );
                        })}
                      </div>
                    </div>
                  ) : (
                    <div className="px-4 py-8 text-center text-slate-400 text-xs font-medium">
                      عذراً، لم نجد خدمة بهذا الاسم. حاول البحث بكلمات أخرى.
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start pt-2">
              <Link 
                href="/booking" 
                data-track="hero-primary-booking"
                className="flex items-center justify-center gap-2 bg-gradient-to-r from-secondary to-[#2ecc71] hover:opacity-95 text-slate-900 font-extrabold px-8 py-3.5 rounded-xl transition-all shadow-lg shadow-secondary/20 transform hover:-translate-y-0.5"
              >
                <span>احجز خدمتك فوراً</span>
                <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
              </Link>
              <Link 
                href="#services" 
                data-track="hero-secondary-browse"
                className="flex items-center justify-center gap-2 bg-white/10 hover:bg-white/15 text-white font-bold px-8 py-3.5 rounded-xl transition-all border border-white/10"
              >
                <span>عرض كل الخدمات</span>
              </Link>
            </div>

            {/* Key Trust Factors */}
            <div className="grid grid-cols-3 gap-4 pt-8 border-t border-white/10 max-w-md mx-auto lg:mx-0">
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">100%</span>
                <span className="text-xs text-slate-300">أمان وموثوقية</span>
              </div>
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">30 يوم</span>
                <span className="text-xs text-slate-300">ضمان على الصيانة</span>
              </div>
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">فوري</span>
                <span className="text-xs text-slate-300">تسعير ديناميكي</span>
              </div>
            </div>
          </div>

          {/* Graphical showcase (Visual Trust / Slider Element) */}
          <div className="lg:col-span-5 flex justify-center w-full">
            <div className="relative w-full max-w-md aspect-[4/5] rounded-[32px] bg-slate-800/80 border border-slate-700/50 p-4 shadow-2xl overflow-hidden flex flex-col justify-between">
              {loading ? (
                <div className="w-full h-full bg-slate-700/50 animate-pulse rounded-2xl flex items-center justify-center">
                  <span className="text-xs text-slate-400">جاري تحميل العروض...</span>
                </div>
              ) : sliders.length > 0 ? (
                <div className="relative w-full h-full rounded-2xl overflow-hidden group">
                  {/* Slides */}
                  {sliders.map((slide, idx) => (
                    <div
                      key={idx}
                      className={`absolute inset-0 transition-all duration-700 ease-in-out ${
                        idx === currentSlide ? "opacity-100 scale-100" : "opacity-0 scale-95 pointer-events-none"
                      }`}
                    >
                      {slide.serviceId ? (
                        <Link href={`/services?serviceId=${slide.serviceId}`}>
                          <img
                            src={slide.image}
                            alt={`عرض ${idx + 1}`}
                            className="w-full h-full object-cover rounded-2xl cursor-pointer hover:scale-102 transition-transform duration-500"
                          />
                        </Link>
                      ) : (
                        <img
                          src={slide.image}
                          alt={`عرض ${idx + 1}`}
                          className="w-full h-full object-cover rounded-2xl"
                        />
                      )}
                    </div>
                  ))}

                  {/* Dots Navigation */}
                  {sliders.length > 1 && (
                    <div className="absolute bottom-4 left-0 right-0 flex justify-center gap-2 z-10 bg-slate-900/40 py-2 backdrop-blur-xs max-w-max mx-auto rounded-full px-4 border border-white/5">
                      {sliders.map((_, idx) => (
                        <button
                          key={idx}
                          onClick={() => setCurrentSlide(idx)}
                          className={`h-2 rounded-full transition-all duration-300 ${
                            idx === currentSlide ? "w-6 bg-secondary" : "w-2 bg-white/50 hover:bg-white"
                          }`}
                        />
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                /* Fallback layout: original Trust Guarantee card */
                <div className="h-full flex flex-col justify-between">
                  <div className="absolute top-0 right-0 w-24 h-24 bg-primary/20 rounded-full blur-2xl"></div>
                  
                  {/* Fake app card header */}
                  <div className="flex justify-between items-center border-b border-slate-700/50 pb-4">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-secondary/20 flex items-center justify-center text-secondary">
                        <ShieldCheck className="w-5 h-5" />
                      </div>
                      <div>
                        <span className="text-xs font-bold block text-white">فريش هوم جارانتي</span>
                        <span className="text-[8px] text-slate-400 block -mt-0.5">Fresh Home Guarantee</span>
                      </div>
                    </div>
                    <span className="bg-emerald-500/20 text-emerald-400 text-[9px] font-bold px-2 py-0.5 rounded-full">نشط</span>
                  </div>

                  {/* Trust list items */}
                  <div className="space-y-4 my-8">
                    <div className="flex items-start gap-3">
                      <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                      <p className="text-xs text-slate-300 leading-relaxed font-sans">
                        <strong>فحص الحالة الجنائية:</strong> جميع الفنيين يخضعون للتحريات والفيش والتشبيه الفعلي.
                      </p>
                    </div>
                    <div className="flex items-start gap-3">
                      <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                      <p className="text-xs text-slate-300 leading-relaxed font-sans">
                        <strong>تدريب عملي صارم:</strong> فنيونا مؤهلون وحاصلون على تقييمات نجاح تتعدى 4.8★.
                      </p>
                    </div>
                    <div className="flex items-start gap-3">
                      <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                      <p className="text-xs text-slate-300 leading-relaxed font-sans">
                        <strong>التأمين ضد الأضرار:</strong> المنصة مأمنة بالكامل لحماية منزلك ومقتنياتك.
                      </p>
                    </div>
                  </div>

                  {/* Fake app card footer */}
                  <div className="bg-slate-750 border border-slate-700/60 rounded-xl p-3.5 flex items-center justify-between text-xs">
                    <div>
                      <span className="text-slate-400 block text-[9px]">متوسط الأسعار يبدأ من</span>
                      <span className="text-white font-extrabold text-sm block">150 ج.م</span>
                    </div>
                    <Link 
                      href="/booking" 
                      className="bg-gradient-to-r from-primary to-[#22A5FC] hover:opacity-95 text-white font-bold px-3 py-2 rounded-lg text-[10px] flex items-center gap-1"
                    >
                      <span>اطلب الآن</span>
                      <ArrowRight className="w-3.5 h-3.5 rotate-180" />
                    </Link>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
