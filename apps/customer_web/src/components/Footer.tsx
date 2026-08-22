"use client";

import Link from "next/link";
import Logo from "@/components/Logo";

export default function Footer() {
  return (
    <footer className="bg-[#030919] text-slate-400 border-t border-slate-900 pt-16 pb-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10 pb-12 border-b border-slate-800/80 text-right">
          {/* Col 1: Brand & Bio */}
          <div className="space-y-4">
            <Logo size="md" />

            <p className="text-xs text-slate-400 leading-relaxed font-normal">
              خدمات تنظيف، وصيانة، ومكافحة حشرات احترافية توصلك لحد باب بيتك بأعلى معايير الأمان والجودة.
            </p>

            {/* Social Icons (TikTok, Instagram, Facebook) */}
            <div className="flex items-center gap-3 pt-2">
              <a
                href="#"
                className="w-8 h-8 rounded-lg bg-white/5 hover:bg-white/15 text-slate-300 hover:text-white flex items-center justify-center transition-colors text-xs font-bold"
                aria-label="Facebook"
              >
                f
              </a>
              <a
                href="#"
                className="w-8 h-8 rounded-lg bg-white/5 hover:bg-white/15 text-slate-300 hover:text-white flex items-center justify-center transition-colors text-xs font-bold"
                aria-label="Instagram"
              >
                ig
              </a>
              <a
                href="#"
                className="w-8 h-8 rounded-lg bg-white/5 hover:bg-white/15 text-slate-300 hover:text-white flex items-center justify-center transition-colors text-xs font-bold"
                aria-label="TikTok"
              >
                tk
              </a>
            </div>
          </div>

          {/* Col 2: Quick Links */}
          <div>
            <h4 className="text-white font-extrabold text-sm mb-4">روابط سريعة</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/" className="hover:text-white transition-colors">الرئيسية</Link>
              </li>
              <li>
                <Link href="#services" className="hover:text-white transition-colors">الخدمات</Link>
              </li>
              <li>
                <Link href="#how-it-works" className="hover:text-white transition-colors">كيف نعمل</Link>
              </li>
              <li>
                <Link href="/orders" className="hover:text-white transition-colors">تتبع طلبك</Link>
              </li>
              <li>
                <Link href="#why-us" className="hover:text-white transition-colors">لماذا Fresh Home</Link>
              </li>
            </ul>
          </div>

          {/* Col 3: Services */}
          <div>
            <h4 className="text-white font-extrabold text-sm mb-4">خدماتنا</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/booking" className="hover:text-white transition-colors">تنظيف بعد التشطيب</Link>
              </li>
              <li>
                <Link href="/booking" className="hover:text-white transition-colors">التنظيف العميق</Link>
              </li>
              <li>
                <Link href="/booking" className="hover:text-white transition-colors">التنظيف الدوري</Link>
              </li>
              <li>
                <Link href="/booking" className="hover:text-white transition-colors">تنظيف الأثاث والمفروشات</Link>
              </li>
              <li>
                <Link href="/booking" className="hover:text-white transition-colors">صيانة التكييف</Link>
              </li>
              <li>
                <Link href="#services" className="text-[#22A5FC] hover:underline font-bold">عرض كل الخدمات</Link>
              </li>
            </ul>
          </div>

          {/* Col 4: Info & Support */}
          <div>
            <h4 className="text-white font-extrabold text-sm mb-4">معلومات</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/orders" className="hover:text-white transition-colors">تتبع طلبك</Link>
              </li>
              <li>
                <Link href="#faq" className="hover:text-white transition-colors">الأسئلة الشائعة</Link>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">شروط الخدمة والخصوصية</a>
              </li>
              <li>
                <a href="https://wa.me/201000000000" className="hover:text-white transition-colors">تواصل معنا والاستفسار</a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Copyright */}
        <div className="pt-8 text-center text-xs text-slate-500 font-medium">
          © 2026 Fresh Home. جميع الحقوق محفوظة.
        </div>
      </div>
    </footer>
  );
}
