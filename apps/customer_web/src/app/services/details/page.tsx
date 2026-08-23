"use client";

import { useState, useEffect, useMemo, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { 
  ArrowRight, ArrowLeft, Calendar, Check, X, Star, 
  Sparkles, ShieldCheck, Heart, User, ChevronLeft,
  Layers, Zap, Home, ChevronRight, MessageCircle, Info
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
  
  const rootServiceId = searchParams.get("serviceId");
  const targetId = searchParams.get("subServiceId") || rootServiceId;

  const [allServices, setAllServices] = useState<any[]>([]);
  const [currentService, setCurrentService] = useState<any>(null);
  const [childServices, setChildServices] = useState<any[]>([]);
  const [reviews, setReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFavorite, setIsFavorite] = useState(false);
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");

  useEffect(() => {
    if (!targetId) {
      router.push("/");
      return;
    }

    const favorites = JSON.parse(localStorage.getItem("favorites") || "[]");
    setIsFavorite(favorites.includes(targetId));

    async function loadTreeAndNode() {
      setLoading(true);
      try {
        // Fetch all active services in the hierarchy
        const { data: treeData, error: treeError } = await supabase
          .from("active_services_tree")
          .select("*")
          .order("sort_order", { ascending: true });

        if (treeError) throw treeError;

        const all = treeData || [];
        setAllServices(all);

        // Find the current active service node
        const current = all.find((s: any) => s.id === targetId);
        if (current) {
          setCurrentService({
            ...current,
            imageUrl: resolveServiceImage(current.image),
          });

          // Find direct children of this node
          const children = all.filter((s: any) => s.parent_id === targetId && s.is_active !== false);
          
          // Map child services with descendants information
          const mappedChildren = children.map((child: any) => {
            const grandChildren = all.filter((s: any) => s.parent_id === child.id && s.is_active !== false);
            const hasKids = grandChildren.length > 0 || child.is_bookable === false;
            
            let priceText = "حسب المواصفات";
            if (child.price_config?.min_price || child.min_price) {
              priceText = `تبدأ من ${child.price_config?.min_price || child.min_price} ج.م`;
            } else if (child.price_config?.value) {
              priceText = `تبدأ من ${child.price_config.value} ج.م`;
            }

            return {
              ...child,
              imageUrl: resolveServiceImage(child.image),
              hasChildren: hasKids,
              childrenCount: grandChildren.length,
              priceText,
            };
          });

          setChildServices(mappedChildren);

          // If it's a leaf node, fetch reviews
          if (children.length === 0 && current.is_bookable) {
            const { data: reviewsData } = await supabase
              .from("view_reviews_with_details")
              .select("*")
              .eq("service_id", targetId)
              .eq("status", "published")
              .order("created_at", { ascending: false });

            setReviews(reviewsData || []);
          }
        }

        // WhatsApp number
        const { data: wsData } = await supabase
          .from("system_settings")
          .select("value")
          .eq("key", "whatsapp_settings")
          .single();
        if (wsData?.value?.business_number) {
          setWhatsappNumber(wsData.value.business_number);
        }
      } catch (e) {
        console.error("Error loading service tree:", e);
      } finally {
        setLoading(false);
      }
    }

    loadTreeAndNode();
  }, [targetId, router]);

  // Compute Breadcrumb trail up to the root
  const breadcrumbs = useMemo(() => {
    if (!currentService || allServices.length === 0) return [];
    
    const trail: { id: string; title: string; isCurrent: boolean }[] = [];
    let curr: any = currentService;

    while (curr) {
      trail.unshift({
        id: curr.id,
        title: curr.title?.ar || curr.title || "خدمة",
        isCurrent: curr.id === currentService.id,
      });
      if (curr.parent_id) {
        curr = allServices.find((s: any) => s.id === curr.parent_id);
      } else {
        curr = null;
      }
    }

    return trail;
  }, [currentService, allServices]);

  // Find root ancestor ID for booking links
  const rootAncestorId = useMemo(() => {
    if (breadcrumbs.length > 0) return breadcrumbs[0].id;
    return rootServiceId || currentService?.id || "FH-S-100001";
  }, [breadcrumbs, rootServiceId, currentService]);

  const toggleFavorite = () => {
    if (!targetId) return;
    const favorites = JSON.parse(localStorage.getItem("favorites") || "[]");
    let newFavorites = [];
    if (favorites.includes(targetId)) {
      newFavorites = favorites.filter((id: string) => id !== targetId);
      setIsFavorite(false);
    } else {
      newFavorites = [...favorites, targetId];
      setIsFavorite(true);
    }
    localStorage.setItem("favorites", JSON.stringify(newFavorites));
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex items-center justify-center py-20">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
        </main>
        <Footer />
      </div>
    );
  }

  if (!currentService) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans">
        <Header />
        <main className="flex-1 flex flex-col items-center justify-center py-20 text-slate-500 dark:text-slate-400 text-center px-4">
          <p className="text-sm font-bold">عذراً، لم نتمكن من العثور على الخدمة المطلوبة.</p>
          <Link href="/" className="mt-4 px-6 py-2.5 rounded-xl bg-[#0091FF] text-white text-xs font-black shadow-md">
            العودة للرئيسية
          </Link>
        </main>
        <Footer />
      </div>
    );
  }

  const isPaused = currentService.status === "paused";
  const arTitle = currentService.title?.ar || currentService.title || "الخدمة";
  const arDesc = currentService.description?.ar || currentService.description || "خدمة احترافية معتمدة من Fresh Home.";

  // =========================================================================
  // CASE A: Branch Node with Sub-Services (e.g. "السباكة", "النجارة", "صيانة التكييف")
  // =========================================================================
  if (childServices.length > 0) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans transition-colors duration-300">
        <Header />

        <main className="flex-1 pt-24 pb-20">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 space-y-8">
            
            {/* Dynamic Breadcrumbs */}
            <div className="flex items-center justify-between flex-wrap gap-2 text-xs font-bold">
              <nav className="flex items-center gap-1.5 text-slate-400 overflow-x-auto no-scrollbar py-1">
                <Link href="/" className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors">
                  الرئيسية
                </Link>
                {breadcrumbs.map((crumb, idx) => (
                  <div key={crumb.id} className="flex items-center gap-1.5">
                    <ChevronLeft className="w-3.5 h-3.5 text-slate-400" />
                    {crumb.isCurrent ? (
                      <span className="text-[#0091FF] font-black">{crumb.title}</span>
                    ) : (
                      <Link
                        href={`/services/details?serviceId=${rootAncestorId}&subServiceId=${crumb.id}`}
                        className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors"
                      >
                        {crumb.title}
                      </Link>
                    )}
                  </div>
                ))}
              </nav>

              <button 
                onClick={toggleFavorite}
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border text-xs font-bold transition-all ${
                  isFavorite 
                    ? "bg-rose-50 dark:bg-rose-950/40 border-rose-200 dark:border-rose-900/60 text-rose-500 shadow-sm" 
                    : "bg-white dark:bg-[#071739] border-slate-200 dark:border-blue-900/50 hover:border-slate-300 text-slate-600 dark:text-slate-300 shadow-sm"
                }`}
              >
                <Heart className={`w-4 h-4 ${isFavorite ? "fill-rose-500" : ""}`} />
                <span>{isFavorite ? "في المفضلة" : "إضافة للمفضلة"}</span>
              </button>
            </div>

            {/* Branch Header Banner */}
            <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right flex flex-col sm:flex-row items-center sm:items-start gap-6">
              <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900/40 flex items-center justify-center p-3.5 shrink-0 overflow-hidden shadow-sm">
                {currentService.imageUrl ? (
                  <img
                    src={currentService.imageUrl}
                    alt={arTitle}
                    className="w-full h-full object-contain"
                  />
                ) : (
                  <Layers className="w-10 h-10 text-[#0091FF]" />
                )}
              </div>
              <div className="space-y-2 text-center sm:text-right flex-1">
                <div className="flex items-center justify-center sm:justify-start gap-2.5">
                  <h1 className="text-xl sm:text-3xl font-black text-slate-900 dark:text-white">
                    خدمات {arTitle}
                  </h1>
                  <span className="text-[10px] font-extrabold px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50">
                    {childServices.length} خيارات متاحة
                  </span>
                </div>
                <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium leading-relaxed max-w-2xl">
                  {arDesc}
                </p>
                <p className="text-[11px] font-bold text-[#0091FF] dark:text-[#22A5FC] pt-1">
                  👇 يرجى اختيار الخدمة الدقيقة المناسبة لاحتياجك من القائمة أدناه للانتقال لتفاصيلها وحجزها:
                </p>
              </div>
            </div>

            {/* Sub-Services Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {childServices.map((child) => (
                <div
                  key={child.id}
                  className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 shadow-sm hover:shadow-xl hover:border-[#0091FF]/50 dark:hover:border-[#0091FF]/60 hover:-translate-y-1 transition-all duration-300 flex flex-col justify-between space-y-5 text-right group"
                >
                  <div className="space-y-4">
                    {/* Icon & Badge */}
                    <div className="flex items-start justify-between">
                      <div className="w-14 h-14 rounded-2xl bg-blue-50/80 dark:bg-[#050D24] border border-blue-100 dark:border-blue-900/50 flex items-center justify-center p-3 text-[#0091FF] dark:text-[#22A5FC] group-hover:bg-[#0091FF] group-hover:text-white transition-colors duration-300 shadow-sm shrink-0">
                        {child.imageUrl ? (
                          <img
                            src={child.imageUrl}
                            alt={child.title?.ar || child.title}
                            className="w-full h-full object-contain"
                          />
                        ) : (
                          <Sparkles className="w-6 h-6" />
                        )}
                      </div>

                      <div>
                        {child.hasChildren ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40 text-[10px] font-extrabold">
                            <Layers className="w-3 h-3" />
                            <span>{child.childrenCount} خيارات فرعية</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40 text-[10px] font-extrabold">
                            <Zap className="w-3 h-3" />
                            <span>حجز مباشر</span>
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Title & Desc */}
                    <div className="space-y-1.5">
                      <h3 className="text-base font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors leading-snug">
                        {child.title?.ar || child.title}
                      </h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed line-clamp-2">
                        {child.description?.ar || child.description || "خدمة متخصصة بأعلى معايير الجودة."}
                      </p>
                    </div>
                  </div>

                  {/* CTA Action */}
                  <div className="pt-3 border-t border-slate-100 dark:border-blue-900/40 flex items-center justify-between gap-2">
                    <span className="text-[11px] font-black text-[#0D327D] dark:text-[#22A5FC]">
                      {child.priceText}
                    </span>
                    <Link
                      href={`/services/details?serviceId=${rootAncestorId}&subServiceId=${child.id}`}
                      className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#0091FF] hover:bg-[#0077E6] text-white text-xs font-black shadow-md shadow-blue-500/20 transition-all group/btn"
                    >
                      <span>{child.hasChildren ? "استعراض الخيارات" : "عرض التفاصيل والحجز"}</span>
                      <ArrowLeft className="w-3.5 h-3.5 group-hover/btn:-translate-x-1 transition-transform" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </main>

        <Footer />
      </div>
    );
  }

  // =========================================================================
  // CASE B: Leaf Bookable Service Node (e.g. "كشف تسريبات المياه", "تنظيف بعد التشطيب")
  // =========================================================================
  let startingPrice = 250;
  let priceLabel = "السعر الأساسي التقديري";
  let unitText = "ج.م";

  const priceConfig = currentService.price_config || {};
  const type = priceConfig.type;
  const value = priceConfig.value || priceConfig.min_price || currentService.min_price || 0;

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

  const inclusions = Array.isArray(currentService.details) ? currentService.details : [];
  const exclusions = Array.isArray(currentService.not_included)
    ? currentService.not_included
    : currentService.not_included?.ar?.points || currentService.not_included?.en?.points || [];

  const arInstructions = typeof currentService.instructions === "string"
    ? currentService.instructions
    : currentService.instructions?.ar || currentService.instructions?.en || "";

  return (
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans transition-colors duration-300">
      <Header />

      <main className="flex-1 pt-24 pb-28 lg:pb-16">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Dynamic Breadcrumb & Favorite */}
          <div className="mb-6 flex items-center justify-between flex-wrap gap-2 text-xs font-bold">
            <nav className="flex items-center gap-1.5 text-slate-400 overflow-x-auto no-scrollbar py-1">
              <Link href="/" className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors">
                الرئيسية
              </Link>
              {breadcrumbs.map((crumb) => (
                <div key={crumb.id} className="flex items-center gap-1.5">
                  <ChevronLeft className="w-3.5 h-3.5 text-slate-400" />
                  {crumb.isCurrent ? (
                    <span className="text-[#0091FF] font-black">{crumb.title}</span>
                  ) : (
                    <Link
                      href={`/services/details?serviceId=${rootAncestorId}&subServiceId=${crumb.id}`}
                      className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors"
                    >
                      {crumb.title}
                    </Link>
                  )}
                </div>
              ))}
            </nav>
            
            <button 
              onClick={toggleFavorite}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border text-xs font-bold transition-all ${
                isFavorite 
                  ? "bg-rose-50 dark:bg-rose-950/40 border-rose-200 dark:border-rose-900/60 text-rose-500 shadow-sm" 
                  : "bg-white dark:bg-[#071739] border-slate-200 dark:border-blue-900/50 hover:border-slate-300 text-slate-600 dark:text-slate-300 shadow-sm"
              }`}
            >
              <Heart className={`w-4 h-4 ${isFavorite ? "fill-rose-500" : ""}`} />
              <span>{isFavorite ? "في المفضلة" : "إضافة للمفضلة"}</span>
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Main Details Column */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* Paused Service Alert */}
              {isPaused && (
                <div className="bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 text-amber-900 dark:text-amber-200 rounded-3xl p-5 text-right flex items-start gap-3 shadow-sm">
                  <Sparkles className="w-5 h-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                  <div className="space-y-1">
                    <h3 className="font-extrabold text-sm">تنويه: ستتوفر هذه الخدمة قريباً</h3>
                    <p className="text-slate-600 dark:text-slate-300 text-xs leading-relaxed">
                      نعمل حالياً على تجهيز هذه الخدمة بأعلى معايير الجودة لتكون متاحة لحجزك قريباً جداً.
                    </p>
                  </div>
                </div>
              )}

              {/* Service Hero Header Card */}
              <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right">
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                  {/* Clean Icon Badge (NOT a huge cover photo) */}
                  <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900/40 flex items-center justify-center p-3.5 shrink-0 overflow-hidden shadow-sm">
                    {currentService.imageUrl ? (
                      <img 
                        src={currentService.imageUrl} 
                        alt={arTitle} 
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <Sparkles className="w-10 h-10 text-[#0091FF] dark:text-[#22A5FC]" />
                    )}
                  </div>

                  <div className="space-y-2.5 text-center sm:text-right flex-1">
                    <div className="flex items-center justify-center sm:justify-start gap-2 flex-wrap">
                      <span className="text-[11px] font-bold px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50">
                        خدمة منزلية معتمدة
                      </span>
                      <span className="text-[11px] font-bold px-3 py-1 rounded-full bg-emerald-50 dark:bg-emerald-950/80 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50 flex items-center gap-1">
                        <ShieldCheck className="w-3.5 h-3.5" />
                        <span>مشمول بضمان Fresh Home</span>
                      </span>
                    </div>

                    <h1 className="text-xl sm:text-3xl font-black text-slate-900 dark:text-white">
                      {arTitle}
                    </h1>

                    <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 leading-relaxed font-medium">
                      {arDesc}
                    </p>
                  </div>
                </div>
              </div>

              {/* What's Included */}
              {inclusions.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right space-y-4">
                  <div className="flex items-center gap-2 text-slate-900 dark:text-white">
                    <Check className="w-5 h-5 text-emerald-500" />
                    <h3 className="text-base font-black">ما تشمله الخدمة</h3>
                  </div>

                  <div className="space-y-3">
                    {inclusions.map((item: any, idx: number) => {
                      const parsed = parseDetailItem(item);
                      if (!parsed) return null;
                      return (
                        <div key={idx} className="p-3.5 rounded-2xl bg-[#F8FAFC] dark:bg-[#050D24] border border-slate-100 dark:border-blue-900/40 space-y-1">
                          <h4 className="text-xs font-black text-slate-800 dark:text-slate-200">{parsed.title}</h4>
                          {parsed.points.length > 0 && (
                            <ul className="list-disc list-inside text-xs text-slate-500 dark:text-slate-400 space-y-1 pr-1 font-medium">
                              {parsed.points.map((pt: string, pIdx: number) => (
                                <li key={pIdx}>{pt}</li>
                              ))}
                            </ul>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* What's NOT Included */}
              {exclusions.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right space-y-4">
                  <div className="flex items-center gap-2 text-slate-900 dark:text-white">
                    <X className="w-5 h-5 text-rose-500" />
                    <h3 className="text-base font-black">ما لا تشمله الخدمة</h3>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                    {exclusions.map((ex: any, idx: number) => (
                      <div key={idx} className="flex items-center gap-2 p-3 rounded-2xl bg-rose-50/50 dark:bg-rose-950/20 border border-rose-100 dark:border-rose-900/30 text-rose-700 dark:text-rose-300 text-xs font-bold">
                        <X className="w-3.5 h-3.5 text-rose-500 shrink-0" />
                        <span>{typeof ex === "string" ? ex : ex?.ar || ex?.en || ""}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Instructions */}
              {arInstructions && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right space-y-3">
                  <div className="flex items-center gap-2 text-slate-900 dark:text-white">
                    <Info className="w-5 h-5 text-[#0091FF]" />
                    <h3 className="text-base font-black">تعليمات وإرشادات مهمة</h3>
                  </div>
                  <div className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed font-medium bg-[#F8FAFC] dark:bg-[#050D24] p-4 rounded-2xl border border-slate-100 dark:border-blue-900/30 whitespace-pre-line">
                    {arInstructions}
                  </div>
                </div>
              )}

              {/* Customer Reviews */}
              {reviews.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm text-right space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="text-base font-black text-slate-900 dark:text-white">تقييمات وتجارب العملاء</h3>
                    <div className="flex items-center gap-1 text-amber-500 text-xs font-black">
                      <Star className="w-4 h-4 fill-amber-500" />
                      <span>{reviews.length} تقييم</span>
                    </div>
                  </div>

                  <div className="space-y-3">
                    {reviews.slice(0, 3).map((rev: any) => (
                      <div key={rev.id} className="p-4 rounded-2xl bg-[#F8FAFC] dark:bg-[#050D24] border border-slate-100 dark:border-blue-900/30 space-y-2">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <div className="w-7 h-7 rounded-full bg-blue-100 dark:bg-blue-900/50 text-[#0091FF] flex items-center justify-center text-xs font-black">
                              <User className="w-3.5 h-3.5" />
                            </div>
                            <span className="text-xs font-bold text-slate-800 dark:text-slate-200">{rev.customer_name || "عميل فريش هوم"}</span>
                          </div>
                          <div className="flex items-center text-amber-500">
                            {Array.from({ length: rev.rating_value || 5 }).map((_, i) => (
                              <Star key={i} className="w-3 h-3 fill-amber-500" />
                            ))}
                          </div>
                        </div>
                        {rev.comment && (
                          <p className="text-xs text-slate-600 dark:text-slate-400 font-medium">{rev.comment}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Sticky Booking Sidebar */}
            <div className="lg:col-span-4 sticky top-24 space-y-4">
              <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-7 shadow-sm text-right space-y-6">
                
                {/* Price Display */}
                <div className="space-y-1 pb-5 border-b border-slate-100 dark:border-blue-900/40">
                  <span className="text-xs font-bold text-slate-400 block">{priceLabel}</span>
                  <div className="flex items-baseline gap-2">
                    <span className="text-3xl sm:text-4xl font-black text-[#0D327D] dark:text-[#22A5FC]">{startingPrice}</span>
                    <span className="text-xs font-black text-slate-500 dark:text-slate-400">{unitText}</span>
                  </div>
                  <span className="text-[10px] text-slate-400 font-medium block">
                    * يتم حساب السعر النهائي بدقة في الخطوة التالية بناءً على مواصفات طلبك.
                  </span>
                </div>

                {/* Key Benefits */}
                <div className="space-y-2.5 text-xs text-slate-600 dark:text-slate-300 font-medium">
                  <div className="flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-500 shrink-0" />
                    <span>تسعير فوري ومباشر حسب المواصفات</span>
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

                {/* Primary CTA Book Button / Paused Notification Button */}
                {isPaused ? (
                  <a
                    href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(`مرحباً، أود إشعاري فور توفر خدمة: ${arTitle}`)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full flex items-center justify-center gap-2 py-3.5 px-6 rounded-2xl bg-[#25D366] hover:bg-[#20bd5a] text-white text-xs sm:text-sm font-black shadow-lg shadow-emerald-500/20 glow-whatsapp transition-all"
                  >
                    <MessageCircle className="w-4 h-4" />
                    <span>إشعاري فور توفر الخدمة (واتساب)</span>
                  </a>
                ) : (
                  <>
                    <Link
                      href={`/booking?serviceId=${rootAncestorId}&subServiceId=${currentService.id}`}
                      className="w-full flex items-center justify-center gap-2 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs sm:text-sm font-black shadow-lg shadow-blue-500/25 glow-button transition-all"
                    >
                      <Calendar className="w-4 h-4" />
                      <span>احجز الخدمة الآن</span>
                    </Link>

                    {/* WhatsApp Support CTA */}
                    <a
                      href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(`مرحباً، أود الاستفسار عن خدمة: ${arTitle}`)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl border border-slate-200 dark:border-blue-900/50 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold transition-all"
                    >
                      <MessageCircle className="w-4 h-4 text-[#25D366]" />
                      <span>استفسر عبر واتساب</span>
                    </a>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Sticky Mobile Booking Bottom Bar */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-[#071739]/95 backdrop-blur-md border-t border-slate-200 dark:border-blue-900/60 p-4 shadow-2xl flex items-center justify-between gap-4">
        <div>
          <span className="text-[10px] text-slate-400 block font-bold">{priceLabel}</span>
          <div className="flex items-baseline gap-1">
            <span className="text-xl font-black text-[#0D327D] dark:text-[#22A5FC]">{startingPrice}</span>
            <span className="text-[10px] font-black text-slate-500">{unitText}</span>
          </div>
        </div>

        {isPaused ? (
          <a
            href={`https://wa.me/${whatsappNumber}?text=${encodeURIComponent(`مرحباً، أود إشعاري فور توفر خدمة: ${arTitle}`)}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 flex items-center justify-center gap-2 py-3 px-6 rounded-xl bg-[#25D366] text-white text-xs font-black shadow-md shadow-emerald-500/20"
          >
            <MessageCircle className="w-4 h-4" />
            <span>إشعاري عند التوفر</span>
          </a>
        ) : (
          <Link
            href={`/booking?serviceId=${rootAncestorId}&subServiceId=${currentService.id}`}
            className="flex-1 flex items-center justify-center gap-2 py-3 px-6 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black shadow-md shadow-blue-500/20"
          >
            <Calendar className="w-4 h-4" />
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
      <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
      </div>
    }>
      <ServiceDetailsContent />
    </Suspense>
  );
}
