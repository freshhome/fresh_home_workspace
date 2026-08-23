"use client";

import { useState, useEffect, useMemo, useRef, useCallback } from "react";
import Link from "next/link";
import {
  Search,
  X,
  Sparkles,
  Calendar,
  Armchair,
  AppWindow,
  Wind,
  Wrench,
  ShieldAlert,
  Bug,
  ChevronLeft,
  ChevronRight,
  ArrowLeft,
  Home,
  ShieldCheck,
  Layers,
  Zap,
  Clock,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

export interface ServiceNode {
  id: string;
  parentId: string | null;
  title: string;
  desc: string;
  iconPath?: string | null;
  fallbackIcon: any;
  status: "active" | "paused" | "ready" | string;
  isBookable: boolean;
  hasChildren: boolean;
  childrenCount: number;
  tag?: string;
  href: string;
}

export interface MainCategoryGroup {
  id: string;
  title: string;
  desc: string;
  iconPath?: string | null;
  fallbackIcon: any;
  status: string;
  badge: string;
  subServices: ServiceNode[];
}

// Fallback initial data matching the hierarchical schema
const fallbackTree: MainCategoryGroup[] = [
  {
    id: "FH-S-100001",
    title: "خدمات النظافة الشاملة",
    desc: "حلول تنظيف متكاملة للمنازل والمفروشات والواجهات بمعدات احترافية.",
    fallbackIcon: Sparkles,
    status: "active",
    badge: "5 خدمات فرعية",
    subServices: [
      {
        id: "FH-S-100009",
        parentId: "FH-S-100001",
        title: "تنظيف بعد التشطيب",
        desc: "إزالة آثار الدهانات والجبس وتنظيف الأرضيات والواجهات باحترافية كاملة.",
        iconPath: null,
        fallbackIcon: Sparkles,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        tag: "الأكثر طلباً",
        href: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100009",
      },
      {
        id: "FH-S-100010",
        parentId: "FH-S-100001",
        title: "التنظيف العميق",
        desc: "تنظيف شامل ودقيق لكل أركان المنزل والمطابخ والحمامات والأسطح.",
        iconPath: null,
        fallbackIcon: Sparkles,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        tag: "شامل",
        href: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100010",
      },
      {
        id: "FH-S-100011",
        parentId: "FH-S-100001",
        title: "تنظيف الأثاث والمفروشات",
        desc: "غسيل وتعقيم الكنب، السجاد، المراتب والستائر بالبخار ومواد خاصة.",
        iconPath: null,
        fallbackIcon: Armchair,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        tag: "تعقيم بالبخار",
        href: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100011",
      },
      {
        id: "FH-S-100012",
        parentId: "FH-S-100001",
        title: "التنظيف الدوري",
        desc: "زيارات تنظيف منتظمة بأفضل الأسعار للحفاظ على رونق ونظافة بيتك.",
        iconPath: null,
        fallbackIcon: Calendar,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        href: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100012",
      },
      {
        id: "FH-S-100013",
        parentId: "FH-S-100001",
        title: "تنظيف الواجهات والشبابيك",
        desc: "تلميع وتنظيف الواجهات والشبابيك والزجاج الداخلي والخارجي بلمعان فائق.",
        iconPath: null,
        fallbackIcon: AppWindow,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        href: "/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100013",
      },
    ],
  },
  {
    id: "FH-S-100002",
    title: "خدمات الصيانة والتشغيل",
    desc: "فنيون متخصصون لصيانة التكييفات والسباكة والكهرباء مع ضمان الجودة.",
    fallbackIcon: Wrench,
    status: "active",
    badge: "فنيون معتمدون",
    subServices: [
      {
        id: "FH-S-100020",
        parentId: "FH-S-100002",
        title: "صيانة وتنظيف التكييف",
        desc: "غسيل الفلاتر، شحن الفريون، صيانة الوحدات الداخلية والخارجية.",
        iconPath: null,
        fallbackIcon: Wind,
        status: "active",
        isBookable: false,
        hasChildren: true,
        childrenCount: 3,
        tag: "خيارات متعددة",
        href: "/services/details?serviceId=FH-S-100002&subServiceId=FH-S-100020",
      },
      {
        id: "FH-S-100021",
        parentId: "FH-S-100002",
        title: "السباكة والأدوات الصحية",
        desc: "كشف تسريبات المياه، صيانة وتأسيس شبكات الصرف الصحي والسباكة.",
        iconPath: null,
        fallbackIcon: Wrench,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        href: "/services/details?serviceId=FH-S-100002&subServiceId=FH-S-100021",
      },
      {
        id: "FH-S-100022",
        parentId: "FH-S-100002",
        title: "الصيانة والكهرباء العامة",
        desc: "إصلاح الأعطال الكهربائية المنزلية وتركيب الإضاءة والأجهزة بأمان تام.",
        iconPath: null,
        fallbackIcon: ShieldAlert,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        href: "/services/details?serviceId=FH-S-100002&subServiceId=FH-S-100022",
      },
    ],
  },
  {
    id: "FH-S-100003",
    title: "مكافحة الحشرات والتعقيم",
    desc: "إبادة فورية وآمنة 100% لكافة أنواع الحشرات والقوارض بضمان معتمد وبدون مغادرة المنزل.",
    fallbackIcon: Bug,
    status: "active",
    badge: "مواد آمنة ومصرحة",
    subServices: [
      {
        id: "FH-S-100030",
        parentId: "FH-S-100003",
        title: "إبادة ومكافحة الحشرات",
        desc: "مكافحة النمل الأبيض، الصراصير، البق، والقوارض بأحدث الأمصال الألمانية.",
        iconPath: null,
        fallbackIcon: Bug,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        tag: "ضمان 6 شهور",
        href: "/services/details?serviceId=FH-S-100003&subServiceId=FH-S-100030",
      },
      {
        id: "FH-S-100031",
        parentId: "FH-S-100003",
        title: "التعقيم والتطهير الشامل",
        desc: "تطهير المنازل والمكاتب من البكتيريا والفيروسات بمطهرات طبية آمنة.",
        iconPath: null,
        fallbackIcon: ShieldCheck,
        status: "active",
        isBookable: true,
        hasChildren: false,
        childrenCount: 0,
        href: "/services/details?serviceId=FH-S-100003&subServiceId=FH-S-100031",
      },
    ],
  },
];

// Helper to choose fallback icon
function getServiceFallbackIcon(title: string) {
  const t = title.toLowerCase();
  if (t.includes("تشطيب") || t.includes("بعد التشطيب")) return Sparkles;
  if (t.includes("عميق") || t.includes("deep")) return Sparkles;
  if (t.includes("دوري") || t.includes("regular") || t.includes("يومي")) return Calendar;
  if (t.includes("أثاث") || t.includes("كنب") || t.includes("سجاد") || t.includes("مفروشات") || t.includes("مجالس")) return Armchair;
  if (t.includes("زجاج") || t.includes("واجهات") || t.includes("شبابيك") || t.includes("window")) return AppWindow;
  if (t.includes("تكييف") || t.includes("ac") || t.includes("تبريد") || t.includes("فريون")) return Wind;
  if (t.includes("سباكة") || t.includes("plumbing") || t.includes("مواسير")) return Wrench;
  if (t.includes("كهرباء") || t.includes("صيانة") || t.includes("تصليح")) return ShieldAlert;
  if (t.includes("حشرات") || t.includes("مكافحة") || t.includes("إبادة") || t.includes("pest")) return Bug;
  return Home;
}

// Helper to resolve service icon path from Supabase storage or URLs
function resolveIconUrl(imageStr?: string | null): string | null {
  if (!imageStr || typeof imageStr !== "string") return null;
  const clean = imageStr.trim();
  if (!clean) return null;
  if (clean.startsWith("http://") || clean.startsWith("https://") || clean.startsWith("/")) {
    return clean;
  }
  const { data } = supabase.storage.from("service_images").getPublicUrl(clean);
  return data?.publicUrl || null;
}

// =========================================================================
// Category Slider with Automatic Auto-Scroll & Smart User Interaction Pause
// =========================================================================
function CategorySlider({ category }: { category: MainCategoryGroup }) {
  const sliderRef = useRef<HTMLDivElement>(null);
  const [isUserInteracting, setIsUserInteracting] = useState(false);
  const resumeTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const CategoryIcon = category.fallbackIcon;

  // Pause auto-scroll immediately on user interaction
  const pauseAutoScroll = useCallback(() => {
    setIsUserInteracting(true);
    if (resumeTimeoutRef.current) {
      clearTimeout(resumeTimeoutRef.current);
    }
  }, []);

  // Resume auto-scroll after idle delay
  const resumeAutoScrollAfterDelay = useCallback((delayMs = 4000) => {
    if (resumeTimeoutRef.current) {
      clearTimeout(resumeTimeoutRef.current);
    }
    resumeTimeoutRef.current = setTimeout(() => {
      setIsUserInteracting(false);
    }, delayMs);
  }, []);

  // Manual scroll with buttons
  const scroll = (direction: "left" | "right") => {
    pauseAutoScroll();
    if (!sliderRef.current) return;
    const scrollAmount = 300;
    sliderRef.current.scrollBy({
      left: direction === "left" ? -scrollAmount : scrollAmount,
      behavior: "smooth",
    });
    resumeAutoScrollAfterDelay(4500);
  };

  // Automatic gentle auto-scroll interval
  useEffect(() => {
    if (isUserInteracting || category.subServices.length <= 1) return;

    const interval = setInterval(() => {
      const el = sliderRef.current;
      if (!el) return;

      const maxScroll = el.scrollWidth - el.clientWidth;
      if (maxScroll <= 15) return; // No need to scroll if all cards fit

      // In RTL, scroll is negative or offsets from start
      const currentScroll = Math.abs(el.scrollLeft);

      if (currentScroll >= maxScroll - 35) {
        // Reached end, loop back smoothly to start
        el.scrollTo({ left: 0, behavior: "smooth" });
      } else {
        // Step to next card smoothly
        el.scrollBy({ left: -295, behavior: "smooth" });
      }
    }, 3600);

    return () => clearInterval(interval);
  }, [isUserInteracting, category.subServices.length]);

  // Clean up timeouts on unmount
  useEffect(() => {
    return () => {
      if (resumeTimeoutRef.current) {
        clearTimeout(resumeTimeoutRef.current);
      }
    };
  }, []);

  return (
    <div className="space-y-4">
      {/* Category Section Header: Clean Responsive Layout */}
      <div className="flex items-center justify-between gap-2.5 border-b border-slate-200/70 dark:border-blue-900/40 pb-3">
        {/* Right side: Icon + Title + Count Badge */}
        <div className="flex items-center gap-2.5 sm:gap-3.5 flex-1 min-w-0">
          <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-blue-50 dark:bg-blue-950/70 border border-blue-100 dark:border-blue-900/60 flex items-center justify-center text-[#0091FF] dark:text-[#22A5FC] shrink-0 shadow-xs">
            {category.iconPath ? (
              <img
                src={category.iconPath}
                alt={category.title}
                className="w-5 h-5 sm:w-6 sm:h-6 object-contain"
              />
            ) : (
              <CategoryIcon className="w-5 h-5 sm:w-6 sm:h-6" />
            )}
          </div>
          
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="text-base sm:text-xl font-black text-slate-900 dark:text-white truncate">
                {category.title}
              </h3>
              <span className="text-[10px] font-black px-2.5 py-0.5 rounded-full bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 shrink-0">
                {category.badge}
              </span>
              {category.status === "paused" && (
                <span className="text-[10px] font-black px-2.5 py-0.5 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50 shrink-0">
                  متوقف مؤقتاً
                </span>
              )}
            </div>
            <p className="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400 font-medium mt-0.5 truncate">
              {category.desc}
            </p>
          </div>
        </div>

        {/* Left side: Navigation Arrows */}
        <div className="flex items-center gap-1.5 shrink-0 self-center">
          <button
            type="button"
            onClick={() => scroll("right")}
            aria-label="السابق"
            className="w-8 h-8 rounded-xl bg-white dark:bg-[#071739] border border-slate-200 dark:border-blue-900/60 flex items-center justify-center text-slate-700 dark:text-slate-200 hover:bg-blue-50 dark:hover:bg-blue-900/40 hover:text-[#0091FF] hover:border-blue-300 transition-all shadow-xs cursor-pointer"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => scroll("left")}
            aria-label="التالي"
            className="w-8 h-8 rounded-xl bg-white dark:bg-[#071739] border border-slate-200 dark:border-blue-900/60 flex items-center justify-center text-slate-700 dark:text-slate-200 hover:bg-blue-50 dark:hover:bg-blue-900/40 hover:text-[#0091FF] hover:border-blue-300 transition-all shadow-xs cursor-pointer"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Horizontal Slider Track with Automatic Smooth Animation & Touch Gestures */}
      <div
        ref={sliderRef}
        onMouseEnter={pauseAutoScroll}
        onMouseLeave={() => resumeAutoScrollAfterDelay(2000)}
        onTouchStart={pauseAutoScroll}
        onTouchEnd={() => resumeAutoScrollAfterDelay(3500)}
        className="flex gap-3.5 sm:gap-5 overflow-x-auto pb-4 pt-1 scroll-smooth snap-x snap-mandatory no-scrollbar text-right px-0.5 touch-auto overscroll-x-contain"
        style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
      >
        {category.subServices.map((service) => {
          const ServiceIcon = service.fallbackIcon;
          const isPaused = service.status === "paused";

          return (
            <Link
              key={service.id}
              href={service.href}
              className={`w-[82vw] max-w-[285px] sm:w-[310px] shrink-0 snap-start bg-white dark:bg-[#071739] rounded-3xl border ${
                isPaused 
                  ? "border-amber-200/80 dark:border-amber-900/40 shadow-[0_4px_15px_rgba(245,158,11,0.05)] hover:border-amber-400" 
                  : "border-slate-200/80 dark:border-blue-900/50 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:border-[#0091FF]/60"
              } hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 p-4 sm:p-5 flex flex-col justify-between space-y-4 group cursor-pointer block text-right`}
            >
              {/* Card Top Row: Icon Container & Tag */}
              <div className="flex items-start justify-between">
                {/* Clean Professional Icon Badge */}
                <div className={`w-13 h-13 sm:w-14 sm:h-14 rounded-2xl ${
                  isPaused 
                    ? "bg-amber-50/80 dark:bg-amber-950/30 text-amber-500 border border-amber-200/60 dark:border-amber-900/40" 
                    : "bg-blue-50/80 dark:bg-[#050D24] text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 group-hover:bg-[#0091FF] group-hover:text-white"
                } flex items-center justify-center p-3 group-hover:scale-105 transition-all duration-300 shadow-xs shrink-0`}>
                  {service.iconPath ? (
                    <img
                      src={service.iconPath}
                      alt={service.title}
                      className="w-full h-full object-contain"
                    />
                  ) : (
                    <ServiceIcon className="w-6 h-6 sm:w-7 sm:h-7" />
                  )}
                </div>

                {/* Status & Feature Badges */}
                <div className="flex flex-col items-end gap-1">
                  {isPaused ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-lg bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50 text-[10px] font-black">
                      <Clock className="w-3 h-3" />
                      <span>متوقفة مؤقتاً</span>
                    </span>
                  ) : service.tag ? (
                    <span className="px-2.5 py-0.5 rounded-lg bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 text-[10px] font-black">
                      {service.tag}
                    </span>
                  ) : null}

                  {!isPaused && (
                    service.hasChildren ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-slate-50 dark:bg-slate-800/80 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-700 text-[9px] font-extrabold">
                        <Layers className="w-2.5 h-2.5 text-[#0091FF]" />
                        <span>{service.childrenCount} خيارات فرعية</span>
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40 text-[9px] font-extrabold">
                        <Zap className="w-2.5 h-2.5" />
                        <span>حجز مباشر</span>
                      </span>
                    )
                  )}
                </div>
              </div>

              {/* Card Body */}
              <div className="space-y-1.5 flex-1">
                <h4 className="text-sm sm:text-base font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors leading-snug">
                  {service.title}
                </h4>
                <p className="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed line-clamp-2">
                  {service.desc}
                </p>
              </div>

              {/* Card Footer Action Button Display */}
              <div className="pt-3 border-t border-slate-100 dark:border-blue-900/40">
                <div
                  className={`w-full flex items-center justify-between py-2.5 px-3.5 sm:px-4 rounded-xl ${
                    isPaused
                      ? "bg-amber-50/70 dark:bg-amber-950/30 group-hover:bg-amber-500 group-hover:text-white text-amber-800 dark:text-amber-300 border border-amber-200/80 dark:border-amber-900/40"
                      : "bg-[#F8FAFC] dark:bg-[#050D24] group-hover:bg-[#0091FF] dark:group-hover:bg-[#0091FF] text-slate-700 dark:text-slate-200 group-hover:text-white dark:group-hover:text-white border border-slate-200/80 dark:border-blue-900/50 group-hover:border-[#0091FF]"
                  } text-xs font-black transition-all shadow-xs`}
                >
                  <span>
                    {isPaused 
                      ? "تفاصيل الخدمة والإشعار" 
                      : service.hasChildren 
                        ? "استعراض الخيارات الفرعية" 
                        : "تفاصيل الخدمة والحجز"}
                  </span>
                  <ArrowLeft className="w-3.5 h-3.5 group-hover:-translate-x-1.5 transition-transform" />
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

export default function ServicesSection() {
  const [categories, setCategories] = useState<MainCategoryGroup[]>(fallbackTree);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [activeCategoryTab, setActiveCategoryTab] = useState("all");

  useEffect(() => {
    async function fetchFullServicesTree() {
      try {
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("*")
          .order("sort_order", { ascending: true });

        if (!error && data && data.length > 0) {
          // 1. Root Services (parent_id is null)
          const roots = data.filter((item: any) => item.parent_id === null && item.status !== "inactive" && item.status !== "archived");

          if (roots.length > 0) {
            const mappedGroups: MainCategoryGroup[] = roots.map((root: any) => {
              const rootTitle = root.title?.ar || root.title || "خدمات فريش هوم";
              const rootDesc = root.description?.ar || root.description || "خدمات منزلية احترافية معتمدة";
              const rootIconUrl = resolveIconUrl(root.image);

              // 2. Direct Children of Root
              const firstLevelChildren = data.filter((item: any) => item.parent_id === root.id && item.status !== "inactive" && item.status !== "archived");

              const subServices: ServiceNode[] = firstLevelChildren.map((sub: any) => {
                const subTitle = sub.title?.ar || sub.title || "خدمة فرعية";
                const subDesc = sub.description?.ar || sub.description || "خدمة بأعلى معايير الجودة";
                const subIconUrl = resolveIconUrl(sub.image);
                const isPostConstruction = subTitle.includes("تشطيب");

                // Check if this sub-service has further descendants in the tree
                const grandChildren = data.filter((item: any) => item.parent_id === sub.id && item.status !== "inactive" && item.status !== "archived");
                const hasChildren = grandChildren.length > 0 || sub.is_bookable === false;

                return {
                  id: sub.id,
                  parentId: root.id,
                  title: subTitle,
                  desc: subDesc,
                  iconPath: subIconUrl,
                  fallbackIcon: getServiceFallbackIcon(subTitle),
                  status: sub.status || "active",
                  isBookable: sub.is_bookable === true,
                  hasChildren,
                  childrenCount: grandChildren.length,
                  tag: isPostConstruction ? "الأكثر طلباً" : hasChildren ? "تفريعات متعددة" : undefined,
                  href: `/services/details?serviceId=${root.id}&subServiceId=${sub.id}`,
                };
              });

              return {
                id: root.id,
                title: rootTitle,
                desc: rootDesc,
                iconPath: rootIconUrl,
                fallbackIcon: getServiceFallbackIcon(rootTitle),
                status: root.status || "active",
                badge: `${subServices.length} خدمات فرعية`,
                subServices: subServices.length > 0 ? subServices : [],
              };
            });

            const validGroups = mappedGroups.filter((g) => g.subServices.length > 0);
            if (validGroups.length > 0) {
              setCategories(validGroups);
            }
          }
        }
      } catch (err) {
        console.warn("Using fallback tree due to network:", err);
      } finally {
        setLoading(false);
      }
    }

    fetchFullServicesTree();
  }, []);

  // Filtered categories based on selected tab and search query
  const displayedCategories = useMemo(() => {
    let result = categories;

    // 1. Tab filter
    if (activeCategoryTab !== "all") {
      result = result.filter((cat) => cat.id === activeCategoryTab);
    }

    // 2. Search query filter
    const cleanSearch = searchQuery.trim().toLowerCase();
    if (cleanSearch) {
      result = result
        .map((cat) => ({
          ...cat,
          subServices: cat.subServices.filter(
            (s) =>
              s.title.toLowerCase().includes(cleanSearch) ||
              s.desc.toLowerCase().includes(cleanSearch) ||
              cat.title.toLowerCase().includes(cleanSearch)
          ),
        }))
        .filter((cat) => cat.subServices.length > 0);
    }

    return result;
  }, [categories, activeCategoryTab, searchQuery]);

  const categoryTabs = [
    { id: "all", label: "الكل" },
    ...categories.map((cat) => ({
      id: cat.id,
      label: cat.title,
    })),
  ];

  return (
    <section id="services" className="py-12 sm:py-16 bg-[#F8FAFC] dark:bg-[#040A1C] relative transition-colors">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10 sm:space-y-12">
        
        {/* Search Bar & Professional Category Header */}
        <div className="max-w-3xl mx-auto space-y-4 sm:space-y-5 text-center">
          <div className="space-y-2">
            <h2 className="text-2xl sm:text-4xl font-black text-slate-900 dark:text-white font-sans tracking-tight">
              فريش هوم <span className="text-[#0091FF] dark:text-[#22A5FC]">•</span> نظافة وراحة تدوم
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium max-w-xl mx-auto">
              اختر الخدمة التي يحتاجها منزلك واحجز بسهولة بأعلى معايير الجودة والضمان
            </p>
          </div>

          {/* Clean Search Input */}
          <div className="bg-white dark:bg-[#071739] rounded-2xl sm:rounded-3xl border border-slate-200/80 dark:border-blue-900/50 shadow-[0_10px_35px_rgba(13,50,125,0.06)] p-2 sm:p-3 relative z-30 transition-all hover:border-[#0091FF]/40">
            <div className="relative flex items-center bg-[#F8FAFC] dark:bg-[#050D24] rounded-xl sm:rounded-2xl border border-slate-200/90 dark:border-blue-900/50 focus-within:border-[#0091FF] focus-within:bg-white dark:focus-within:bg-[#071739] focus-within:ring-4 focus-within:ring-[#0091FF]/10 transition-all">
              <div className="pr-3.5 pl-2 text-[#0D327D] dark:text-[#22A5FC] flex items-center justify-center">
                <Search className="w-4 h-4 sm:w-5 sm:h-5 text-[#0091FF]" />
              </div>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث عن أي خدمة (مثال: تنظيف، تكييف، سباكة، حشرات...)"
                className="w-full bg-transparent text-slate-900 dark:text-white placeholder-slate-400 text-xs sm:text-sm font-bold py-3 sm:py-3.5 pl-10 pr-1 outline-none border-none text-right font-sans focus:ring-0"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="absolute left-2.5 p-1.5 hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-400 hover:text-slate-700 dark:hover:text-white rounded-full transition-colors cursor-pointer"
                  aria-label="مسح البحث"
                >
                  <X className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                </button>
              )}
            </div>
          </div>

          {/* Category Filter Pills: Perfectly scrollable without clipping in RTL */}
          <div className="w-full overflow-x-auto no-scrollbar py-1 px-1">
            <div className="flex items-center gap-2 justify-start sm:justify-center min-w-max mx-auto">
              {categoryTabs.map((tab) => {
                const isActive = activeCategoryTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    type="button"
                    onClick={() => setActiveCategoryTab(tab.id)}
                    className={`px-4 py-2 rounded-xl sm:rounded-2xl text-xs font-black transition-all shrink-0 border cursor-pointer ${
                      isActive
                        ? "bg-[#0091FF] text-white border-[#0091FF] shadow-md shadow-blue-500/25"
                        : "bg-white dark:bg-[#071739] text-slate-600 dark:text-slate-300 border-slate-200/80 dark:border-blue-900/50 hover:bg-blue-50 dark:hover:bg-blue-900/30 hover:text-[#0091FF]"
                    }`}
                  >
                    {tab.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Hierarchical Sliders by Main Service Category */}
        {displayedCategories.length > 0 ? (
          <div className="space-y-10 sm:space-y-12">
            {displayedCategories.map((category) => (
              <CategorySlider key={category.id} category={category} />
            ))}
          </div>
        ) : (
          <div className="py-16 text-center bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/40 p-8 max-w-lg mx-auto space-y-4 shadow-sm">
            <div className="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-950/70 border border-blue-100 dark:border-blue-900/60 flex items-center justify-center mx-auto text-[#0091FF]">
              <Search className="w-6 h-6" />
            </div>
            <div className="space-y-1">
              <h3 className="text-base font-black text-slate-900 dark:text-white">
                لم يتم العثور على خدمات مطابقة
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                جرب البحث بكلمات أخرى مثل: &quot;تشطيب&quot;، &quot;تكييف&quot;، &quot;سباكة&quot;، أو &quot;حشرات&quot;.
              </p>
            </div>
            <button
              type="button"
              onClick={() => {
                setSearchQuery("");
                setActiveCategoryTab("all");
              }}
              className="px-5 py-2 rounded-xl bg-[#0091FF] text-white text-xs font-bold shadow-md shadow-blue-500/20 hover:bg-blue-600 transition-all cursor-pointer"
            >
              عرض جميع الخدمات
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
