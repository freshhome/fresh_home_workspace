"use client";

import { useState, useEffect, useMemo, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { 
  ArrowRight, ArrowLeft, Calendar, Check, X, Star, 
  Sparkles, ShieldCheck, Heart, User, ChevronLeft,
  Layers, Zap, Home, ChevronRight, MessageCircle, Info,
  ChevronDown, CheckCircle2, FileText
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { motion, AnimatePresence } from "framer-motion";
import { supabase } from "@/lib/supabase";
import { buildWhatsAppUrl } from "@/lib/whatsapp";
import { trackViewItem, trackContactWhatsApp } from "@/lib/gtm";

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
  const [expandedInclusions, setExpandedInclusions] = useState<number[]>([0]);

  const toggleInclusion = (idx: number) => {
    setExpandedInclusions((prev) =>
      prev.includes(idx) ? prev.filter((i) => i !== idx) : [...prev, idx]
    );
  };

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

  useEffect(() => {
    if (currentService && childServices.length === 0 && currentService.is_bookable) {
      const priceVal = currentService.price_config?.value || currentService.price_config?.min_price || currentService.min_price || 250;
      trackViewItem({
        service_id: currentService.id,
        service_name: currentService.title?.ar || currentService.title || "خدمة",
        category_id: rootAncestorId,
        category_name: breadcrumbs[0]?.title || "خدمات فريش هوم",
        price: Number(priceVal) || 250,
        currency: "EGP",
        price_type: currentService.price_config?.type || "fixed",
      });
    }
  }, [currentService?.id, childServices.length, rootAncestorId, breadcrumbs]);

  if (loading) {
    // [UI-FIX] Professional skeleton loader instead of a plain spinner
    return (
      <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans">
        <Header />
        <main className="flex-1 pt-24 pb-20">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
            {/* Breadcrumb skeleton */}
            <div className="mb-6 flex items-center gap-2">
              <div className="h-3.5 w-12 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
              <div className="h-3.5 w-3.5 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
              <div className="h-3.5 w-24 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
              <div className="h-3.5 w-3.5 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
              <div className="h-3.5 w-32 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
              <div className="lg:col-span-8 space-y-6">
                {/* Hero card skeleton */}
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm">
                  <div className="flex items-start gap-5">
                    <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl bg-slate-200 dark:bg-blue-900/30 animate-pulse shrink-0" />
                    <div className="space-y-3 flex-1">
                      <div className="h-6 sm:h-8 w-3/4 rounded-xl bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
                      <div className="h-3.5 w-full rounded-full bg-slate-100 dark:bg-blue-900/20 animate-pulse" />
                      <div className="h-3.5 w-2/3 rounded-full bg-slate-100 dark:bg-blue-900/20 animate-pulse" />
                    </div>
                  </div>
                </div>
                {/* Inclusions skeleton */}
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm space-y-4">
                  <div className="h-5 w-32 rounded-xl bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="flex items-center gap-3 p-3.5 rounded-2xl bg-slate-50 dark:bg-[#050D24]/40 border border-slate-100 dark:border-blue-900/40">
                      <div className="w-10 h-10 rounded-xl bg-slate-200 dark:bg-blue-900/30 animate-pulse shrink-0" />
                      <div className="h-4 flex-1 rounded-full bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
                      <div className="w-20 h-8 rounded-xl bg-slate-100 dark:bg-blue-900/20 animate-pulse shrink-0" />
                    </div>
                  ))}
                </div>
              </div>
              {/* Sidebar skeleton */}
              <div className="lg:col-span-4">
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 shadow-sm space-y-4">
                  <div className="h-10 w-28 rounded-xl bg-slate-200 dark:bg-blue-900/30 animate-pulse" />
                  <div className="h-3.5 w-full rounded-full bg-slate-100 dark:bg-blue-900/20 animate-pulse" />
                  <div className="h-12 w-full rounded-2xl bg-slate-200 dark:bg-blue-900/30 animate-pulse mt-2" />
                </div>
              </div>
            </div>
          </div>
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
              {/* [RESPONSIVE] min-w-0 + flex-1 + truncate: mirrors leaf breadcrumb fix, prevents overflow on small screens */}
              <nav className="flex items-center gap-1.5 text-slate-400 overflow-x-auto no-scrollbar py-1 min-w-0 flex-1">
                <Link href="/" className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors shrink-0">
                  الرئيسية
                </Link>
                {breadcrumbs.map((crumb, idx) => (
                  <div key={crumb.id} className="flex items-center gap-1.5 min-w-0">
                    <ChevronLeft className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                    {crumb.isCurrent ? (
                      <span className="text-[#0091FF] font-black truncate max-w-[120px] sm:max-w-none">{crumb.title}</span>
                    ) : (
                      <Link
                        href={`/services/details?serviceId=${rootAncestorId}&subServiceId=${crumb.id}`}
                        className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors truncate max-w-[100px] sm:max-w-none"
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
            {/* [RESPONSIVE] flex-row flex-wrap: icon + title stay horizontal, wrap only if space truly runs out.
                Icon scales fluidly 56px→80px. H1 scales fluidly 20px→30px. No breakpoint jumps. */}
            <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right flex flex-row flex-wrap items-center gap-4">
              <div className="w-[clamp(3.5rem,8vw,5rem)] h-[clamp(3.5rem,8vw,5rem)] rounded-2xl bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900/40 flex items-center justify-center p-3 shrink-0 overflow-hidden shadow-sm">
                {currentService.imageUrl ? (
                  <img
                    src={currentService.imageUrl}
                    alt={arTitle}
                    className="w-full h-full object-contain"
                  />
                ) : (
                  <Layers className="w-8 h-8 text-[#0091FF]" />
                )}
              </div>
              <div className="space-y-2 text-right flex-1 min-w-0">
                <div className="flex items-center gap-2.5 flex-wrap">
                  <h1 className="text-[clamp(1.25rem,4vw,1.875rem)] font-black text-slate-900 dark:text-white leading-snug">
                    خدمات {arTitle}
                  </h1>
                  <span className="text-[10px] font-extrabold px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 shrink-0">
                    {childServices.length} خيارات متاحة
                  </span>
                </div>
                <p className="text-[clamp(0.75rem,1.5vw,0.875rem)] text-slate-500 dark:text-slate-400 font-medium leading-relaxed">
                  {arDesc}
                </p>
                <p className="text-[11px] font-bold text-[#0091FF] dark:text-[#22A5FC] pt-1">
                  👇 يرجى اختيار الخدمة الدقيقة المناسبة لاحتياجك من القائمة أدناه للانتقال لتفاصيلها وحجزها:
                </p>
              </div>
            </div>

            {/* Sub-Services Grid */}
            {/* [RESPONSIVE] auto-fit minmax replaces 3 explicit breakpoints — cards tile naturally
                based on available width, with no media queries needed */}
            <div className="grid gap-5" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))" }}>
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
                  {/* [RESPONSIVE] flex-wrap: price + CTA button wrap to next line if space is tight */}
                  <div className="pt-3 border-t border-slate-100 dark:border-blue-900/40 flex flex-wrap items-center justify-between gap-2">
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
            {/* [UI-FIX] Breadcrumb: overflow-hidden + max-w to prevent spill on 360px screens */}
            <nav className="flex items-center gap-1.5 text-slate-400 overflow-x-auto no-scrollbar py-1 min-w-0 flex-1">
              <Link href="/" className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors shrink-0">
                الرئيسية
              </Link>
              {breadcrumbs.map((crumb) => (
                <div key={crumb.id} className="flex items-center gap-1.5 min-w-0">
                  <ChevronLeft className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  {crumb.isCurrent ? (
                    <span className="text-[#0091FF] font-black truncate max-w-[140px] sm:max-w-none">{crumb.title}</span>
                  ) : (
                    <Link
                      href={`/services/details?serviceId=${rootAncestorId}&subServiceId=${crumb.id}`}
                      className="hover:text-[#0091FF] text-slate-600 dark:text-slate-300 transition-colors truncate max-w-[100px] sm:max-w-none"
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
              {/* [RESPONSIVE] flex-row flex-wrap: stays horizontal at all sizes, wraps gracefully if needed.
                  Icon scales 48px→72px via clamp(). H1 22px→30px, desc 12px→14px — all fluid, no breakpoints. */}
              <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right">
                <div className="flex flex-row flex-wrap items-center gap-4">
                  {/* Fluid Icon Badge — scales with available space via clamp() */}
                  <div className="w-[clamp(3rem,6vw,4.5rem)] h-[clamp(3rem,6vw,4.5rem)] rounded-2xl bg-gradient-to-br from-blue-50 to-sky-50 dark:from-[#050D24] dark:to-[#071739] border border-blue-100 dark:border-blue-900/60 flex items-center justify-center p-3 shrink-0 shadow-xs">
                    {currentService.imageUrl ? (
                      <img 
                        src={currentService.imageUrl} 
                        alt={arTitle} 
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <Sparkles className="w-8 h-8 text-[#0091FF] dark:text-[#22A5FC]" />
                    )}
                  </div>

                  <div className="space-y-2 flex-1 min-w-0">
                    {/* [RESPONSIVE] fluid controlled H1 */}
                    <h1 className="text-[clamp(1.25rem,2.5vw,1.5rem)] font-black text-slate-900 dark:text-white tracking-tight leading-snug">
                      {arTitle}
                    </h1>

                    <p className="text-[clamp(0.8125rem,1.4vw,0.875rem)] text-slate-500 dark:text-slate-400 leading-relaxed font-medium">
                      {arDesc}
                    </p>
                  </div>
                </div>
              </div>

              {/* What's Included */}
              {inclusions.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-100/90 dark:border-blue-900/40 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right space-y-4">
                  {/* Main Section Header */}
                  <div className="space-y-1.5">
                    <div className="flex items-center gap-2.5 text-slate-900 dark:text-white">
                      <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 flex items-center justify-center text-emerald-600 dark:text-emerald-400 shrink-0 shadow-2xs">
                        <Check className="w-5 h-5 stroke-[2.5]" />
                      </div>
                      <h3 className="text-[clamp(1.125rem,2.2vw,1.375rem)] font-black text-slate-900 dark:text-white tracking-tight">ما تشمله الخدمة</h3>
                    </div>
                    <p className="text-[clamp(0.8125rem,1.4vw,0.875rem)] text-slate-500 dark:text-slate-400 font-medium leading-relaxed pr-1 sm:pr-2">
                      اقرأ تفاصيل الخدمة بعناية لتتعرف على ما يتم تنفيذه بدقة واحترافية في منزلك.
                    </p>
                  </div>

                  {/* Section Category Cards */}
                  <div className="space-y-3 pt-1">
                    {inclusions.map((item: any, idx: number) => {
                      const parsed = parseDetailItem(item);
                      if (!parsed) return null;
                      const isOpen = expandedInclusions.includes(idx);
                      const hasPoints = parsed.points && parsed.points.length > 0;
                      const itemIconUrl = resolveServiceImage(parsed.icon);

                      return (
                        <div 
                          key={idx} 
                          className={`rounded-3xl border transition-all duration-200 overflow-hidden ${
                            isOpen 
                              ? "bg-white dark:bg-[#071739] border-blue-200/90 dark:border-blue-800/80 shadow-xs" 
                              : `bg-white dark:bg-[#071739] border-slate-200/80 dark:border-blue-900/40 ${hasPoints ? "hover:border-blue-200 dark:hover:border-blue-900/70" : ""}`
                          }`}
                        >
                          {/* Card Header Row */}
                          <div 
                            onClick={() => hasPoints && toggleInclusion(idx)}
                            className={`p-3.5 sm:p-4 flex flex-wrap items-center justify-between gap-x-3 gap-y-2.5 sm:gap-x-4 ${hasPoints ? "cursor-pointer select-none" : ""}`}
                          >
                            <div className="flex items-center gap-3 sm:gap-3.5 flex-[1_1_210px] min-w-[min(100%,190px)] max-w-full">
                              {/* Icon squircle */}
                              <div className="w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-blue-50/90 dark:bg-blue-950/70 flex items-center justify-center text-[#0091FF] dark:text-[#22A5FC] shrink-0 p-2.5 shadow-2xs">
                                {itemIconUrl ? (
                                  <img src={itemIconUrl} alt="" className="w-full h-full object-contain" />
                                ) : (
                                  <Sparkles className="w-5 h-5" />
                                )}
                              </div>
                              <h4 className="text-[clamp(0.9375rem,1.8vw,1.0625rem)] font-black text-slate-900 dark:text-white leading-snug break-normal [overflow-wrap:anywhere]">
                                {parsed.title}
                              </h4>
                            </div>

                            {hasPoints && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  toggleInclusion(idx);
                                }}
                                className={`flex items-center justify-center gap-1.5 px-3.5 sm:px-4 py-2 rounded-xl text-xs sm:text-sm font-black transition-all shrink-0 cursor-pointer min-h-[40px] sm:min-h-[42px] select-none ms-auto sm:ms-0 ${
                                  isOpen
                                    ? "bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-200/80 dark:border-blue-900/60 shadow-xs"
                                    : "bg-blue-50/70 dark:bg-blue-950/40 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100/60 dark:border-blue-900/30 hover:bg-blue-100/80 dark:hover:bg-blue-900/50"
                                }`}
                              >
                                <span className="text-[clamp(0.75rem,1.2vw,0.8125rem)]">{isOpen ? "إخفاء" : "التفاصيل"}</span>
                                <ChevronDown className={`w-4 h-4 transition-transform duration-300 ease-out ${isOpen ? "rotate-180" : "rotate-0"}`} />
                              </button>
                            )}
                          </div>

                          {/* Accordion Content: Flatter Hierarchy with Sequential Badges */}
                          <AnimatePresence initial={false}>
                            {isOpen && hasPoints && (
                              <motion.div
                                key={`inclusions-content-${idx}`}
                                initial={{ height: 0, opacity: 0 }}
                                animate={{ height: "auto", opacity: 1 }}
                                exit={{ height: 0, opacity: 0 }}
                                transition={{ duration: 0.28, ease: "easeInOut" }}
                                className="overflow-hidden"
                              >
                                <div className="px-3.5 sm:px-4 pb-4 pt-1">
                                  <div className="space-y-2 pt-1">
                                    {parsed.points.map((pt: string, pIdx: number) => (
                                      <div 
                                        key={pIdx}
                                        className="flex items-start gap-3 p-3 sm:p-3.5 rounded-2xl bg-[#F8FAFC] dark:bg-white/[0.03] hover:bg-slate-100/80 dark:hover:bg-white/[0.06] transition-colors"
                                      >
                                        <span className="w-7 h-7 sm:w-8 sm:h-8 rounded-xl bg-blue-100/70 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] text-xs font-black flex items-center justify-center shrink-0 mt-0.5 shadow-2xs">
                                          {pIdx + 1}
                                        </span>
                                        <span className="text-[clamp(0.8125rem,1.5vw,0.875rem)] font-bold text-slate-700 dark:text-slate-200 leading-relaxed flex-1 text-right whitespace-pre-line">
                                          {pt}
                                        </span>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              </motion.div>
                            )}
                          </AnimatePresence>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* What's NOT Included */}
              {exclusions.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right space-y-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2.5 text-slate-900 dark:text-white">
                      <div className="w-8 h-8 rounded-xl bg-rose-50 dark:bg-rose-950/60 border border-rose-200/60 dark:border-rose-900/50 flex items-center justify-center text-rose-600 dark:text-rose-400 shrink-0">
                        <X className="w-4 h-4 stroke-[3]" />
                      </div>
                      <h3 className="text-[clamp(1rem,2vw,1.125rem)] font-black">ما لا تشمله الخدمة</h3>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400 font-medium pr-10">
                      ملاحظة هامة للشفافية: البنود التالية غير مدرجة ضمن نطاق هذا الطلب وتتطلب خدمات إضافية منفصلة.
                    </p>
                  </div>

                  {/* [RESPONSIVE] auto-fit replaces sm:grid-cols-2 breakpoint — items tile based on available width */}
                  <div className="grid gap-[clamp(0.625rem,2vw,0.75rem)] pt-1" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))" }}>
                    {exclusions.map((ex: any, idx: number) => (
                      <div 
                        key={idx} 
                        className="flex items-start gap-3 p-[clamp(0.75rem,2vw,1rem)] rounded-2xl bg-[#F8FAFC] dark:bg-[#050D24] border border-slate-100/90 dark:border-blue-900/25 shadow-[0_1px_3px_rgba(0,0,0,0.02)] transition-all hover:border-slate-200 dark:hover:border-blue-900/50"
                      >
                        <span className="w-[clamp(1.375rem,3vw,1.75rem)] h-[clamp(1.375rem,3vw,1.75rem)] rounded-lg bg-rose-50 dark:bg-rose-950/80 border border-rose-200/70 dark:border-rose-900/50 text-rose-500 flex items-center justify-center shrink-0 mt-0.5 shadow-2xs">
                          <X className="w-[clamp(0.875rem,2vw,1rem)] h-[clamp(0.875rem,2vw,1rem)] stroke-[2.5]" />
                        </span>
                        <span className="text-[clamp(0.875rem,2vw,1rem)] leading-[1.75] font-medium text-slate-700 dark:text-slate-200 whitespace-pre-line flex-1">
                          {typeof ex === "string" ? ex : ex?.ar || ex?.en || ""}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Instructions */}
              {arInstructions && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right space-y-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2.5 text-slate-900 dark:text-white">
                      <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900/50 flex items-center justify-center text-[#0091FF] dark:text-[#22A5FC] shrink-0">
                        <Info className="w-4 h-4" />
                      </div>
                      <h3 className="text-[clamp(1rem,2vw,1.125rem)] font-black">تعليمات وإرشادات هامة قبل بدء الخدمة</h3>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400 font-medium pr-10">
                      يرجى الاطلاع على الإرشادات التالية لضمان تنفيذ الخدمة بأعلى معايير الدقة والسرعة.
                    </p>
                  </div>

                  <div className="space-y-3 pt-1">
                    {arInstructions
                      .split("\n")
                      .map((line: string) => line.trim())
                      .filter((line: string) => line.length > 0)
                      .map((instruction: string, iIdx: number) => {
                        const cleanText = instruction.replace(/^([0-9]+[-.)\s]+|[-•*]\s*)/, "").trim();
                        return (
                          <div 
                            key={iIdx}
                            className="flex items-start gap-3 p-[clamp(0.75rem,2vw,1rem)] rounded-2xl bg-[#F8FAFC] dark:bg-[#050D24] border border-slate-100/90 dark:border-blue-900/25 shadow-[0_1px_3px_rgba(0,0,0,0.02)] text-slate-700 dark:text-slate-200"
                          >
                            <span className="w-[clamp(1.375rem,3vw,1.75rem)] h-[clamp(1.375rem,3vw,1.75rem)] rounded-lg bg-[#0091FF]/10 text-[#0091FF] dark:text-[#22A5FC] border border-blue-200/50 dark:border-blue-900/40 text-[clamp(0.7rem,1.5vw,0.875rem)] font-black flex items-center justify-center shrink-0 mt-0.5 shadow-2xs">
                              {iIdx + 1}
                            </span>
                            <span className="text-[clamp(0.875rem,2vw,1rem)] leading-[1.75] font-medium whitespace-pre-line flex-1">
                              {cleanText || instruction}
                            </span>
                          </div>
                        );
                      })}
                  </div>
                </div>
              )}

              {/* Customer Reviews */}
              {reviews.length > 0 && (
                <div className="bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-[clamp(1.25rem,3vw,2rem)] shadow-sm text-right space-y-4">
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
                    {/* [RESPONSIVE] clamp() sidebar price: fluid 30px→36px replaces text-3xl sm:text-4xl jump */}
                    <span className="text-[clamp(1.875rem,4vw,2.25rem)] font-black text-[#0D327D] dark:text-[#22A5FC]">{startingPrice}</span>
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
                    href={buildWhatsAppUrl(whatsappNumber, `مرحباً، أود إشعاري فور توفر خدمة: ${arTitle}`)}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() =>
                      trackContactWhatsApp({
                        placement: "service_details_paused",
                        service_context: arTitle,
                      })
                    }
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
                      href={buildWhatsAppUrl(whatsappNumber, `مرحباً، أود الاستفسار عن خدمة: ${arTitle}`)}
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={() =>
                        trackContactWhatsApp({
                          placement: "service_details_inquiry",
                          service_context: arTitle,
                        })
                      }
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

      {/* Sticky Mobile Booking Bottom Bar (Matches IMAGE 2) */}
      <div
        className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-[#071739]/95 backdrop-blur-md border-t border-slate-100 dark:border-blue-900/50 shadow-[0_-4px_20px_rgba(0,0,0,0.04)] flex items-center justify-between gap-4 px-4 pt-3.5"
        style={{ paddingBottom: "max(1rem, env(safe-area-inset-bottom, 1rem))" }}
      >
        <div>
          <span className="text-[11px] text-slate-400 block font-bold">{priceLabel}</span>
          <div className="flex items-baseline gap-1">
            <span className="text-2xl font-black text-[#0D327D] dark:text-white">{startingPrice}</span>
            <span className="text-xs font-bold text-slate-500 mr-1">{unitText}</span>
          </div>
        </div>

        {isPaused ? (
          <a
            href={buildWhatsAppUrl(whatsappNumber, `مرحباً، أود إشعاري فور توفر خدمة: ${arTitle}`)}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() =>
              trackContactWhatsApp({
                placement: "service_details_paused",
                service_context: arTitle,
              })
            }
            className="flex-1 flex items-center justify-center gap-2 py-3 px-6 rounded-2xl bg-[#25D366] text-white text-xs sm:text-sm font-black shadow-md shadow-emerald-500/20"
          >
            <MessageCircle className="w-4 h-4" />
            <span>إشعاري عند التوفر</span>
          </a>
        ) : (
          <Link
            href={`/booking?serviceId=${rootAncestorId}&subServiceId=${currentService.id}`}
            className="flex-1 flex items-center justify-center gap-2 py-3.5 px-6 rounded-2xl bg-[#0091FF] hover:bg-[#0080E5] text-white text-xs sm:text-sm font-black shadow-md shadow-blue-500/25 transition-all"
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
