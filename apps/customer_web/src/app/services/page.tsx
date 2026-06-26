"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowRight, ChevronLeft, Sparkles, Star } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";

function ServicesListContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const serviceId = searchParams.get("serviceId");

  const [subServices, setSubServices] = useState<any[]>([]);
  const [parentService, setParentService] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!serviceId) {
      router.push("/");
      return;
    }

    async function fetchData() {
      setLoading(true);
      try {
        // 1. Fetch parent service details
        const { data: parentData, error: parentError } = await supabase
          .from("services")
          .select("*")
          .eq("id", serviceId)
          .single();

        if (parentError) throw parentError;
        setParentService(parentData);

        // 2. Fetch sub services
        const { data: subData, error: subError } = await supabase
          .from("services")
          .select("*")
          .eq("parent_id", serviceId)
          .eq("is_bookable", true)
          .eq("status", "active")
          .order("sort_order", { ascending: true });

        if (subError) throw subError;
        setSubServices(subData || []);
      } catch (e) {
        console.error("Error fetching services:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, [serviceId, router]);

  const parentTitle = parentService?.title?.ar || parentService?.title || "الخدمات المنزلية";
  const parentDesc = parentService?.description?.ar || parentService?.description || "تصفح باقة خدماتنا المنزلية المميزة.";

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <Header />

      <main className="flex-1 py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Back button & title */}
          <div className="mb-8 flex items-center justify-between">
            <Link 
              href="/" 
              className="flex items-center gap-2 text-slate-500 hover:text-primary transition-colors text-xs font-bold"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة للرئيسية</span>
            </Link>
            {parentService && (
              <span className="text-[10px] bg-primary/10 text-primary font-black px-3 py-1 rounded-full">
                قسم: {parentTitle}
              </span>
            )}
          </div>

          {/* Banner */}
          <div className="bg-gradient-to-br from-primary via-primary/95 to-slate-900 text-white rounded-3xl p-8 relative overflow-hidden shadow-xl mb-10 text-right">
            <div className="absolute top-0 left-0 w-64 h-64 rounded-full bg-secondary/5 blur-3xl -ml-20 -mt-20"></div>
            <div className="relative z-10 space-y-3">
              <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
                خدمات {parentTitle}
              </h1>
              <p className="text-slate-200 text-sm leading-relaxed max-w-xl font-light">
                {parentDesc}
              </p>
            </div>
          </div>

          {/* Sub Services List */}
          <div className="space-y-6">
            <div className="flex items-center gap-3 border-b border-slate-200/60 pb-3 mb-6">
              <h2 className="text-lg font-black text-slate-800">الخدمات المتوفرة حالياً في هذا القسم</h2>
              <div className="w-2.5 h-2.5 rounded-full bg-secondary"></div>
            </div>

            {loading ? (
              // Skeletons
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div key={i} className="bg-white rounded-[22px] border border-slate-100 shadow-sm p-5 space-y-6 animate-pulse">
                    <div className="w-full h-[150px] bg-slate-100 rounded-2xl"></div>
                    <div className="space-y-3">
                      <div className="w-2/3 h-5 bg-slate-200 rounded"></div>
                      <div className="w-full h-4 bg-slate-200 rounded"></div>
                      <div className="w-5/6 h-4 bg-slate-200 rounded"></div>
                    </div>
                    <div className="pt-4 border-t border-slate-100 flex justify-between">
                      <div className="w-16 h-8 bg-slate-200 rounded"></div>
                      <div className="w-20 h-8 bg-slate-200 rounded"></div>
                    </div>
                  </div>
                ))}
              </div>
            ) : subServices.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {subServices.map((sub) => {
                  const arTitle = sub.title?.ar || sub.title;
                  const arDesc = sub.description?.ar || sub.description;
                  
                  // Deterministic reviews info
                  const charSum = sub.id.split("").reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0);
                  const rating = (4.5 + (charSum % 5) / 10).toFixed(1);
                  const reviews = 50 + (charSum % 100);

                  // Base Price text
                  let priceText = "حسب الطلب";
                  if (sub.price_config?.min_price || sub.min_price) {
                    priceText = `تبدأ من ${sub.price_config?.min_price || sub.min_price} ج.م`;
                  } else if (sub.price_config?.value) {
                    priceText = `تبدأ من ${sub.price_config.value} ج.م`;
                  }

                  return (
                    <div 
                      key={sub.id}
                      onClick={() => router.push(`/services/details?serviceId=${serviceId}&subServiceId=${sub.id}`)}
                      className="bg-white rounded-[22px] border border-slate-100 shadow-[0_8px_40px_rgba(0,0,0,0.05)] hover:shadow-lg transition-all duration-300 flex flex-col justify-between group overflow-hidden transform hover:-translate-y-1 cursor-pointer text-right"
                    >
                      {/* Top Image Container */}
                      <div className="relative h-[150px] w-full bg-slate-50 border-b border-slate-100 flex items-center justify-center p-4">
                        {sub.image ? (
                          <img 
                            src={sub.image} 
                            alt={arTitle} 
                            className="w-20 h-20 object-contain transition-transform duration-300 group-hover:scale-105"
                          />
                        ) : (
                          <Sparkles className="w-10 h-10 text-primary/40" />
                        )}
                        
                        {/* Rating Overlay */}
                        <div className="absolute top-3 left-3 bg-white/95 text-amber-500 font-black px-2 py-0.5 rounded-lg text-[10px] flex items-center gap-1 shadow-xs border border-slate-100">
                          <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                          <span>{rating}</span>
                          <span className="text-slate-400 font-normal">({reviews})</span>
                        </div>
                      </div>

                      {/* Card Body */}
                      <div className="p-5 flex-1 flex flex-col justify-between space-y-4">
                        <div className="space-y-2">
                          <h3 className="font-extrabold text-slate-800 text-sm sm:text-base leading-snug group-hover:text-primary transition-colors min-h-[44px] line-clamp-2">
                            {arTitle}
                          </h3>
                          <p className="text-slate-500 text-xs leading-relaxed line-clamp-3 font-light">
                            {arDesc}
                          </p>
                        </div>

                        {/* Bottom Info & CTA */}
                        <div className="pt-4 border-t border-slate-100 flex items-center justify-between gap-2">
                          <div>
                            <span className="text-[9px] text-slate-400 block font-bold uppercase">السعر التقديري</span>
                            <span className="text-secondary font-black text-xs sm:text-sm block">{priceText}</span>
                          </div>
                          <span className="text-xs font-bold text-primary group-hover:text-secondary flex items-center gap-1 transition-colors">
                            <span>احجز الآن</span>
                            <ChevronLeft className="w-3.5 h-3.5 transform group-hover:-translate-x-0.5 transition-transform" />
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-16 bg-white rounded-3xl border border-slate-100 shadow-sm text-slate-400 text-sm">
                عذراً، لا توجد خدمات فرعية متاحة حالياً في هذا القسم.
              </div>
            )}
          </div>

        </div>
      </main>

      <Footer />
    </div>
  );
}

export default function ServicesListPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
      </div>
    }>
      <ServicesListContent />
    </Suspense>
  );
}
