"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowRight, ChevronLeft, Sparkles, Star, Search, X, CheckCircle2, Home } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";
import { buildWhatsAppUrl } from "@/lib/whatsapp";

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

function ServicesListContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const serviceId = searchParams.get("serviceId");

  const [subServices, setSubServices] = useState<any[]>([]);
  const [parentService, setParentService] = useState<any>(null);
  const [allRootServices, setAllRootServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");

  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      try {
        // Fetch all root services for category tabs switcher
        const { data: roots } = await supabase
          .from("active_services_tree")
          .select("*")
          .is("parent_id", null)
          .order("sort_order", { ascending: true });

        if (roots) {
          setAllRootServices(roots);
        }

        // Determine active category id (use query param or first root category)
        const activeId = serviceId || (roots && roots.length > 0 ? roots[0].id : null);

        if (!activeId) {
          setLoading(false);
          return;
        }

        // 1. Fetch parent service details
        const { data: parentData, error: parentError } = await supabase
          .from("active_services_tree")
          .select("*")
          .eq("id", activeId)
          .single();

        if (!parentError && parentData) {
          setParentService(parentData);
        }

        // 2. Fetch sub services
        const { data: subData, error: subError } = await supabase
          .from("active_services_tree")
          .select("*")
          .eq("parent_id", activeId)
          .order("sort_order", { ascending: true });

        if (subError) throw subError;

        // Fetch real ratings and review counts from reviews table
        const subIds = (subData || []).map((s: any) => s.id);
        const ratingsMap: Record<string, { avg: number; count: number }> = {};
        if (subIds.length > 0) {
          const { data: revs } = await supabase
            .from("reviews")
            .select("service_id, rating_value")
            .eq("status", "published")
            .in("service_id", subIds);

          if (revs) {
            const tempMap: Record<string, { sum: number; count: number }> = {};
            revs.forEach((r: any) => {
              if (!tempMap[r.service_id]) {
                tempMap[r.service_id] = { sum: 0, count: 0 };
              }
              tempMap[r.service_id].sum += r.rating_value;
              tempMap[r.service_id].count += 1;
            });
            Object.keys(tempMap).forEach((k) => {
              ratingsMap[k] = {
                avg: Number((tempMap[k].sum / tempMap[k].count).toFixed(1)),
                count: tempMap[k].count,
              };
            });
          }
        }

        const updatedSubServices = (subData || []).map((s: any) => ({
          ...s,
          imageUrl: resolveServiceImage(s.image),
          rating: ratingsMap[s.id]?.avg ?? 5.0,
          reviewsCount: ratingsMap[s.id]?.count ?? 0,
        }));
        setSubServices(updatedSubServices);

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
  }, [serviceId]);

  const parentTitle = parentService?.title?.ar || parentService?.title || "دليل الخدمات";
  const parentDesc = parentService?.description?.ar || parentService?.description || "تصفح خدماتنا المتخصصة بأعلى معايير الجودة والضمان.";

  const filteredServices = subServices.filter((sub) => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return true;
    const title = (sub.title?.ar || sub.title || "").toLowerCase();
    const desc = (sub.description?.ar || sub.description || "").toLowerCase();
    return title.includes(q) || desc.includes(q);
  });

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
      <Header />

      <main className="flex-1 pt-24 pb-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          {/* Breadcrumb Navigation */}
          <div className="mb-6 flex items-center justify-between">
            <Link
              href="/"
              className="flex items-center gap-2 text-slate-500 hover:text-[#0091FF] transition-colors text-xs font-bold bg-white px-3.5 py-1.5 rounded-full border border-slate-200 shadow-sm"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة للرئيسية</span>
            </Link>

            <div className="flex items-center gap-2 text-xs font-bold text-slate-400">
              <Link href="/" className="hover:text-slate-600">الرئيسية</Link>
              <span>/</span>
              <span className="text-[#0091FF]">خدمات {parentTitle}</span>
            </div>
          </div>

          {/* Premium Hero Banner for Category */}
          <div className="bg-gradient-to-r from-[#071739] via-[#0D2A68] to-[#071739] text-white rounded-3xl p-6 sm:p-10 relative overflow-hidden shadow-xl mb-10 text-right border border-blue-900/40">
            {/* Ambient Background Glow */}
            <div className="absolute top-0 right-1/4 w-96 h-96 bg-[#0091FF]/15 rounded-full blur-3xl pointer-events-none" />

            <div className="relative z-10 space-y-4 max-w-2xl">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 backdrop-blur-md border border-white/10 text-xs font-bold text-[#22A5FC]">
                <Sparkles className="w-3.5 h-3.5" />
                <span>قسم معتمد • جودة مضمونة</span>
              </span>

              <h1 className="text-2xl sm:text-4xl font-black tracking-tight text-white">
                خدمات {parentTitle}
              </h1>

              <p className="text-slate-200 text-xs sm:text-sm leading-relaxed font-medium">
                {parentDesc}
              </p>
            </div>
          </div>

          {/* Root Categories Switcher Tabs */}
          {allRootServices.length > 0 && (
            <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-8 no-scrollbar text-right">
              {allRootServices.map((root) => {
                const isActive = (parentService?.id === root.id) || (!serviceId && allRootServices[0]?.id === root.id);
                const title = root.title?.ar || root.title;
                return (
                  <button
                    key={root.id}
                    onClick={() => router.push(`/services?serviceId=${root.id}`)}
                    className={`px-5 py-2.5 rounded-2xl text-xs font-black transition-all shrink-0 border flex items-center gap-2 ${
                      isActive
                        ? "bg-[#0D327D] text-white border-[#0D327D] shadow-md shadow-blue-900/20 scale-102"
                        : "bg-white text-slate-700 border-slate-200 hover:bg-blue-50 hover:text-[#0091FF] hover:border-blue-200 shadow-sm"
                    }`}
                  >
                    <span>{title}</span>
                  </button>
                );
              })}
            </div>
          )}

          {/* Search Filter Inside Category */}
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-8 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
            <div className="relative w-full sm:max-w-md">
              <Search className="absolute right-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث داخل هذا القسم..."
                className="w-full bg-[#F8FAFC] rounded-xl border border-slate-200 py-2.5 pr-10 pl-9 text-xs font-bold text-slate-800 placeholder-slate-400 outline-none focus:border-[#0091FF] focus:bg-white"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            <div className="text-xs font-bold text-slate-500 self-end sm:self-center">
              إجمالي الخدمات المتاحة: <span className="text-[#0091FF] font-black">{filteredServices.length}</span>
            </div>
          </div>

          {/* Sub Services Grid */}
          <div className="space-y-6">
            {loading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div key={i} className="bg-white rounded-3xl border border-slate-100 p-6 space-y-4 animate-pulse shadow-sm">
                    <div className="flex justify-between items-center">
                      <div className="w-12 h-12 bg-slate-100 rounded-2xl" />
                      <div className="w-16 h-6 bg-slate-100 rounded-lg" />
                    </div>
                    <div className="w-2/3 h-5 bg-slate-200 rounded" />
                    <div className="w-full h-12 bg-slate-100 rounded" />
                    <div className="pt-4 border-t border-slate-50 flex justify-between">
                      <div className="w-20 h-7 bg-slate-100 rounded-lg" />
                      <div className="w-24 h-9 bg-slate-200 rounded-xl" />
                    </div>
                  </div>
                ))}
              </div>
            ) : filteredServices.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredServices.map((sub) => {
                  const arTitle = sub.title?.ar || sub.title;
                  const arDesc = sub.description?.ar || sub.description;
                  const rating = sub.rating;
                  const reviews = sub.reviewsCount;

                  let priceText = "حسب المواصفات";
                  if (sub.price_config?.min_price || sub.min_price) {
                    priceText = `تبدأ من ${sub.price_config?.min_price || sub.min_price} ج.م`;
                  } else if (sub.price_config?.value) {
                    priceText = `تبدأ من ${sub.price_config.value} ج.م`;
                  }

                  return (
                    <div
                      key={sub.id}
                      onClick={() =>
                        router.push(
                          sub.is_bookable
                            ? `/services/details?serviceId=${parentService?.id || serviceId}&subServiceId=${sub.id}`
                            : `/services?serviceId=${sub.id}`
                        )
                      }
                      className="bg-white rounded-3xl border border-slate-200/80 hover:border-[#0091FF]/40 p-6 shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col justify-between group cursor-pointer text-right transform hover:-translate-y-1"
                    >
                      <div>
                        {/* Top: Icon & Rating */}
                        <div className="flex justify-between items-center mb-5">
                          <div className="w-13 h-13 rounded-2xl bg-blue-50 text-[#0091FF] border border-blue-100 flex items-center justify-center p-2.5 group-hover:bg-[#0091FF] group-hover:text-white transition-colors overflow-hidden shrink-0">
                            {sub.imageUrl ? (
                              <img
                                src={sub.imageUrl}
                                alt={arTitle}
                                className="w-full h-full object-contain group-hover:brightness-0 group-hover:invert transition-all"
                              />
                            ) : (
                              <Sparkles className="w-6 h-6" />
                            )}
                          </div>

                          <div className="flex items-center gap-1 text-amber-500 text-xs font-black bg-amber-50 px-2.5 py-1 rounded-xl border border-amber-100">
                            <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                            <span>{rating}</span>
                            <span className="text-slate-400 font-normal">({reviews})</span>
                          </div>
                        </div>

                        {/* Title & Description */}
                        <div className="space-y-2">
                          <h3 className="font-black text-slate-900 text-base group-hover:text-[#0091FF] transition-colors line-clamp-1">
                            {arTitle}
                          </h3>
                          <p className="text-slate-500 text-xs leading-relaxed line-clamp-3 font-medium min-h-[50px]">
                            {arDesc}
                          </p>
                        </div>
                      </div>

                      {/* Bottom Price & Booking CTA */}
                      <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between gap-3">
                        <div>
                          <span className="text-[10px] text-slate-400 block font-bold">التكلفة التقديرية</span>
                          <span className="text-[#0D327D] font-black text-xs sm:text-sm block">{priceText}</span>
                        </div>

                        <span className="bg-[#0091FF] group-hover:bg-[#0077E6] text-white text-xs font-black px-4 py-2.5 rounded-xl transition-all shadow-md shadow-blue-500/20 flex items-center gap-1.5">
                          <span>احجز الآن</span>
                          <ChevronLeft className="w-3.5 h-3.5 transition-transform group-hover:-translate-x-1" />
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-16 px-6 bg-white rounded-3xl border border-slate-100 shadow-sm max-w-md mx-auto space-y-4">
                <div className="w-16 h-16 rounded-2xl bg-blue-50 text-[#0091FF] flex items-center justify-center mx-auto">
                  <Sparkles className="w-8 h-8" />
                </div>
                <h3 className="text-lg font-black text-slate-900">ستتوفر هذه الخدمة قريباً!</h3>
                <p className="text-slate-500 text-xs leading-relaxed">
                  نحن نعمل على تجهيز أفضل الفنيين لتقديم هذه الخدمة لك بأعلى مستويات الجودة.
                </p>
                <a
                  href={buildWhatsAppUrl(whatsappNumber, "مرحباً، أود الاستفسار عن توفر هذه الخدمة في منطقتي.")}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-[#25D366] text-white text-xs font-bold glow-whatsapp shadow-md"
                >
                  <span>طلب اهتمام عبر واتساب</span>
                </a>
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
      <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
      </div>
    }>
      <ServicesListContent />
    </Suspense>
  );
}
