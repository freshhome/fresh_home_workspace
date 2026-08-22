"use client";

import { useState, useEffect, useMemo } from "react";
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
  ArrowLeft,
  Plus,
  Home,
  ChevronLeft,
  SlidersHorizontal,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

interface SubServiceUI {
  id: string;
  parentId: string;
  title: string;
  desc: string;
  imageUrl?: string | null;
  icon: any;
  isFeatured?: boolean;
  tag?: string;
  href: string;
}

// Fallback services in case database is loading or offline
const fallbackServices: SubServiceUI[] = [
  {
    id: "post-construction",
    parentId: "cleaning-main",
    title: "تنظيف بعد التشطيب",
    desc: "تنظيف شامل بعد أعمال التشطيب",
    imageUrl: null,
    icon: Sparkles,
    isFeatured: true,
    tag: "الأكثر طلباً",
    href: "/booking",
  },
  {
    id: "deep-cleaning",
    parentId: "cleaning-main",
    title: "التنظيف العميق",
    desc: "تنظيف شامل لكل تفاصيل بيتك",
    imageUrl: null,
    icon: Sparkles,
    href: "/booking",
  },
  {
    id: "regular-cleaning",
    parentId: "cleaning-main",
    title: "التنظيف الدوري",
    desc: "حافظ على نظافة بيتك بانتظام",
    imageUrl: null,
    icon: Calendar,
    href: "/booking",
  },
  {
    id: "furniture-cleaning",
    parentId: "cleaning-main",
    title: "تنظيف الأثاث والمفروشات",
    desc: "غسيل كنب ومجالس وسجاد",
    imageUrl: null,
    icon: Armchair,
    href: "/booking",
  },
  {
    id: "glass-facade",
    parentId: "cleaning-main",
    title: "تنظيف الواجهات الزجاجية",
    desc: "نظافة ولمعان يدوم لأطول وقت",
    imageUrl: null,
    icon: AppWindow,
    href: "/booking",
  },
  {
    id: "ac-maintenance",
    parentId: "maintenance-main",
    title: "صيانة التكييف",
    desc: "صيانة وتنظيف الفلاتر وشحن الفريون",
    imageUrl: null,
    icon: Wind,
    href: "/booking",
  },
  {
    id: "plumbing",
    parentId: "maintenance-main",
    title: "السباكة والكهرباء",
    desc: "إصلاح وصيانة الأعطال الفورية",
    imageUrl: null,
    icon: Wrench,
    href: "/booking",
  },
  {
    id: "general-maintenance",
    parentId: "maintenance-main",
    title: "الصيانة والكهرباء",
    desc: "أمان وصيانة لكافة الأعطال",
    imageUrl: null,
    icon: ShieldAlert,
    href: "/booking",
  },
  {
    id: "pest-control",
    parentId: "pest-main",
    title: "مكافحة الحشرات",
    desc: "طرق فعالة وآمنة لإبادة الحشرات",
    imageUrl: null,
    icon: Bug,
    href: "/booking",
  },
];

const quickFilterTags = [
  { label: "الكل", query: "" },
  { label: "🔥 الأكثر طلباً", query: "تشطيب" },
  { label: "✨ تنظيف عميق", query: "عميق" },
  { label: "🛋️ كنب ومفروشات", query: "أثاث" },
  { label: "❄️ صيانة تكييف", query: "تكييف" },
  { label: "⚡ سباكة وكهرباء", query: "سباكة" },
  { label: "🐜 مكافحة حشرات", query: "حشرات" },
];

