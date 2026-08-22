"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { Menu, X, Moon, Sun, Globe, ChevronDown } from "lucide-react";
import Logo from "@/components/Logo";

export default function Header() {
  const [isOpen, setIsOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [activeTab, setActiveTab] = useState("home");
  const [isDark, setIsDark] = useState(false);

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

    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

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

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled
          ? "bg-[#06112c]/95 backdrop-blur-md border-b border-slate-800/80 shadow-lg py-3"
          : "bg-[#071330]/80 backdrop-blur-sm border-b border-white/5 py-4"
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Official Fresh Home Logo */}
          <Logo />

          {/* Desktop Navigation Links */}
          <nav className="hidden md:flex items-center gap-1 lg:gap-2 bg-white/5 border border-white/10 px-4 py-1.5 rounded-full backdrop-blur-md">
            <Link
              href="/"
              onClick={() => setActiveTab("home")}
              className={`px-4 py-1.5 text-xs font-extrabold rounded-full transition-all ${
                activeTab === "home"
                  ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                  : "text-slate-200 hover:text-white hover:bg-white/10"
              }`}
            >
              الرئيسية
            </Link>
            <Link
              href="#services"
              onClick={() => setActiveTab("services")}
              className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
                activeTab === "services"
                  ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                  : "text-slate-200 hover:text-white hover:bg-white/10"
              }`}
            >
              الخدمات
            </Link>
            <Link
              href="#how-it-works"
              onClick={() => setActiveTab("how-it-works")}
              className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
                activeTab === "how-it-works"
                  ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                  : "text-slate-200 hover:text-white hover:bg-white/10"
              }`}
            >
              كيف نعمل
            </Link>
            <Link
              href="/orders"
              onClick={() => setActiveTab("orders")}
              className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
                activeTab === "orders"
                  ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                  : "text-slate-200 hover:text-white hover:bg-white/10"
              }`}
            >
              تتبع طلبك
            </Link>
            <Link
              href="#why-us"
              onClick={() => setActiveTab("why-us")}
              className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
                activeTab === "why-us"
                  ? "bg-[#0091FF] text-white shadow-md shadow-blue-500/30"
                  : "text-slate-200 hover:text-white hover:bg-white/10"
              }`}
            >
              لماذا Fresh Home
            </Link>
          </nav>

          {/* Action Buttons (Left in RTL) */}
          <div className="hidden sm:flex items-center gap-3">
            {/* Theme Toggle Button (Interactive Dark/Light Mode) */}
            <button
              onClick={toggleTheme}
              aria-label="تبديل المظهر النهاري والليلي"
              title={isDark ? "تفعيل الوضع النهاري" : "تفعيل الوضع الليلي"}
              className="p-2.5 rounded-xl text-slate-300 hover:text-white hover:bg-white/10 transition-all border border-white/10 flex items-center justify-center cursor-pointer"
            >
              {isDark ? (
                <Sun className="w-4 h-4 text-amber-400 transition-transform rotate-0 scale-100" />
              ) : (
                <Moon className="w-4 h-4 text-slate-300 transition-transform -rotate-12" />
              )}
            </button>

            {/* Language Dropdown */}
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-white/10 text-slate-200 hover:text-white text-xs font-bold bg-white/5 cursor-pointer">
              <Globe className="w-3.5 h-3.5 text-[#22A5FC]" />
              <span>AR</span>
              <ChevronDown className="w-3 h-3 text-slate-400" />
            </div>

            {/* Primary CTA Book Now Button */}
            <Link
              href="/booking"
              className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black glow-button flex items-center gap-2"
            >
              <span>احجز الآن</span>
            </Link>
          </div>

          {/* Mobile Menu Toggle & Theme Toggle */}
          <div className="flex sm:hidden items-center gap-2">
            <button
              onClick={toggleTheme}
              aria-label="تبديل المظهر"
              className="p-2 rounded-lg text-slate-300 hover:text-white bg-white/10"
            >
              {isDark ? (
                <Sun className="w-4 h-4 text-amber-400" />
              ) : (
                <Moon className="w-4 h-4 text-slate-300" />
              )}
            </button>
            <Link
              href="/booking"
              className="px-3.5 py-1.5 rounded-lg bg-[#0091FF] text-white text-xs font-bold"
            >
              احجز
            </Link>
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="p-2 rounded-lg text-slate-300 hover:text-white bg-white/10"
              aria-label="القائمة"
            >
              {isOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Drawer Menu */}
      {isOpen && (
        <div className="sm:hidden bg-[#06112c] border-b border-slate-800 px-4 pt-3 pb-6 space-y-2 mt-3 animate-fade-in-up">
          <Link
            href="/"
            onClick={() => setIsOpen(false)}
            className="block px-3 py-2 rounded-lg text-sm font-bold text-white bg-white/10"
          >
            الرئيسية
          </Link>
          <Link
            href="#services"
            onClick={() => setIsOpen(false)}
            className="block px-3 py-2 rounded-lg text-sm font-medium text-slate-300 hover:bg-white/5"
          >
            الخدمات
          </Link>
          <Link
            href="#how-it-works"
            onClick={() => setIsOpen(false)}
            className="block px-3 py-2 rounded-lg text-sm font-medium text-slate-300 hover:bg-white/5"
          >
            كيف نعمل
          </Link>
          <Link
            href="/orders"
            onClick={() => setIsOpen(false)}
            className="block px-3 py-2 rounded-lg text-sm font-medium text-slate-300 hover:bg-white/5"
          >
            تتبع طلبك
          </Link>
          <Link
            href="#why-us"
            onClick={() => setIsOpen(false)}
            className="block px-3 py-2 rounded-lg text-sm font-medium text-slate-300 hover:bg-white/5"
          >
            لماذا Fresh Home
          </Link>
          <div className="pt-3 border-t border-white/10 flex items-center justify-between">
            <button
              onClick={toggleTheme}
              className="flex items-center gap-2 text-xs font-bold text-slate-300 bg-white/10 px-3 py-1.5 rounded-lg"
            >
              {isDark ? (
                <>
                  <Sun className="w-4 h-4 text-amber-400" />
                  <span>الوضع النهاري</span>
                </>
              ) : (
                <>
                  <Moon className="w-4 h-4 text-slate-300" />
                  <span>الوضع الليلي</span>
                </>
              )}
            </button>
            <Link
              href="/booking"
              onClick={() => setIsOpen(false)}
              className="px-5 py-2 rounded-lg bg-[#0091FF] text-white text-xs font-extrabold"
            >
              احجز الآن
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
