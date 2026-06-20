"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X, Shield, Phone, Calendar } from "lucide-react";

export default function Header() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-slate-100 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-white shadow-md shadow-primary/20">
                <Shield className="w-6 h-6 stroke-[2.5]" />
              </div>
              <div>
                <span className="text-xl font-black text-primary tracking-tight font-sans">فريش هوم</span>
                <span className="block text-[9px] text-secondary font-bold -mt-1 tracking-wider uppercase">Fresh Home</span>
              </div>
            </Link>
          </div>

          {/* Desktop Nav */}
          <nav className="hidden md:flex items-center gap-8 font-medium text-slate-600">
            <Link href="/" className="hover:text-primary transition-colors py-2 text-primary font-bold">الرئيسية</Link>
            <Link href="#services" className="hover:text-primary transition-colors py-2">خدماتنا</Link>
            <Link href="#trust" className="hover:text-primary transition-colors py-2">لماذا نحن؟</Link>
            <Link href="/orders" className="hover:text-primary transition-colors py-2 flex items-center gap-1.5">
              <span>تتبع الطلبات</span>
              <span className="bg-emerald-50 text-secondary text-[10px] font-bold px-2 py-0.5 rounded-full border border-emerald-100">نشط</span>
            </Link>
          </nav>

          {/* Action CTAs */}
          <div className="hidden md:flex items-center gap-4">
            <a href="tel:19999" className="flex items-center gap-1.5 text-slate-500 hover:text-primary transition-colors text-sm font-semibold">
              <Phone className="w-4 h-4 text-secondary" />
              <span>الخط الساخن: 19999</span>
            </a>
            <Link 
              href="/booking" 
              className="flex items-center gap-2 bg-primary hover:bg-primary/95 text-white font-bold px-5 py-2.5 rounded-xl transition-all shadow-lg shadow-primary/20 transform hover:-translate-y-0.5 active:translate-y-0 text-sm"
            >
              <Calendar className="w-4 h-4" />
              <span>احجز الآن</span>
            </Link>
          </div>

          {/* Mobile Menu Toggle */}
          <div className="md:hidden">
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
        <div className="md:hidden border-t border-slate-100 bg-white px-4 pt-2 pb-6 space-y-3 shadow-inner">
          <Link 
            href="/" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-bold transition-all"
            onClick={() => setIsOpen(false)}
          >
            الرئيسية
          </Link>
          <Link 
            href="#services" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-medium transition-all"
            onClick={() => setIsOpen(false)}
          >
            خدماتنا
          </Link>
          <Link 
            href="#trust" 
            className="block px-3 py-2.5 rounded-xl text-slate-700 hover:bg-slate-50 hover:text-primary font-medium transition-all"
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
          <div className="pt-4 border-t border-slate-100 flex flex-col gap-3">
            <a href="tel:19999" className="flex items-center justify-center gap-1.5 text-slate-600 py-2.5 text-sm font-bold">
              <Phone className="w-4 h-4 text-secondary" />
              <span>الخط الساخن: 19999</span>
            </a>
            <Link 
              href="/booking" 
              className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/95 text-white font-bold py-3 rounded-xl text-center shadow-lg shadow-primary/10"
              onClick={() => setIsOpen(false)}
            >
              <Calendar className="w-4 h-4" />
              <span>احجز الآن كضيف</span>
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
