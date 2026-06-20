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

  // 2. Direct keys: { icon, title, points, icon_id, icon_path }
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
          .from("services")
          .select("*")
          .eq("id", subServiceId)
          .single();

        if (error) throw error;
        setService(data);

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
      <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex items-center justify-center py-20">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
        </main>
        <Footer />
      </div>
    );
  }

  if (!service) {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex flex-col items-center justify-center py-20 text-slate-500">
          <p>عذراً، لم نتمكن من العثور على الخدمة المطلوبة.</p>
          <Link href="/" className="mt-4 text-primary font-bold hover:underline">العودة للرئيسية</Link>
        </main>
        <Footer />
      </div>
    );
  }

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
    : typeof service.not_included === "object" && service.not_included
    ? Object.values(service.not_included)
    : [];

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <Header />

      <main className="flex-1 py-10">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Breadcrumb / Back button */}
          <div className="mb-6 flex items-center justify-between">
            <Link 
              href={`/services?serviceId=${serviceId}`}
              className="flex items-center gap-2 text-slate-500 hover:text-primary transition-colors text-xs font-bold"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة لقائمة الخدمات</span>
            </Link>
            
            <button 
              onClick={toggleFavorite}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-bold transition-all ${
                isFavorite 
                  ? "bg-rose-50 border-rose-200 text-rose-500" 
                  : "bg-white border-slate-200 hover:border-slate-350 text-slate-500"
              }`}
            >
              <Heart className={`w-4 h-4 ${isFavorite ? "fill-rose-500" : ""}`} />
              <span>{isFavorite ? "في المفضلة" : "إضافة للمفضلة"}</span>
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Left Column: Details, Inclusions, Reviews */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* Header Info Card */}
              <div className="bg-white rounded-[22px] border border-slate-100 p-6 shadow-[0_8px_40px_rgba(0,0,0,0.05)] text-right">
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                  {/* Service Image */}
                  <div className="w-24 h-24 rounded-[22px] bg-service-bg border border-primary/5 flex items-center justify-center p-4 shrink-0 shadow-inner">
                    {service.image ? (
                      <img 
                        src={service.image} 
                        alt={arTitle} 
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <Sparkles className="w-10 h-10 text-primary/45" />
                    )}
                  </div>

                  {/* Text */}
                  <div className="space-y-3 flex-1 w-full text-center sm:text-right">
                    <h1 className="text-xl sm:text-2xl font-black text-slate-800 leading-tight">
                      {arTitle}
                    </h1>
                    {arDesc && (
                      <p className="text-slate-500 text-sm leading-relaxed font-light">
                        {arDesc}
                      </p>
                    )}
                    
                    {/* Trust guarantee mini-badge */}
                    <div className="inline-flex items-center gap-1.5 bg-emerald-50 text-secondary border border-emerald-100 text-[10px] font-black px-3 py-1 rounded-md mt-2">
                      <ShieldCheck className="w-3.5 h-3.5" />
                      <span>مشمول بضمان الجودة من فريش هوم</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* What's included (Inclusions) */}
              {inclusions.length > 0 && (
                <div className="bg-white rounded-[22px] border border-slate-100 p-6 shadow-[0_8px_40px_rgba(0,0,0,0.05)] text-right">
                  <h2 className="text-base font-black text-slate-800 mb-6 pb-2 border-b border-slate-100">
                    تفاصيل ومميزات الخدمة
                  </h2>
                  <div className="space-y-4">
                    {inclusions.map((item: any, idx: number) => {
                      const parsed = parseDetailItem(item, true); // true for Arabic
                      if (!parsed) return null;

                      return (
                        <div 
                          key={idx} 
                          className="bg-slate-50 rounded-2xl border border-slate-150 overflow-hidden text-right"
                        >
                          {/* Accordion Header */}
                          <details className="group" open={idx === 0}>
                            <summary className="flex items-center justify-between p-4 cursor-pointer select-none list-none [&::-webkit-details-marker]:hidden">
                              <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                                  {parsed.icon ? (
                                    <img 
                                      src={parsed.icon} 
                                      alt={parsed.title} 
                                      className="w-6 h-6 object-contain" 
                                    />
                                  ) : (
                                    <Sparkles className="w-5 h-5" />
                                  )}
                                </div>
                                <span className="font-extrabold text-sm text-slate-800">
                                  {parsed.title}
                                </span>
                              </div>
                              <span className="transition-transform duration-200 group-open:-rotate-90">
                                <ChevronLeft className="w-4 h-4 text-primary" />
                              </span>
                            </summary>
                            
                            {/* Accordion Body */}
                            {parsed.points && parsed.points.length > 0 && (
                              <div className="px-6 pb-4 pt-1 border-t border-slate-150/60 bg-white">
                                <ul className="space-y-3">
                                  {parsed.points.map((pt: string, pIdx: number) => (
                                    <li key={pIdx} className="flex items-start gap-2.5 text-xs text-slate-600 leading-relaxed pt-2">
                                      <Check className="w-4 h-4 text-secondary shrink-0 mt-0.5" />
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
                <div className="bg-white rounded-[22px] border border-slate-100 p-6 shadow-[0_8px_40px_rgba(0,0,0,0.05)] text-right">
                  <h2 className="text-base font-black text-slate-800 mb-4 pb-2 border-b border-slate-100">
                    الخدمة لا تشمل:
                  </h2>
                  <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm text-slate-500">
                    {exclusions.map((item: any, idx: number) => {
                      const text = !item ? "" : typeof item === "string" ? item : (item.ar || item.en || String(item));
                      return (
                        <li key={idx} className="flex items-center gap-2 bg-slate-50/50 p-3 rounded-xl border border-slate-100/50">
                          <X className="w-4 h-4 text-rose-500 shrink-0" />
                          <span>{text}</span>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}

              {/* Reviews Section */}
              <div className="bg-white rounded-[22px] border border-slate-100 p-6 shadow-[0_8px_40px_rgba(0,0,0,0.05)] text-right">
                <h2 className="text-base font-black text-slate-800 mb-4 pb-2 border-b border-slate-100 flex items-center justify-between">
                  <span>آراء وتقييمات العملاء</span>
                  {reviews.length > 0 && (
                    <span className="text-xs bg-slate-100 text-slate-500 px-2 py-0.5 rounded-full font-bold">
                      {reviews.length} تقييم
                    </span>
                  )}
                </h2>

                {reviews.length > 0 ? (
                  <div className="space-y-4">
                    {reviews.slice(0, 5).map((rev: any) => {
                      const custName = `${rev.customer_first_name || "عميل"} ${rev.customer_last_name || ""}`.trim() || "عميل فريش هوم";
                      const date = rev.created_at ? new Date(rev.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short", year: "numeric" }) : "";
                      return (
                        <div key={rev.id} className="p-4 rounded-xl border border-slate-150 bg-slate-50/50 space-y-2">
                          <div className="flex justify-between items-center text-xs">
                            <div className="flex items-center gap-2">
                              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                {rev.customer_avatar_url ? (
                                  <img 
                                    src={rev.customer_avatar_url} 
                                    alt={custName} 
                                    className="w-full h-full rounded-full object-cover" 
                                  />
                                ) : (
                                  <User className="w-4 h-4" />
                                )}
                              </div>
                              <span className="font-extrabold text-slate-700">{custName}</span>
                            </div>
                            <span className="text-slate-400 font-bold">{date}</span>
                          </div>
                          
                          <div className="flex items-center gap-1 text-amber-500 py-1">
                            {Array.from({ length: 5 }).map((_, i) => (
                              <Star 
                                key={i} 
                                className={`w-3.5 h-3.5 ${i < rev.rating_value ? "fill-amber-500 text-amber-500" : "text-slate-200"}`} 
                              />
                            ))}
                          </div>

                          {rev.feedback_text && (
                            <p className="text-xs sm:text-sm text-slate-600 leading-relaxed font-light">
                              {rev.feedback_text}
                            </p>
                          )}
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="text-center py-12 text-slate-400 text-xs">
                    لا توجد مراجعات منشورة لهذه الخدمة بعد.
                  </div>
                )}
              </div>

            </div>

            {/* Right Column: Pricing & Booking Sidebar */}
            <div className="lg:col-span-4 sticky top-24">
              <div className="bg-white rounded-[22px] border border-slate-100 p-6 shadow-[0_8px_40px_rgba(0,0,0,0.05)] text-right space-y-6">
                <div>
                  <span className="text-slate-400 text-[10px] font-black uppercase tracking-wider block">
                    {priceLabel}
                  </span>
                  <div className="flex items-baseline gap-2 mt-1 justify-end">
                    <span className="text-2xl sm:text-3xl font-black text-primary">
                      {startingPrice}
                    </span>
                    <span className="text-sm font-bold text-slate-500">
                      {unitText}
                    </span>
                  </div>
                  <span className="text-[10px] text-slate-400 block mt-1 leading-normal font-light">
                    * يتم حساب السعر النهائي بدقة بناءً على المواصفات في الخطوة التالية.
                  </span>
                </div>

                <div className="border-t border-slate-100 pt-4 space-y-3 text-xs text-slate-500 leading-relaxed font-light">
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-secondary shrink-0" />
                    <span>تسعير ديناميكي فوري دون مفاجآت</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-secondary shrink-0" />
                    <span>ضمان الجودة وإعادة العمل مجاناً</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-secondary shrink-0" />
                    <span>تأمين مالي شامل على الممتلكات</span>
                  </div>
                </div>

                <Link
                  href={`/booking?serviceId=${serviceId}&subServiceId=${subServiceId}`}
                  className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-primary to-[#22A5FC] hover:opacity-95 text-white font-extrabold py-3.5 rounded-xl text-center shadow-lg shadow-primary/20 transition-all duration-300 transform hover:-translate-y-0.5 active:translate-y-0 text-sm"
                >
                  <Calendar className="w-4 h-4" />
                  <span>احجز الخدمة كضيف</span>
                </Link>
              </div>
            </div>

          </div>

        </div>
      </main>

      <Footer />
    </div>
  );
}

export default function ServiceDetailsPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
      </div>
    }>
      <ServiceDetailsContent />
    </Suspense>
  );
}