// Helper to determine the best fallback icon based on service title
function getServiceIcon(title: string) {
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

// Helper to resolve service icon / image from Supabase storage or URLs
function resolveServiceImage(imageStr?: string | null): string | null {
  if (!imageStr || typeof imageStr !== "string") return null;
  const clean = imageStr.trim();
  if (!clean) return null;
  if (clean.startsWith("http://") || clean.startsWith("https://")) {
    return clean;
  }
  if (clean.startsWith("/")) {
    return clean;
  }
  // Otherwise resolve from Supabase storage bucket 'service_images'
  const { data } = supabase.storage.from("service_images").getPublicUrl(clean);
  return data?.publicUrl || null;
}

export default function ServicesSection() {
  const [services, setServices] = useState<SubServiceUI[]>(fallbackServices);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [isFocused, setIsFocused] = useState(false);
  const [activeFilter, setActiveFilter] = useState("");

  useEffect(() => {
    async function fetchSubServices() {
      try {
        // Query active bookable sub-services from Supabase active_services_tree view
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("*")
          .order("sort_order", { ascending: true });

        if (!error && data && data.length > 0) {
          // Filter sub-services (those that are bookable or have a parent_id)
          const bookableItems = data.filter(
            (item: any) => item.is_bookable === true || item.parent_id !== null
          );

          if (bookableItems.length > 0) {
            const mapped: SubServiceUI[] = bookableItems.map((item: any, index: number) => {
              const title = item.title?.ar || item.title || "خدمة منزلية";
              const desc = item.description?.ar || item.description || "خدمة احترافية بأعلى معايير الجودة";
              const isPostConstruction = title.includes("تشطيب");
              const isFirst = index === 0;
              const imageUrl = resolveServiceImage(item.image);

              return {
                id: item.id,
                parentId: item.parent_id || item.id,
                title,
                desc,
                imageUrl,
                icon: getServiceIcon(title),
                isFeatured: isPostConstruction || (isFirst && !bookableItems.some((s: any) => (s.title?.ar || s.title || "").includes("تشطيب"))),
                tag: isPostConstruction ? "الأكثر طلباً" : index === 0 ? "مميز" : undefined,
                href: item.parent_id 
                  ? `/services/details?serviceId=${item.parent_id}&subServiceId=${item.id}`
                  : `/booking?subServiceId=${item.id}`,
              };
            });

            // Sort so the featured service is first (left/start of list in design)
            mapped.sort((a, b) => (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0));

            setServices(mapped);
          }
        }
      } catch (err) {
        console.warn("Using fallback services due to network:", err);
      } finally {
        setLoading(false);
      }
    }

    fetchSubServices();
  }, []);

  // Filter services in real-time based on query
  const filteredServices = useMemo(() => {
    const clean = searchQuery.trim().toLowerCase();
    if (!clean) return services;
    return services.filter(
      (s) =>
        s.title.toLowerCase().includes(clean) ||
        s.desc.toLowerCase().includes(clean)
    );
  }, [services, searchQuery]);

  const handleQuickFilter = (query: string) => {
    setActiveFilter(query);
    setSearchQuery(query);
  };

  return (
    <section id="services" className="py-16 bg-[#F8FAFC] relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* ========================================================================= */}
        {/* Modern Professional Search Bar (Placed Above Services Section)           */}
        {/* ========================================================================= */}
        <div className="max-w-3xl mx-auto mb-12">
          <div className="bg-white rounded-3xl border border-slate-200/80 shadow-[0_10px_35px_rgba(13,50,125,0.06)] p-3 sm:p-4 backdrop-blur-md relative z-30 transition-all hover:border-[#0091FF]/40">
            {/* Search Input Container */}
            <div className="relative flex items-center bg-[#F8FAFC] rounded-2xl border border-slate-200/90 focus-within:border-[#0091FF] focus-within:bg-white focus-within:ring-4 focus-within:ring-[#0091FF]/10 transition-all">
              {/* Search Icon (Right in RTL) */}
              <div className="pr-4.5 pl-2 text-[#0D327D] flex items-center justify-center">
                <Search className="w-5 h-5 text-[#0091FF]" />
              </div>

              {/* Text Input */}
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setActiveFilter("");
                }}
                onFocus={() => setIsFocused(true)}
                onBlur={() => setTimeout(() => setIsFocused(false), 250)}
                placeholder="ابحث عن أي خدمة (مثال: تنظيف بعد التشطيب، غسيل سجاد، صيانة تكييف...)"
                className="w-full bg-transparent text-slate-900 placeholder-slate-400 text-xs sm:text-sm font-bold py-3.5 sm:py-4 pl-12 pr-1 outline-none border-none text-right font-sans focus:ring-0"
              />

              {/* Clear Search Button */}
              {searchQuery && (
                <button
                  onClick={() => {
                    setSearchQuery("");
                    setActiveFilter("");
                  }}
                  className="absolute left-3 p-1.5 hover:bg-slate-200 text-slate-400 hover:text-slate-700 rounded-full transition-colors"
                  aria-label="مسح البحث"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            {/* Quick Filter Tag Chips */}
            <div className="flex items-center gap-1.5 sm:gap-2 mt-3 overflow-x-auto pb-1 pt-0.5 no-scrollbar text-right">
              <span className="text-[11px] font-bold text-slate-400 shrink-0 ml-1 flex items-center gap-1">
                <SlidersHorizontal className="w-3 h-3 text-[#0091FF]" />
                <span>اقتراحات سريعة:</span>
              </span>

              {quickFilterTags.map((tag) => {
                const isActive = activeFilter === tag.query || (tag.query === "" && searchQuery === "");
                return (
                  <button
                    key={tag.label}
                    onClick={() => handleQuickFilter(tag.query)}
                    className={`px-3 py-1 rounded-full text-xs font-bold transition-all shrink-0 border ${
                      isActive
                        ? "bg-[#0D327D] text-white border-[#0D327D] shadow-sm shadow-blue-900/20"
                        : "bg-slate-50 text-slate-600 border-slate-200 hover:bg-blue-50 hover:text-[#0091FF] hover:border-blue-200"
                    }`}
                  >
                    {tag.label}
                  </button>
                );
              })}
            </div>

            {/* Live Suggestion Overlay Dropdown (When focused & typing) */}
            {isFocused && searchQuery.trim() && (
              <div className="absolute top-full right-0 left-0 mt-2 bg-white rounded-2xl border border-slate-100 shadow-2xl overflow-hidden z-40 animate-fade-in-up text-right">
                <div className="p-3 bg-slate-50 border-b border-slate-100 flex items-center justify-between text-xs font-black text-slate-500">
                  <span>نتائج البحث المباشرة ({filteredServices.length})</span>
                  {searchQuery && (
                    <span className="text-[10px] text-[#0091FF] font-bold">
                      بحث عن: &quot;{searchQuery}&quot;
                    </span>
                  )}
                </div>

                <div className="max-h-64 overflow-y-auto divide-y divide-slate-50">
                  {filteredServices.length > 0 ? (
                    filteredServices.map((item) => (
                      <Link
                        key={item.id}
                        href={item.href}
                        className="flex items-center justify-between p-3.5 hover:bg-blue-50/60 transition-colors group"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-xl bg-blue-50 text-[#0091FF] flex items-center justify-center p-1.5 shrink-0">
                            {item.imageUrl ? (
                              <img
                                src={item.imageUrl}
                                alt={item.title}
                                className="w-full h-full object-contain"
                              />
                            ) : (
                              <item.icon className="w-4 h-4" />
                            )}
                          </div>
                          <div>
                            <h4 className="text-xs font-black text-slate-900 group-hover:text-[#0091FF] transition-colors">
                              {item.title}
                            </h4>
                            <p className="text-[10px] text-slate-400 font-medium line-clamp-1">
                              {item.desc}
                            </p>
                          </div>
                        </div>
                        <ChevronLeft className="w-4 h-4 text-slate-400 group-hover:text-[#0091FF] group-hover:-translate-x-1 transition-all" />
                      </Link>
                    ))
                  ) : (
                    <div className="p-6 text-center text-xs text-slate-400">
                      لم نجد خدمة مطابقة لـ &quot;{searchQuery}&quot;. جرب البحث بكلمات أخرى.
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* ========================================================================= */}
        {/* Section Header                                                            */}
        {/* ========================================================================= */}
        <div className="text-center mb-10">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            كل اللي بيتك محتاجه في مكان واحد
          </h2>
          <div className="w-12 h-1 bg-[#0091FF] rounded-full mx-auto mt-2.5" />
          {searchQuery && (
            <p className="text-xs text-[#0091FF] font-bold mt-2">
              نتائج مطابقة: {filteredServices.length} خدمة
            </p>
          )}
        </div>

        {/* Services Grid matching design */}
        {filteredServices.length > 0 ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-9 gap-3.5">
            {filteredServices.map((service) => {
              const Icon = service.icon;

              if (service.isFeatured) {
                return (
                  <Link
                    key={service.id}
                    href={service.href}
                    className="group relative rounded-2xl p-3.5 flex flex-col justify-between text-right overflow-hidden shadow-lg border border-blue-900/30 col-span-2 sm:col-span-1 md:col-span-2 lg:col-span-1 min-h-[190px] transition-all hover:-translate-y-1 hover:shadow-xl"
                  >
                    {/* Background Image for Featured Service */}
                    <img
                      src="/images/hero_transformation.jpg"
                      alt={service.title}
                      className="absolute inset-0 w-full h-full object-cover object-left filter brightness-50 group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-[#06112c] via-[#06112c]/80 to-[#071739]/60" />

                    {/* Top Badge & Icon */}
                    <div className="relative z-10 flex items-center justify-between">
                      <span className="inline-block text-[9px] font-black bg-white/20 text-[#22A5FC] px-2 py-0.5 rounded-full backdrop-blur-md border border-white/10">
                        {service.tag || "الأكثر طلباً"}
                      </span>

                      {/* Small Icon Badge if image exists */}
                      {service.imageUrl && (
                        <div className="w-6 h-6 rounded-lg bg-white/10 p-1 flex items-center justify-center backdrop-blur-md border border-white/10">
                          <img
                            src={service.imageUrl}
                            alt={service.title}
                            className="w-full h-full object-contain"
                          />
                        </div>
                      )}
                    </div>

                    {/* Content */}
                    <div className="relative z-10 mt-auto">
                      <h3 className="text-xs font-black text-white leading-tight">
                        {service.title}
                      </h3>
                      <p className="text-[10px] text-slate-300 font-medium line-clamp-2 mt-1">
                        {service.desc}
                      </p>

                      {/* Bottom Action Icon */}
                      <div className="mt-3 flex justify-start">
                        <span className="w-6 h-6 rounded-full bg-[#0091FF] text-white flex items-center justify-center shadow-md group-hover:scale-110 transition-transform">
                          <ArrowLeft className="w-3.5 h-3.5 stroke-[2.5]" />
                        </span>
                      </div>
                    </div>
                  </Link>
                );
              }

              return (
                <Link
                  key={service.id}
                  href={service.href}
                  className="group relative bg-white rounded-2xl p-3.5 flex flex-col justify-between items-center text-center border border-slate-100 shadow-sm hover:shadow-md hover:border-blue-200 transition-all hover:-translate-y-1 min-h-[190px]"
                >
                  {/* Icon / Image Container */}
                  <div className="w-11 h-11 rounded-2xl bg-blue-50 text-[#0091FF] group-hover:bg-[#0091FF] group-hover:text-white flex items-center justify-center transition-colors p-2 overflow-hidden shrink-0">
                    {service.imageUrl ? (
                      <img
                        src={service.imageUrl}
                        alt={service.title}
                        className="w-full h-full object-contain transition-all group-hover:brightness-0 group-hover:invert"
                      />
                    ) : (
                      <Icon className="w-5 h-5 stroke-[2]" />
                    )}
                  </div>

                  {/* Title and Short description */}
                  <div className="my-2">
                    <h3 className="text-xs font-extrabold text-slate-900 group-hover:text-[#0091FF] transition-colors leading-tight">
                      {service.title}
                    </h3>
                    <p className="text-[10px] text-slate-400 font-medium line-clamp-2 mt-1">
                      {service.desc}
                    </p>
                  </div>

                  {/* Add / Select Circle Button */}
                  <div className="w-6 h-6 rounded-full border border-slate-200 text-slate-400 group-hover:border-[#0091FF] group-hover:bg-[#0091FF] group-hover:text-white flex items-center justify-center transition-all">
                    <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
                  </div>
                </Link>
              );
            })}
          </div>
        ) : (
          /* Empty Search Results State */
          <div className="bg-white rounded-3xl border border-slate-100 shadow-sm p-10 text-center max-w-lg mx-auto space-y-4">
            <div className="w-14 h-14 rounded-2xl bg-blue-50 text-[#0091FF] flex items-center justify-center mx-auto">
              <Search className="w-7 h-7" />
            </div>
            <h3 className="text-base font-black text-slate-800">
              لم نجد نتائج مطابقة لـ &quot;{searchQuery}&quot;
            </h3>
            <p className="text-xs text-slate-500">
              يمكنك مسح البحث لعرض كافة الخدمات أو التواصل معنا عبر الواتساب لتوفير الخدمة التي تحتاجها.
            </p>
            <div className="flex items-center justify-center gap-3 pt-2">
              <button
                onClick={() => {
                  setSearchQuery("");
                  setActiveFilter("");
                }}
                className="px-5 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors"
              >
                عرض كل الخدمات
              </button>
              <a
                href="https://wa.me/201000000000"
                target="_blank"
                rel="noopener noreferrer"
                className="px-5 py-2.5 rounded-xl bg-[#25D366] text-white text-xs font-bold glow-whatsapp flex items-center gap-1.5"
              >
                <span>مساعدة عبر واتساب</span>
              </a>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
