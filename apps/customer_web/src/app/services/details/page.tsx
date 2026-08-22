"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { 
  ArrowRight, Calendar, Check, X, Star, 
  Sparkles, ShieldCheck, Heart, User, ChevronLeft
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";

function resolveServiceImage(imageStr?: string | null): string | null {
  if (!imageStr || typeof imageStr !== "string") return null;
  const clean = imageStr.trim();
  if (!clean) return null;
  if (clean.startsWith("http://") || clean.startsWith("https://") || clean.startsWith("/")) {
    return clean;
  }
  const { data } = supabase.storage.from("service_images").getPublicUrl(clean);
  return data?.publicUrl || null;
}

const parseDetailItem = (item: any, isArabic: boolean = true) => {
  if (!item) return null;
  
  if (typeof item === "string") {
    return { title: item, points: [], icon: null };
  }

  // 1. Check if it has multilingual subkeys 'ar' or 'en'
  if (item.ar || item.en) {
    const langContent = isArabic ? (item.ar || item.en) : (item.en || item.ar);
    if (langContent) {
      if (typeof langContent === "string") {
        return { title: langContent, points: [], icon: null };
      }
      return {
        title: typeof langContent.title === "object" 
          ? (isArabic ? langContent.title.ar : langContent.title.en) 
          : langContent.title || "",
        points: Array.isArray(langContent.points) ? langContent.points : [],
        icon: langContent.icon || null
      };
    }
  }

  // Helper to extract text from a field that could be string or object
  const getMultilingualText = (field: any) => {
    if (!field) return "";
    if (typeof field === "string") return field;
    if (typeof field === "object") {
      return isArabic ? (field.ar || field.en || "") : (field.en || field.ar || "");
    }
    return String(field);
  };

  const title = getMultilingualText(item.title);
  
  let points: string[] = [];
  if (Array.isArray(item.points)) {
    points = item.points.map((p: any) => getMultilingualText(p));
  }

  return {
    title,
    points,
    icon: item.icon || null
  };
};

function ServiceDetailsContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const serviceId = searchParams.get("serviceId");
  const subServiceId = searchParams.get("subServiceId");

  const [service, setService] = useState<any>(null);
  const [reviews, setReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFavorite, setIsFavorite] = useState(false);
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");

  useEffect(() => {
    if (!subServiceId || !serviceId) {
      router.push("/");
      return;
    }

    // Check favorite status from localStorage
    const favorites = JSON.parse(localStorage.getItem("favorites") || "[]");
    setIsFavorite(favorites.includes(subServiceId));

    async function fetchData() {
      setLoading(true);
      try {
        // 1. Fetch subservice details
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("*")
          .eq("id", subServiceId)
          .single();

        if (error) throw error;
        setService({
          ...data,
          imageUrl: resolveServiceImage(data.image),
        });

        // 2. Fetch reviews from unified details view
        const { data: reviewsData, error: reviewsError } = await supabase
          .from("view_reviews_with_details")
          .select("*")
          .eq("service_id", subServiceId)
          .eq("status", "published")
          .order("created_at", { ascending: false });

        if (!reviewsError) {
          setReviews(reviewsData || []);
        }

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
        console.error("Error fetching details:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, [serviceId, subServiceId, router]);

  const toggleFavorite = () => {
    if (!subServiceId) return;
    const favorites = JSON.parse(localStorage.getItem("favorites") || "[]");
    let newFavorites = [];
    if (favorites.includes(subServiceId)) {
      newFavorites = favorites.filter((id: string) => id !== subServiceId);
      setIsFavorite(false);
    } else {
      newFavorites = [...favorites, subServiceId];
      setIsFavorite(true);
    }
    localStorage.setItem("favorites", JSON.stringify(newFavorites));
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex items-center justify-center py-20">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
        </main>
        <Footer />
      </div>
    );
  }

  if (!service) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex flex-col items-center justify-center py-20 text-slate-500 text-center">
          <p className="text-sm font-bold">عذراً، لم نتمكن من العثور على الخدمة المطلوبة.</p>
          <Link href="/" className="mt-4 px-6 py-2 rounded-xl bg-[#0091FF] text-white text-xs font-black shadow-md">
            العودة للرئيسية
          </Link>
        </main>
        <Footer />
      </div>
    );
  }

  const isUnavailable = service.status !== "active" && service.status !== "ready";
  
  if (isUnavailable) {
    return (
      <div className="min-h-screen bg-[#071739] text-white flex flex-col font-sans justify-between">
        <Header />
        <main className="flex-1 flex items-center justify-center p-6">
          <div className="bg-[#0D2A68]/80 border border-blue-800/60 rounded-3xl max-w-md w-full p-8 text-center space-y-5 shadow-2xl">
            <div className="w-16 h-16 bg-[#0091FF]/20 rounded-2xl flex items-center justify-center mx-auto text-[#22A5FC]">
              <Sparkles className="w-8 h-8" />
            </div>
            <h2 className="text-xl font-black text-white">الخدمة ستتوفر قريباً</h2>
            <p className="text-slate-300 text-xs leading-relaxed">
              نعمل حالياً على تجهيز هذه الخدمة بأعلى معايير الجودة لتكون متاحة لحجزك قريباً.
            </p>
            <button 
              onClick={() => router.back()}
              className="w-full bg-[#0091FF] hover:bg-[#0077E6] text-white font-black py-3.5 px-6 rounded-xl shadow-lg transition-all text-xs"
            >
              العودة للخلف
            </button>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  const isPaused = service.status === "paused";
  const arTitle = service.title?.ar || service.title || "تفاصيل الخدمة";
  const arDesc = service.description?.ar || service.description || "";

  // Pricing details formatting
  let startingPrice = 250;
  let priceLabel = "السعر الأساسي التقديري";
  let unitText = "ج.م";

  const priceConfig = service.price_config || {};
  const type = priceConfig.type;
  const value = priceConfig.value || priceConfig.min_price || service.min_price || 0;

  if (value > 0) startingPrice = value;

  if (type === "fixed") {
    priceLabel = "السعر الأساسي الثابت";
  } else if (type === "per_square_meter") {
    priceLabel = "سعر المتر المربع";
    unitText = "ج.م / م²";
  } else if (type === "per_linear_meter") {
    priceLabel = "سعر المتر الطولي";
    unitText = "ج.م / م";
  } else if (type === "inspection") {
    priceLabel = "رسوم المعاينة الميدانية";
  }

  // Parse inclusions / details
  const inclusions = Array.isArray(service.details) 
    ? service.details 
    : [];

  // Parse exclusions
  const exclusions = Array.isArray(service.not_included)
    ? service.not_included
    : service.not_included?.ar?.points || service.not_included?.en?.points || [];

  // Parse instructions
  const arInstructions = typeof service.instructions === "string"
    ? service.instructions
    : service.instructions?.ar || service.instructions?.en || "";

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
      <Header />

      <main className="flex-1 pt-24 pb-28 lg:pb-16">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Breadcrumb / Top Actions */}
          <div className="mb-6 flex items-center justify-between">
            <Link 
              href={`/services?serviceId=${serviceId}`}
              className="flex items-center gap-2 text-slate-500 hover:text-[#0091FF] transition-colors text-xs font-bold bg-white px-3.5 py-1.5 rounded-full border border-slate-200 shadow-sm"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة لقائمة الخدمات</span>
            </Link>
            
            <button 
              onClick={toggleFavorite}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border text-xs font-bold transition-all ${
                isFavorite 
                  ? "bg-rose-50 border-rose-200 text-rose-500 shadow-sm" 
                  : "bg-white border-slate-200 hover:border-slate-300 text-slate-600 shadow-sm"
              }`}
            >
              <Heart className={`w-4 h-4 ${isFavorite ? "fill-rose-500" : ""}`} />
              <span>{isFavorite ? "في المفضلة" : "إضافة للمفضلة"}</span>
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Main Details Column (Right in RTL) */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* Alert for Paused Services */}
              {isPaused && (
                <div className="bg-amber-50 border border-amber-200 text-amber-900 rounded-3xl p-5 text-right flex items-start gap-3 shadow-sm">
                  <Sparkles className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
                  <div className="space-y-1">
                    <h3 className="font-extrabold text-sm">تنويه: ستتوفر هذه الخدمة قريباً</h3>
                    <p className="text-slate-600 text-xs leading-relaxed">
                      نعمل حالياً على تجهيز هذه الخدمة بأعلى معايير الجودة لتكون متاحة لحجزك قريباً جداً.
                    </p>
                  </div>
                </div>
              )}

              {/* Service Hero Header Card */}
              <div className="bg-white rounded-3xl border border-slate-200/80 p-6 sm:p-8 shadow-sm text-right">
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                  {/* Service Icon */}
                  <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center p-3.5 shrink-0 overflow-hidden">
                    {service.imageUrl ? (
                      <img 
                        src={service.imageUrl} 
                        alt={arTitle} 
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <Sparkles className="w-10 h-10 text-[#0091FF]" />
                    )}
                  </div>

                  {/* Text */}
                  <div className="space-y-3 flex-1 w-full text-center sm:text-right">
                    <h1 className="text-xl sm:text-2xl font-black text-slate-900 leading-tight">
                      {arTitle}
                    </h1>
                    {arDesc && (
                      <p className="text-slate-500 text-xs sm:text-sm leading-relaxed font-medium">
                        {arDesc}
                      </p>
                    )}
                    
                    {/* Trust guarantee badge */}
                    <div className="inline-flex items-center gap-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-black px-3 py-1 rounded-full">
                      <ShieldCheck className="w-3.5 h-3.5" />
                      <span>مشمول بضمان الجودة والأمان من Fresh Home</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* What's included (Inclusions) */}
              {inclusions.length > 0 && (
                <div className="bg-white rounded-3xl border border-slate-200/80 p-6 sm:p-8 shadow-sm text-right">
                  <h2 className="text-base font-black text-slate-900 mb-6 pb-2 border-b border-slate-100">
                    تفاصيل ومميزات الخدمة
                  </h2>
                  <div className="space-y-3.5">
                    {inclusions.map((item: any, idx: number) => {
                      const parsed = parseDetailItem(item, true);
                      if (!parsed) return null;

                      return (
                        <div 
                          key={idx} 
                          className="bg-[#F8FAFC] rounded-2xl border border-slate-200/70 overflow-hidden text-right"
                        >
                          <details className="group" open={idx === 0}>
                            <summary className="flex items-center justify-between p-4 cursor-pointer select-none list-none [&::-webkit-details-marker]:hidden">
                              <div className="flex items-center gap-3">
                                <div className="w-8 h-8 rounded-xl bg-blue-100 text-[#0091FF] flex items-center justify-center shrink-0">
                                  {parsed.icon ? (
                                    <img 
                                      src={parsed.icon} 
                                      alt={parsed.title} 
                                      className="w-5 h-5 object-contain" 
                                    />
                                  ) : (
                                    <Sparkles className="w-4 h-4" />
                                  )}
                                </div>
                                <span className="font-extrabold text-xs sm:text-sm text-slate-800">
                                  {parsed.title}
                                </span>
                              </div>
                              <span className="transition-transform duration-200 group-open:-rotate-90">
                                <ChevronLeft className="w-4 h-4 text-[#0091FF]" />
                              </span>
                            </summary>
                            
                            {parsed.points && parsed.points.length > 0 && (
                              <div className="px-5 pb-4 pt-1 border-t border-slate-200/60 bg-white">
                                <ul className="space-y-2.5 pt-2">
                                  {parsed.points.map((pt: string, pIdx: number) => (
                                    <li key={pIdx} className="flex items-start gap-2 text-xs text-slate-600 leading-relaxed font-medium">
                                      <Check className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                                      <span>{pt}</span>
                                    </li>
                                  ))}
                                </ul>
                              </div>
                            )}
                          </details>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* What's NOT included (Exclusions) */}
              {exclusions.length > 0 && (
                <div className="bg-white rounded-3xl border border-slate-200/80 p-6 sm:p-8 shadow-sm text-right">
                  <h2 className="text-base font-black text-slate-900 mb-4 pb-2 border-b border-slate-100">
                    الخدمة لا تشمل:
                  </h2>
                  <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs text-slate-600">
                    {exclusions.map((item: any, idx: number) => {
                      const text = !item ? "" : typeof item === "string" ? item : (item.ar || item.en || String(item));
                      return (
                        <li key={idx} className="flex items-center gap-2 bg-rose-50/60 p-3 rounded-xl border border-rose-100 font-medium">
                          <X className="w-4 h-4 text-rose-500 shrink-0" />
                          <span>{text}</span>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}

              {/* Service Instructions */}
              {arInstructions && (
                <div className="bg-amber-50/50 rounded-3xl border border-amber-200/70 p-6 shadow-sm text-right space-y-3">
                  <h2 className="text-sm font-black text-amber-900 pb-2 border-b border-amber-200/60 flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-amber-600 shrink-0" />
                    <span>تعليمات وإرشادات هامة للخدمة</span>
                  </h2>
                  <p className="text-xs text-slate-700 leading-relaxed font-medium whitespace-pre-line">
                    {arInstructions}
                  </p>
                </div>
              )}

              {/* Reviews Section */}
              {reviews.length > 0 && (
                <div className="bg-white rounded-3xl border border-slate-200/80 p-6 sm:p-8 shadow-sm text-right">
                  <h2 className="text-base font-black text-slate-900 mb-4 pb-2 border-b border-slate-100 flex items-center justify-between">
                    <span>آراء وتقييمات العملاء</span>
                    <span className="text-xs bg-blue-50 text-[#0091FF] px-2.5 py-0.5 rounded-full font-bold">
                      {reviews.length} تقييم موثق
                    </span>
                  </h2>

                  <div className="space-y-4">
                    {reviews.slice(0, 5).map((rev: any) => {
                      const custName = `${rev.customer_first_name || "عميل"} ${rev.customer_last_name || ""}`.trim() || "عميل فريش هوم";
                      const date = rev.created_at ? new Date(rev.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short", year: "numeric" }) : "";
                      return (
                        <div key={rev.id} className="p-4 rounded-2xl border border-slate-100 bg-[#F8FAFC] space-y-2">
                          <div className="flex justify-between items-center text-xs">
                            <div className="flex items-center gap-2">
                              <div className="w-7 h-7 rounded-full bg-blue-100 text-[#0091FF] flex items-center justify-center">
                                {rev.customer_avatar_url ? (
                                  <img 
                                    src={rev.customer_avatar_url} 
                                    alt={custName} 
                                    className="w-full h-full rounded-full object-cover" 
                                  />
                                ) : (
                                  <User className="w-3.5 h-3.5" />
                                )}
                              </div>
                              <span className="font-extrabold text-slate-800">{custName}</span>
                            </div>
                            <span className="text-slate-400 font-bold text-[10px]">{date}</span>
                          </div>
                          
                          <div className="flex items-center gap-1 text-amber-500 py-0.5">
                            {Array.from({ length: 5 }).map((_, i) => (
                              <Star 
                                key={i} 
                                className={`w-3 h-3 ${i < rev.rating_value ? "fill-amber-500 text-amber-500" : "text-slate-200"}`} 
                              />
                            ))}
                          </div>

                          {rev.feedback_text && (
                            <p className="text-xs text-slate-600 leading-relaxed font-medium">
                              {rev.feedback_text}
                            </p>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

            </div>

            {/* Sidebar Column: Sticky Pricing Card */}
            <div className="lg:col-span-4 sticky top-24">
              <div className="bg-white rounded-3xl border border-slate-200/80 p-6 sm:p-7 shadow-sm text-right space-y-6">
                <div>
                  <span className="text-slate-400 text-[10px] font-black uppercase tracking-wider block">
                    {priceLabel}
                  </span>
                  <div className="flex items-baseline gap-2 mt-1 justify-end">
                    <span className="text-2xl sm:text-3xl font-black text-[#0D327D]">
                      {startingPrice}
                    </span>
                    <span className="text-xs font-bold text-slate-500">
                      {unitText}
                    </span>
                  </div>
                  <span className="text-[10px] text-slate-400 block mt-1.5 leading-normal font-medium">
                    * يتم حساب السعر النهائي بدقة بناءً على المواصفات في الخطوة التالية.
                  </span>
                </div>

                <div className="border-t border-slate-100 pt-4 space-y-3 text-xs text-slate-600 leading-relaxed font-medium">
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-500 shrink-0" />
                    <span>تسعير فوري ومباشر حسب المساحة والمواصفات</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-500 shrink-0" />
                    <span>ضمان الجودة والاستلام التام الخاص بـ Fresh Home</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-500 shrink-0" />
                    <span>فنيون معتمدون ومفحوصون أمنياً ومهنياً</span>
                  </div>
                </div>

                {isPaused ? (
                  <a
                    href={`https://wa.me/${whatsappNumber}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full flex items-center justify-center gap-2 bg-[#25D366] hover:bg-[#20bd5a] text-white font-black py-3.5 rounded-xl text-center shadow-lg transition-all glow-whatsapp text-xs"
                  >
                    <span>أبلغني عند التوفر (واتساب)</span>
                  </a>
                ) : (
                  <Link
                    href={`/booking?serviceId=${serviceId}&subServiceId=${subServiceId}`}
                    className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-[#0091FF] to-[#0077E6] hover:opacity-95 text-white font-black py-3.5 rounded-xl text-center shadow-lg shadow-blue-500/20 transition-all glow-button text-xs"
                  >
                    <Calendar className="w-4 h-4" />
                    <span>احجز الخدمة الآن</span>
                  </Link>
                )}
              </div>
            </div>

          </div>

        </div>
      </main>

      {/* Floating Bottom Booking Bar for Mobile */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-xl border-t border-slate-200 px-5 py-3.5 flex items-center justify-between gap-4 shadow-xl">
        <div className="text-right font-sans">
          <span className="text-[10px] font-bold text-slate-400 block leading-tight">السعر يبدأ من</span>
          <div className="flex items-baseline gap-1 mt-0.5">
            <span className="text-lg font-black text-[#0D327D]">{startingPrice}</span>
            <span className="text-[10px] font-bold text-slate-500">{unitText}</span>
          </div>
        </div>
        
        {isPaused ? (
          <a
            href={`https://wa.me/${whatsappNumber}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 max-w-[200px] flex items-center justify-center gap-1.5 bg-[#25D366] text-white font-bold py-2.5 px-4 rounded-xl text-center text-xs shadow-md"
          >
            <span>أبلغني عند التوفر</span>
          </a>
        ) : (
          <Link
            href={`/booking?serviceId=${serviceId}&subServiceId=${subServiceId}`}
            className="flex-1 max-w-[200px] flex items-center justify-center gap-1.5 bg-[#0091FF] text-white font-bold py-2.5 px-4 rounded-xl text-center shadow-md text-xs"
          >
            <Calendar className="w-3.5 h-3.5" />
            <span>احجز الآن</span>
          </Link>
        )}
      </div>

      <Footer />
    </div>
  );
}

export default function ServiceDetailsPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
      </div>
    }>
      <ServiceDetailsContent />
    </Suspense>
  );
}
