"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, useEffect, useCallback } from "react";
import { 
  Menu, X, Moon, Sun, User, LogIn, Package, 
  ArrowRight, ShieldCheck, UserPlus, LogOut, ChevronLeft 
} from "lucide-react";
import Logo from "@/components/Logo";
import { supabase } from "@/lib/supabase";
import CoverageBanner from "@/components/CoverageBanner";

export default function Header() {
  const pathname = usePathname();
  const router = useRouter();

  const [isOpen, setIsOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [activeTab, setActiveTab] = useState("home");
  const [isDark, setIsDark] = useState(false);
  
  // User & Profile State
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<{ firstName: string; lastName: string; avatarUrl?: string } | null>(null);
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Fetch full user profile details from public.profiles table
  const fetchUserProfile = useCallback(async (sessionUser: any) => {
    if (!sessionUser) {
      setUser(null);
      setProfile(null);
      return;
    }
    setUser(sessionUser);

    try {
      const { data, error } = await supabase
        .from("profiles")
        .select("first_name, last_name, avatar_url")
        .eq("id", sessionUser.id)
        .single();

      if (data && !error) {
        setProfile({
          firstName: data.first_name || "",
          lastName: data.last_name || "",
          avatarUrl: data.avatar_url || "",
        });
      } else {
        const meta = sessionUser.user_metadata || {};
        setProfile({
          firstName: meta.first_name || meta.full_name?.split(" ")[0] || sessionUser.email?.split("@")[0] || "مستخدم",
          lastName: meta.last_name || meta.full_name?.split(" ").slice(1).join(" ") || "",
          avatarUrl: meta.avatar_url || "",
        });
      }
    } catch (e) {
      const meta = sessionUser.user_metadata || {};
      setProfile({
        firstName: meta.first_name || sessionUser.email?.split("@")[0] || "مستخدم",
        lastName: meta.last_name || "",
        avatarUrl: meta.avatar_url || "",
      });
    }
  }, []);

  useEffect(() => {
    // 1. Scroll listener
    const handleScroll = () => {
      if (window.scrollY > 20) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }
    };
    window.addEventListener("scroll", handleScroll);

    // 2. Initialize Dark Mode preference
    try {
      const savedTheme = localStorage.getItem("theme");
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      if (savedTheme === "dark" || (!savedTheme && prefersDark)) {
        setIsDark(true);
        document.documentElement.classList.add("dark");
      } else {
        setIsDark(false);
        document.documentElement.classList.remove("dark");
      }
    } catch (e) {
      console.warn("Theme init error:", e);
    }

    // 3. Supabase Auth listener & initial load
    supabase.auth.getSession().then(({ data: { session } }) => {
      fetchUserProfile(session?.user || null);
    });

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
      fetchUserProfile(session?.user || null);
    });

    // 4. Refresh profile on window focus
    const handleFocus = () => {
      supabase.auth.getSession().then(({ data: { session } }) => {
        fetchUserProfile(session?.user || null);
      });
    };
    window.addEventListener("focus", handleFocus);

    return () => {
      window.removeEventListener("scroll", handleScroll);
      window.removeEventListener("focus", handleFocus);
      authListener?.subscription.unsubscribe();
    };
  }, [fetchUserProfile]);

  const toggleTheme = () => {
    if (isDark) {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
      setIsDark(false);
    } else {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
      setIsDark(true);
    }
  };

  const handleNavClick = (sectionId: string, tabName: string) => {
    setActiveTab(tabName);
    setIsOpen(false);

    if (pathname === "/") {
      const el = document.getElementById(sectionId);
      if (el) {
        el.scrollIntoView({ behavior: "smooth" });
        return;
      }
    }
    router.push(`/#${sectionId}`);
  };

  const handleOrdersClick = (e: React.MouseEvent) => {
    e.preventDefault();
    setIsOpen(false);
    setActiveTab("orders");

    if (user) {
      router.push("/orders");
    } else {
      setShowAuthModal(true);
    }
  };

  // Compute Display Name & Avatar Initial
  const displayName = profile?.firstName 
    ? `${profile.firstName} ${profile.lastName}`.trim() 
    : (user?.user_metadata?.first_name || user?.email?.split("@")[0] || "حسابي");
  
  const userInitial = profile?.firstName 
    ? profile.firstName.charAt(0).toUpperCase() 
    : (user?.email?.charAt(0).toUpperCase() || "U");

  return (
    <>
      <div className="fixed top-0 left-0 right-0 z-50">
        <CoverageBanner />
        <header
          className={`transition-all duration-300 ${
            scrolled
              ? "bg-white/95 dark:bg-[#06112c]/95 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800/80 shadow-sm dark:shadow-lg py-3"
              : "bg-white/85 dark:bg-[#071330]/85 backdrop-blur-sm border-b border-slate-200/60 dark:border-white/5 py-4"
          }`}
        >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            {/* Official Fresh Home Logo */}
            <Logo />

            {/* Desktop Navigation Links */}
            <nav className="hidden md:flex items-center gap-1 lg:gap-2 bg-slate-100/90 dark:bg-white/5 border border-slate-200/80 dark:border-white/10 px-4 py-1.5 rounded-full backdrop-blur-md shadow-xs">
              <Link
                href="/"
                onClick={() => {
                  setActiveTab("home");
                  if (pathname === "/") {
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }
                }}
                className={`px-4 py-1.5 text-xs font-extrabold rounded-full transition-all cursor-pointer ${
                  activeTab === "home" && pathname === "/"
                    ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                    : "text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-white hover:bg-white dark:hover:bg-white/10"
                }`}
              >
                الرئيسية
              </Link>
              
              <button
                type="button"
                onClick={() => handleNavClick("services", "services")}
                className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all cursor-pointer ${
                  activeTab === "services"
                    ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                    : "text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-white hover:bg-white dark:hover:bg-white/10"
                }`}
              >
                الخدمات
              </button>

              <button
                type="button"
                onClick={() => handleNavClick("how-it-works", "how-it-works")}
                className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all cursor-pointer ${
                  activeTab === "how-it-works"
                    ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                    : "text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-white hover:bg-white dark:hover:bg-white/10"
                }`}
              >
                كيف نعمل
              </button>

              <button
                type="button"
                onClick={handleOrdersClick}
                className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all cursor-pointer ${
                  activeTab === "orders"
                    ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                    : "text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-white hover:bg-white dark:hover:bg-white/10"
                }`}
              >
                طلباتي
              </button>

              <button
                type="button"
                onClick={() => handleNavClick("why-us", "why-us")}
                className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all cursor-pointer ${
                  activeTab === "why-us"
                    ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                    : "text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-white hover:bg-white dark:hover:bg-white/10"
                }`}
              >
                لماذا Fresh Home
              </button>
            </nav>

            {/* Action Buttons (Left in RTL): Theme Toggle & Account / Login */}
            <div className="hidden sm:flex items-center gap-3">
              {/* Theme Toggle Button (Interactive Dark/Light Mode) */}
              <button
                onClick={toggleTheme}
                aria-label="تبديل المظهر النهاري والليلي"
                title={isDark ? "تفعيل الوضع النهاري" : "تفعيل الوضع الليلي"}
                className="p-2.5 rounded-xl text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-slate-100 dark:bg-white/10 hover:bg-slate-200 dark:hover:bg-white/15 transition-all border border-slate-200 dark:border-white/10 flex items-center justify-center cursor-pointer shadow-xs"
              >
                {isDark ? (
                  <Sun className="w-4 h-4 text-amber-400 transition-transform rotate-0 scale-100" />
                ) : (
                  <Moon className="w-4 h-4 text-[#0D327D] transition-transform -rotate-12" />
                )}
              </button>

              {/* Account / Profile / Login Button */}
              {user ? (
                /* Authenticated User: Profile Avatar & Name */
                <Link
                  href="/profile"
                  className="flex items-center gap-2.5 px-3 py-1.5 rounded-xl border border-blue-200 dark:border-blue-500/30 bg-blue-50/80 dark:bg-blue-500/10 hover:bg-blue-100 dark:hover:bg-blue-500/20 text-slate-800 dark:text-white transition-all group cursor-pointer shadow-sm"
                  title="عرض وإدارة الملف الشخصي"
                >
                  <div className="relative flex items-center justify-center">
                    {profile?.avatarUrl ? (
                      <img
                        src={profile.avatarUrl}
                        alt={displayName}
                        className="w-8 h-8 rounded-lg object-cover border border-[#0091FF]/40"
                      />
                    ) : (
                      <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-[#0091FF] to-[#00D2FF] text-white font-black text-xs flex items-center justify-center shadow-md shadow-blue-500/30">
                        {userInitial}
                      </div>
                    )}
                    <span className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#071330]"></span>
                  </div>
                  <div className="text-right flex flex-col justify-center">
                    <span className="text-xs font-black leading-tight text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors max-w-[120px] truncate">
                      {displayName}
                    </span>
                    <span className="text-[10px] font-medium text-slate-500 dark:text-slate-400 leading-tight">
                      الملف الشخصي
                    </span>
                  </div>
                </Link>
              ) : (
                /* Guest: Professional Login Button */
                <Link
                  href="/login"
                  className="flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-200 dark:border-white/10 bg-slate-100/90 dark:bg-white/5 hover:bg-slate-200 dark:hover:bg-white/10 hover:border-slate-300 dark:hover:border-white/20 text-slate-800 dark:text-white transition-all group cursor-pointer shadow-xs"
                  title="تسجيل الدخول إلى حسابك"
                >
                  <LogIn className="w-4 h-4 text-[#0091FF] dark:text-[#22A5FC] group-hover:scale-110 transition-transform" />
                  <span className="text-xs font-black">تسجيل الدخول</span>
                </Link>
              )}
            </div>

            {/* Mobile Menu Toggle & Actions */}
            <div className="flex sm:hidden items-center gap-2">
              {/* Account / Login on Mobile */}
              {user ? (
                <Link
                  href="/profile"
                  className="relative w-8 h-8 rounded-lg bg-gradient-to-tr from-[#0091FF] to-[#00D2FF] text-white font-black text-xs flex items-center justify-center border border-blue-400/40"
                  title="الملف الشخصي"
                >
                  {profile?.avatarUrl ? (
                    <img src={profile.avatarUrl} alt={displayName} className="w-full h-full rounded-lg object-cover" />
                  ) : (
                    <span>{userInitial}</span>
                  )}
                  <span className="absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full bg-emerald-500 ring-1 ring-white dark:ring-[#071330]"></span>
                </Link>
              ) : (
                <Link
                  href="/login"
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-white/10 bg-slate-100 dark:bg-white/10 text-slate-800 dark:text-white text-xs font-bold"
                >
                  <LogIn className="w-3.5 h-3.5 text-[#0091FF] dark:text-[#22A5FC]" />
                  <span>دخول</span>
                </Link>
              )}

              {/* Theme Toggle Button on Mobile */}
              <button
                onClick={toggleTheme}
                aria-label="تبديل المظهر"
                className="p-2 rounded-lg text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-slate-100 dark:bg-white/10 cursor-pointer"
              >
                {isDark ? (
                  <Sun className="w-4 h-4 text-amber-400" />
                ) : (
                  <Moon className="w-4 h-4 text-[#0D327D]" />
                )}
              </button>
              
              <button
                onClick={() => setIsOpen(!isOpen)}
                className="p-2 rounded-lg text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-slate-100 dark:bg-white/10 cursor-pointer"
                aria-label="القائمة"
              >
                {isOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Drawer Menu */}
        {isOpen && (
          <div className="sm:hidden bg-white dark:bg-[#06112c] border-b border-slate-200 dark:border-slate-800 px-4 pt-3 pb-6 space-y-2 mt-3 shadow-xl animate-fade-in-up">
            {/* User Profile / Login Card in Drawer */}
            <div className="pb-2 mb-2 border-b border-slate-100 dark:border-white/10">
              {user ? (
                <Link
                  href="/profile"
                  onClick={() => setIsOpen(false)}
                  className="flex items-center justify-between p-3 rounded-xl border border-[#0091FF]/30 bg-blue-50 dark:bg-[#0091FF]/10 text-slate-900 dark:text-white transition-all"
                >
                  <div className="flex items-center gap-3">
                    <div className="relative">
                      {profile?.avatarUrl ? (
                        <img
                          src={profile.avatarUrl}
                          alt={displayName}
                          className="w-10 h-10 rounded-xl object-cover border border-[#0091FF]/40"
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#0091FF] to-[#00D2FF] text-white font-black text-sm flex items-center justify-center shadow-md">
                          {userInitial}
                        </div>
                      )}
                      <span className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#06112c]"></span>
                    </div>
                    <div className="text-right">
                      <span className="block text-xs font-black text-slate-900 dark:text-white">
                        {displayName}
                      </span>
                      <span className="block text-[10px] text-slate-500 dark:text-slate-400">
                        {user.email || "عرض الملف الشخصي وإدارة العناوين"}
                      </span>
                    </div>
                  </div>
                  <ChevronLeft className="w-4 h-4 text-slate-400" />
                </Link>
              ) : (
                <Link
                  href="/login"
                  onClick={() => setIsOpen(false)}
                  className="flex items-center justify-between p-3 rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50 dark:bg-white/5 text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-white/10 transition-all"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-white/10 flex items-center justify-center text-[#0091FF] dark:text-slate-300">
                      <LogIn className="w-4 h-4" />
                    </div>
                    <div className="text-right">
                      <span className="block text-xs font-black text-slate-900 dark:text-white">
                        تسجيل الدخول
                      </span>
                      <span className="block text-[10px] text-slate-500 dark:text-slate-400">
                        سجل دخولك لحفظ بياناتك وعناوينك
                      </span>
                    </div>
                  </div>
                  <ChevronLeft className="w-4 h-4 text-slate-400" />
                </Link>
              )}
            </div>

            <Link
              href="/"
              onClick={() => {
                setIsOpen(false);
                if (pathname === "/") window.scrollTo({ top: 0, behavior: "smooth" });
              }}
              className="block px-3 py-2 rounded-lg text-sm font-bold text-white bg-[#0091FF]"
            >
              الرئيسية
            </Link>
            
            <button
              onClick={() => handleNavClick("services", "services")}
              className="w-full text-right block px-3 py-2 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-white/5"
            >
              الخدمات
            </button>
            
            <button
              onClick={() => handleNavClick("how-it-works", "how-it-works")}
              className="w-full text-right block px-3 py-2 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-white/5"
            >
              كيف نعمل
            </button>
            
            <button
              onClick={handleOrdersClick}
              className="w-full text-right block px-3 py-2 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-white/5"
            >
              طلباتي
            </button>
            
            <button
              onClick={() => handleNavClick("why-us", "why-us")}
              className="w-full text-right block px-3 py-2 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-white/5"
            >
              لماذا Fresh Home
            </button>

            <div className="pt-3 border-t border-slate-200 dark:border-white/10 flex items-center justify-between">
              <button
                onClick={toggleTheme}
                className="w-full flex items-center justify-center gap-2 text-xs font-bold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-white/10 py-2.5 rounded-xl cursor-pointer"
              >
                {isDark ? (
                  <>
                    <Sun className="w-4 h-4 text-amber-400" />
                    <span>تفعيل الوضع النهاري</span>
                  </>
                ) : (
                  <>
                    <Moon className="w-4 h-4 text-[#0D327D]" />
                    <span>تفعيل الوضع الليلي</span>
                  </>
                )}
              </button>
            </div>
          </div>
        )}
        </header>
      </div>

      {/* ========================================================================= */}
      {/* Auth Required Dialog Modal for "الطلبات" when guest is not logged in      */}
      {/* ========================================================================= */}
      {showAuthModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in font-sans">
          <div className="bg-white dark:bg-[#071739] border border-slate-200 dark:border-blue-900/60 rounded-3xl max-w-md w-full p-6 sm:p-8 text-right shadow-2xl relative space-y-5 animate-scale-up">
            {/* Close Button */}
            <button
              type="button"
              onClick={() => setShowAuthModal(false)}
              className="absolute top-5 left-5 p-1.5 rounded-full text-slate-400 hover:text-slate-700 dark:hover:text-white bg-slate-100 dark:bg-slate-800/80 transition-colors"
              aria-label="إغلاق"
            >
              <X className="w-4 h-4" />
            </button>

            {/* Icon & Title */}
            <div className="flex items-center gap-3.5 pt-2">
              <div className="w-12 h-12 rounded-2xl bg-blue-50 dark:bg-blue-950/70 border border-blue-100 dark:border-blue-900/50 flex items-center justify-center text-[#0091FF] dark:text-[#22A5FC] shrink-0">
                <Package className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-base sm:text-lg font-black text-slate-900 dark:text-white">
                  متابعة سجل طلباتك
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-0.5">
                  يرجى تسجيل الدخول لعرض وتتبع كافة حجوزاتك
                </p>
              </div>
            </div>

            {/* Description Card */}
            <div className="bg-[#F8FAFC] dark:bg-[#050D24] p-4 rounded-2xl border border-slate-200/80 dark:border-blue-900/40 space-y-2 text-xs text-slate-600 dark:text-slate-300 font-medium leading-relaxed">
              <div className="flex items-start gap-2">
                <ShieldCheck className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <span>عرض تفاصيل جميع الخدمات المحجوزة والجدول الزمني لوصول الفنيين.</span>
              </div>
              <div className="flex items-start gap-2">
                <ShieldCheck className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <span>إمكانية تعديل المواعيد والتواصل المباشر مع الدعم الفني.</span>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="space-y-2.5 pt-1">
              <Link
                href="/login?redirect=/orders"
                onClick={() => setShowAuthModal(false)}
                className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black shadow-lg shadow-blue-500/20 glow-button transition-all"
              >
                <LogIn className="w-4 h-4" />
                <span>تسجيل الدخول إلى حسابي</span>
              </Link>

              <Link
                href="/register?redirect=/orders"
                onClick={() => setShowAuthModal(false)}
                className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl border border-slate-200 dark:border-blue-900/50 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold transition-all"
              >
                <UserPlus className="w-4 h-4 text-[#0091FF]" />
                <span>إنشاء حساب جديد لأول مرة</span>
              </Link>

              <div className="pt-2 border-t border-slate-100 dark:border-slate-800 text-center">
                <Link
                  href="/orders"
                  onClick={() => setShowAuthModal(false)}
                  className="text-[11px] font-bold text-slate-400 hover:text-[#0091FF] transition-colors"
                >
                  أو تتبع طلب برقم الحجز فقط (للزوار) ←
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
