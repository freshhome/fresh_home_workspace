"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { Menu, X, Search, ChevronLeft } from "lucide-react";
import { supabase } from "@/lib/supabase";

const WhatsAppIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg viewBox="0 0 24 24" fill="currentColor" {...props}>
    <path d="M12.012 2c-5.506 0-9.989 4.478-9.99 9.984a9.96 9.96 0 001.37 5.054L2 22l5.13-1.346a9.921 9.921 0 004.882 1.28h.005c5.507 0 9.99-4.479 9.99-9.986C22.007 6.478 17.518 2 12.012 2zm6.09 13.982c-.268.76-1.531 1.393-2.13 1.462-.599.07-1.192.327-3.834-.72-2.641-1.047-4.329-3.73-4.462-3.907-.133-.177-1.082-1.442-1.082-2.75 0-1.307.683-1.95.927-2.215.244-.265.532-.332.71-.332.177 0 .354.004.51.011.165.008.387-.06.608.48.221.54.757 1.848.823 1.98.066.133.11.288.022.464-.088.177-.133.288-.266.442-.133.155-.28.346-.4.496-.133.167-.277.348-.12.62.156.27.691 1.139 1.482 1.842.92.818 1.693 1.07 1.936 1.193.244.122.388.106.532-.06.144-.167.62-.72.787-.962.167-.243.332-.2.554-.117.221.083 1.405.663 1.649.785.244.122.409.182.469.288.06.106.06.612-.208 1.372z"/>
  </svg>
);

