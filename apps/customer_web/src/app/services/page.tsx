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
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");

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
          .from("active_services_tree")
          .select("*")
          .eq("id", serviceId)
          .single();

        if (parentError) throw parentError;
        setParentService(parentData);

        // 2. Fetch sub services
        const { data: subData, error: subError } = await supabase
          .from("active_services_tree")
          .select("*")
          .eq("parent_id", serviceId)
          .order("sort_order", { ascending: true });

        if (subError) throw subError;
        setSubServices(subData || []);

        // 3. Fetch whatsapp number
        const { data: wsData } = await supabase
          .from("system_settings")
          .select("value")
          .eq("key", "whatsapp_settings")
          .single();
        if (wsData?.value?.business_number) {
          setWhatsappNumber(wsData.value.business_number);
        }
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
              href={parentService?.parent_id ? `/services?serviceId=${parentService.parent_id}` : "/"} 
              className="flex items-center gap-2 text-slate-500 hover:text-primary transition-colors text-xs font-bold"
            >
              <ArrowRight className="w-4 h-4" />
              <span>{parentService?.parent_id ? "العودة للقسم السابق" : "العودة للرئيسية"}</span>
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
              // Skeletons with updated spacing
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div key={i} className="bg-white rounded-3xl border border-slate-100/80 p-6 space-y-5 animate-pulse">
                    <div className="flex justify-between items-center">
                      <div className="w-14 h-14 bg-slate-100 rounded-2xl"></div>
                      <div className="w-16 h-6 bg-slate-100 rounded-lg"></div>
                    </div>
                    <div className="space-y-3">
                      <div className="w-1/2 h-5 bg-slate-200 rounded"></div>
                      <div className="w-full h-3.5 bg-slate-100 rounded"></div>
                      <div className="w-5/6 h-3.5 bg-slate-100 rounded"></div>
                    </div>
                    <div className="pt-5 border-t border-slate-50 flex justify-between items-center">
                      <div className="w-20 h-8 bg-slate-100 rounded-xl"></div>
                      <div className="w-24 h-9 bg-slate-150 rounded-xl"></div>
                    </div>
                  </div>
                ))}
              </div>
            ) : subServices.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
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
                      onClick={() => router.push(sub.is_bookable ? `/services/details?serviceId=${serviceId}&subServiceId=${sub.id}` : `/services?serviceId=${sub.id}`)}
                      className="bg-white rounded-3xl border border-slate-100/80 hover:border-primary/10 p-6 shadow-[0_10px_30px_rgba(0,0,0,0.02)] hover:shadow-xl hover:shadow-primary/5 transition-all duration-300 flex flex-col justify-between group cursor-pointer text-right transform hover:-translate-y-1"
                    >
                      <div>
                        {/* Top Row: Icon & Rating */}
                        <div className="flex justify-between items-center mb-5">
                          <div className="w-14 h-14 rounded-2xl bg-primary/5 border border-primary/10 flex items-center justify-center p-2.5 group-hover:scale-105 transition-transform duration-300">
                            {sub.image ? (
                              <img 
                                src={sub.image} 
                                alt={arTitle} 
                                className="w-full h-full object-contain"
                              />
                            ) : (
                              <Sparkles className="w-6 h-6 text-primary/45" />
                            )}
                          </div>
                          <div className="flex items-center gap-1 text-amber-500 text-xs font-black bg-amber-50 px-2.5 py-1 rounded-lg border border-amber-100/40">
                            <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                            <span>{rating}</span>
                            <span className="text-slate-400 font-normal">({reviews})</span>
                          </div>
                        </div>
                        
                        {/* Info with high contrast colors */}
                        <div className="space-y-3">
                          <h3 className="font-extrabold text-slate-900 text-base group-hover:text-primary transition-colors line-clamp-1">
                            {arTitle}
                          </h3>
                          <p className="text-slate-600 text-xs leading-relaxed line-clamp-3 font-normal min-h-[54px]">
                            {arDesc}
                          </p>
                        </div>
                      </div>

                      {/* Bottom Row: Price & Solid Premium CTA Button */}
                      <div className="mt-6 pt-4 border-t border-slate-100/60 flex items-center justify-between gap-3">
                        {sub.is_bookable ? (
                          <>
                            <div>
                              <span className="text-[10px] text-slate-500 block font-bold">السعر التقديري</span>
                              <span className="text-secondary font-black text-xs sm:text-sm block">{priceText}</span>
                            </div>
                            <span className="bg-primary hover:bg-secondary text-white hover:text-slate-900 text-xs font-extrabold px-4 py-2 rounded-xl transition-all duration-300 flex items-center gap-1 shadow-sm hover:shadow-md">
                              <span>احجز الآن</span>
                              <ChevronLeft className="w-3.5 h-3.5 transition-transform group-hover:-translate-x-0.5" />
                            </span>
                          </>
                        ) : (
                          <>
                            <div>
                              <span className="text-[10px] text-slate-500 block font-bold">نوع الخدمة</span>
                              <span className="text-slate-600 font-bold text-xs sm:text-sm block">قسم رئيسي</span>
                            </div>
                            <span className="bg-slate-100 hover:bg-primary hover:text-white text-slate-700 text-xs font-extrabold px-4 py-2 rounded-xl transition-all duration-300 flex items-center gap-1 shadow-sm hover:shadow-md">
                              <span>تصفح الأقسام</span>
                              <ChevronLeft className="w-3.5 h-3.5 transition-transform group-hover:-translate-x-0.5" />
                            </span>
                          </>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-16 px-6 bg-gradient-to-br from-white to-slate-50 rounded-3xl border border-slate-100/80 shadow-md text-right max-w-2xl mx-auto space-y-6">
                <div className="w-20 h-20 rounded-2xl bg-secondary/10 flex items-center justify-center mx-auto mb-6 border border-secondary/20">
                  <Sparkles className="w-10 h-10 text-secondary" />
                </div>
                <h3 className="text-xl sm:text-2xl font-black text-slate-900 text-center">ستتوفر هذه الخدمة قريباً!</h3>
                <p className="text-slate-600 text-sm leading-relaxed text-center font-normal max-w-md mx-auto">
                  نحن نعمل حالياً على استقطاب وتأهيل أفضل الفنيين المحترفين لتقديم هذه الخدمة لك بأعلى مستويات الجودة والأمان التي عهدتها من فريش هوم.
                </p>
                <div className="pt-4 border-t border-slate-200/60 flex flex-col sm:flex-row items-center justify-center gap-4">
                  <Link
                    href="/"
                    className="w-full sm:w-auto bg-primary hover:bg-slate-900 text-white text-xs font-black px-6 py-3.5 rounded-xl transition-all duration-300 shadow-sm hover:shadow-md text-center"
                  >
                    استكشف الأقسام الأخرى المتاحة
                  </Link>
                  <a
                    href={`https://wa.me/${whatsappNumber}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full sm:w-auto bg-emerald-50 hover:bg-emerald-100 text-emerald-700 hover:text-emerald-800 border border-emerald-200 text-xs font-black px-6 py-3.5 rounded-xl transition-all duration-300 text-center flex items-center justify-center gap-2"
                  >
                    أرسل لنا طلب اهتمام عبر واتساب
                  </a>
                </div>
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