export default function Header() {
  const [isOpen, setIsOpen] = useState(false);
  const [services, setServices] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearchFocused, setIsSearchFocused] = useState(false);
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");
  const [user, setUser] = useState<any>(null);
  const [loadingUser, setLoadingUser] = useState(true);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  useEffect(() => {
    // Check current auth session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoadingUser(false);
    });

    // Subscribe to auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      setLoadingUser(false);
    });

    async function fetchAllServices() {
      try {
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("id, title, description, parent_id, status, is_bookable");
        if (!error && data) {
          setServices(data);
        }
      } catch (e) {
        console.error("Error fetching services in header:", e);
      }
    }

    async function fetchWhatsappSettings() {
      try {
        const { data, error } = await supabase
          .from("system_settings")
          .select("value")
          .eq("key", "whatsapp_settings")
          .single();
        if (!error && data?.value?.business_number) {
          setWhatsappNumber(data.value.business_number);
        }
      } catch (err) {
        console.error("Error fetching whatsapp settings in header:", err);
      }
    }

    fetchAllServices();
    fetchWhatsappSettings();

    return () => {
      subscription.unsubscribe();
    };
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

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-slate-100 shadow-sm">
      {isSearchFocused && (
        <div 
          className="fixed inset-0 z-40 cursor-default" 
          onClick={() => setIsSearchFocused(false)}
        />
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-50">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div className="flex items-center gap-2 shrink-0">
            <Link href="/" className="flex items-center gap-3 group">
              <img 
                src="/app_icon_customer.png" 
                alt="فريش هوم" 
                className="w-10 h-10 object-contain rounded-xl shadow-md shadow-primary/10 transition-transform duration-300 group-hover:scale-105" 
              />
              <div className="hidden sm:block text-right">
                <span className="text-xl font-black text-primary tracking-tight font-sans block">فريش هوم</span>
                <span className="block text-[9px] text-secondary font-bold -mt-1 tracking-wider uppercase">Fresh Home</span>
              </div>
            </Link>
          </div>

          {/* Search Bar in App Bar */}
          <div className="relative mx-4 flex-1 max-w-[160px] xs:max-w-[200px] sm:max-w-xs md:max-w-sm">
            <div className="relative flex items-center bg-slate-100/80 rounded-xl border border-slate-200/50 shadow-xs focus-within:border-primary focus-within:bg-white focus-within:ring-2 focus-within:ring-primary/10 transition-all">
              <Search className="absolute right-3 w-4 h-4 text-slate-400" />
              <input
                type="text"
                placeholder="بحث عن خدمة..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onFocus={() => setIsSearchFocused(true)}
                className="w-full bg-transparent text-slate-800 placeholder-[#94A3B8] text-xs font-bold py-2 pr-9 pl-3 rounded-xl outline-none border-none text-right font-sans focus:ring-0"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="absolute left-2.5 p-0.5 hover:bg-slate-200 rounded-full transition-colors text-slate-400 hover:text-slate-600"
                >
                  <X className="w-3 h-3" />
                </button>
              )}
            </div>

            {/* Dropdown Results */}
            {isSearchFocused && searchQuery && (
              <div className="absolute top-full right-0 mt-2 w-[280px] md:w-[320px] bg-white rounded-2xl border border-slate-150 shadow-[0_10px_35px_rgba(0,0,0,0.08)] overflow-hidden text-right z-50 text-slate-800">
                {searchResults.length > 0 ? (
                  <div className="py-1">
                    <div className="max-h-[240px] overflow-y-auto divide-y divide-slate-50">
                      {searchResults.map((serve) => {
                        const isSubService = !!serve.parent_id;
                        const arTitle = serve.title?.ar || serve.title;
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
                              setIsSearchFocused(false);
                              setSearchQuery("");
                            }}
                            className="block px-3 py-2.5 hover:bg-primary/5 transition-colors group"
                          >
                            <div className="flex items-center justify-between gap-2">
                              <div className="flex-1">
                                <div className="flex items-center gap-1.5 flex-wrap">
                                  <span className="font-extrabold text-[11px] text-slate-800 group-hover:text-primary transition-colors">
                                    {arTitle}
                                  </span>
                                  {parentName && (
                                    <span className="text-[8px] font-black text-secondary bg-secondary/10 px-1.5 py-0.5 rounded-full">
                                      قسم {parentName}
                                    </span>
                                  )}
                                  {!isSubService && (
                                    <span className="text-[8px] font-black text-primary bg-primary/10 px-1.5 py-0.5 rounded-full">
                                      قسم رئيسي
                                    </span>
                                  )}
                                </div>
                              </div>
                              <ChevronLeft className="w-3.5 h-3.5 text-slate-300 group-hover:text-primary transition-transform transform group-hover:-translate-x-0.5" />
                            </div>
                          </Link>
                        );
                      })}
                    </div>
                  </div>
                ) : (
                  <div className="px-3 py-6 text-center text-slate-400 text-[11px] font-bold">
                    لا توجد خدمات مطابقة.
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Desktop Nav & WhatsApp CTA */}
          <div className="hidden md:flex items-center gap-6 shrink-0">
            <nav className="flex items-center gap-6 font-medium text-slate-600">
              <Link href="/" className="hover:text-primary transition-colors py-2 text-primary font-bold">الرئيسية</Link>
              <Link href="#services" className="hover:text-primary transition-colors py-2">خدماتنا</Link>
              <Link href="#trust" className="hover:text-primary transition-colors py-2">لماذا نحن؟</Link>
              <Link href="/orders" className="hover:text-primary transition-colors py-2 flex items-center gap-1.5">
                <span>تتبع الطلبات</span>
                <span className="bg-emerald-50 text-secondary text-[10px] font-bold px-2 py-0.5 rounded-full border border-emerald-100">نشط</span>
              </Link>
            </nav>

            <div className="h-4 w-[1px] bg-slate-200" />

            <a 
              href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 bg-[#25D366] hover:bg-[#20ba5a] text-white font-extrabold px-4 py-2 rounded-xl transition-all shadow-md shadow-emerald-500/10 hover:-translate-y-0.5 active:translate-y-0 text-xs"
            >
              <WhatsAppIcon className="w-4 h-4" />
              <span>تواصل معنا</span>
            </a>

            <div className="h-4 w-[1px] bg-slate-200" />

            {!loadingUser && (
              <div className="relative">
                {user ? (
                  <>
                    <button
                      onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                      className="flex items-center gap-2 px-3 py-1.5 rounded-xl border border-slate-200 hover:border-primary hover:bg-primary/5 transition-all text-xs font-bold text-slate-700 cursor-pointer"
                    >
                      <div className="w-6 h-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-black">
                        {user.user_metadata?.first_name ? user.user_metadata.first_name[0].toUpperCase() : user.email?.[0].toUpperCase()}
                      </div>
                      <span>{user.user_metadata?.first_name || "حسابي"}</span>
                    </button>
                    {isDropdownOpen && (
                      <>
                        <div 
                          className="fixed inset-0 z-40 cursor-default" 
                          onClick={() => setIsDropdownOpen(false)}
                        />
                        <div className="absolute left-0 mt-2 w-48 bg-white rounded-2xl border border-slate-150 shadow-lg py-1.5 z-50 text-right">
                          <Link
                            href="/profile"
                            onClick={() => setIsDropdownOpen(false)}
                            className="block px-4 py-2 text-xs font-bold text-slate-700 hover:bg-primary/5 hover:text-primary transition-colors"
                          >
                            ملفي الشخصي
                          </Link>
                          <Link
                            href="/orders"
                            onClick={() => setIsDropdownOpen(false)}
                            className="block px-4 py-2 text-xs font-bold text-slate-700 hover:bg-primary/5 hover:text-primary transition-colors"
                          >
                            طلباتي
                          </Link>
                          <button
                            onClick={async () => {
                              setIsDropdownOpen(false);
                              await supabase.auth.signOut();
                              window.location.href = "/";
                            }}
                            className="w-full text-right block px-4 py-2 text-xs font-bold text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer"
                          >
                            تسجيل الخروج
                          </button>
                        </div>
                      </>
                    )}
                  </>
                ) : (
                  <Link
                    href="/login"
                    className="px-4 py-2 rounded-xl bg-primary/10 hover:bg-primary text-primary hover:text-white border border-primary/20 hover:border-primary font-bold text-xs transition-all cursor-pointer"
                  >
                    تسجيل الدخول
                  </Link>
                )}
              </div>
            )}
          </div>

          {/* Mobile Menu Toggle */}
          <div className="md:hidden shrink-0">
            <button 
              onClick={() => setIsOpen(!isOpen)}
              className="p-2 text-slate-600 hover:text-primary transition-colors rounded-lg hover:bg-slate-50"
            >
              {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Drawer */}
      {isOpen && (
        <div className="md:hidden border-t border-slate-100 bg-white px-4 pt-2 pb-6 space-y-3 shadow-inner relative z-50">
          <Link 
            href="/" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-bold transition-all text-right"
            onClick={() => setIsOpen(false)}
          >
            الرئيسية
          </Link>
          <Link 
            href="#services" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-medium transition-all text-right"
            onClick={() => setIsOpen(false)}
          >
            خدماتنا
          </Link>
          <Link 
            href="#trust" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-medium transition-all text-right"
            onClick={() => setIsOpen(false)}
          >
            لماذا نحن؟
          </Link>
          <Link 
            href="/orders" 
            className="px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-medium transition-all flex items-center justify-between"
            onClick={() => setIsOpen(false)}
          >
            <span>تتبع الطلبات</span>
            <span className="bg-emerald-50 text-secondary text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-emerald-100">متاح الآن كضيف</span>
          </Link>
          {!loadingUser && (
            <div className="pt-2 border-t border-slate-100/80">
              {user ? (
                <div className="space-y-2.5">
                  <div className="flex items-center gap-2.5 px-3 py-1.5 bg-slate-50/55 rounded-xl">
                    <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-black">
                      {user.user_metadata?.first_name ? user.user_metadata.first_name[0].toUpperCase() : user.email?.[0].toUpperCase()}
                    </div>
                    <div className="text-right">
                      <span className="text-xs font-black block text-slate-800">{user.user_metadata?.first_name || "مرحباً بك"}</span>
                      <span className="text-[10px] font-medium text-slate-400 block">{user.email}</span>
                    </div>
                  </div>
                  <Link
                    href="/profile"
                    className="block px-3 py-2 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-bold text-right text-xs"
                    onClick={() => setIsOpen(false)}
                  >
                    ملفي الشخصي
                  </Link>
                  <Link
                    href="/orders"
                    className="block px-3 py-2 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-bold text-right text-xs"
                    onClick={() => setIsOpen(false)}
                  >
                    طلباتي
                  </Link>
                  <button
                    onClick={async () => {
                      setIsOpen(false);
                      await supabase.auth.signOut();
                      window.location.href = "/";
                    }}
                    className="w-full text-right block px-3 py-2 rounded-xl text-rose-600 hover:bg-rose-50 font-bold text-xs cursor-pointer"
                  >
                    تسجيل الخروج
                  </button>
                </div>
              ) : (
                <Link
                  href="/login"
                  className="block text-center px-4 py-2.5 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md cursor-pointer"
                  onClick={() => setIsOpen(false)}
                >
                  تسجيل الدخول / إنشاء حساب
                </Link>
              )}
            </div>
          )}

          <div className="pt-4 border-t border-slate-100 flex flex-col gap-3">
            <a 
              href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}`}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full flex items-center justify-center gap-2 bg-[#25D366] hover:bg-[#20ba5a] text-white font-extrabold py-3 rounded-xl text-center shadow-md transition-all text-xs"
              onClick={() => setIsOpen(false)}
            >
              <WhatsAppIcon className="w-4.5 h-4.5" />
              <span>تواصل معنا عبر واتساب</span>
            </a>
          </div>
        </div>
      )}
    </header>
  );
}
