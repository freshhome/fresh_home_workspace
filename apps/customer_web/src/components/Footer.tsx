"use client";

import Link from "next/link";
import Logo from "@/components/Logo";
import { useWhatsAppSettings } from "@/lib/whatsapp";

export default function Footer() {
  const { getUrl } = useWhatsAppSettings();

  return (
    <footer className="bg-slate-50 dark:bg-[#030919] text-slate-600 dark:text-slate-400 border-t border-slate-200 dark:border-slate-900 pt-16 pb-8 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10 pb-12 border-b border-slate-200 dark:border-slate-800/80 text-right">
          {/* Col 1: Brand & Bio */}
          <div className="space-y-4">
            <Logo size="md" />

            <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed font-normal">
              خدمات تنظيف، وصيانة، ومكافحة حشرات احترافية توصلك لحد باب بيتك بأعلى معايير الأمان والجودة.
            </p>

            {/* Social Media Channels */}
            <div className="pt-2">
              <span className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-2.5">
                تابعنا على منصات التواصل:
              </span>
              <div className="flex items-center gap-2.5">
                {/* Facebook */}
                <a
                  href="https://www.facebook.com/share/1BoRCz8Rfh/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-9 h-9 rounded-xl bg-white dark:bg-white/5 border border-slate-200 dark:border-slate-800 hover:bg-[#1877F2] hover:border-[#1877F2] hover:text-white text-slate-600 dark:text-slate-300 flex items-center justify-center transition-all duration-200 shadow-2xs hover:scale-105 group"
                  aria-label="Fresh Home Facebook"
                  title="صفحة فيسبوك الرسمية"
                >
                  <svg className="w-4 h-4 fill-current group-hover:scale-110 transition-transform" viewBox="0 0 24 24">
                    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                  </svg>
                </a>

                {/* Instagram */}
                <a
                  href="https://www.instagram.com/fresh_home.eg?igsi=MTYyM2k2YWI4MmdmbQ=="
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-9 h-9 rounded-xl bg-white dark:bg-white/5 border border-slate-200 dark:border-slate-800 hover:bg-gradient-to-tr hover:from-[#f09433] hover:via-[#dc2743] hover:to-[#bc1888] hover:border-transparent hover:text-white text-slate-600 dark:text-slate-300 flex items-center justify-center transition-all duration-200 shadow-2xs hover:scale-105 group"
                  aria-label="Fresh Home Instagram"
                  title="حساب إنستغرام الرسمي"
                >
                  <svg className="w-4 h-4 fill-current group-hover:scale-110 transition-transform" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                  </svg>
                </a>

                {/* TikTok */}
                <a
                  href="https://www.tiktok.com/@_fresh.home?_r=1&_t=ZS-997mdjnaW1w"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-9 h-9 rounded-xl bg-white dark:bg-white/5 border border-slate-200 dark:border-slate-800 hover:bg-[#000000] dark:hover:bg-slate-800 hover:border-slate-900 hover:text-white text-slate-600 dark:text-slate-300 flex items-center justify-center transition-all duration-200 shadow-2xs hover:scale-105 group"
                  aria-label="Fresh Home TikTok"
                  title="حساب تيك توك الرسمي"
                >
                  <svg className="w-4 h-4 fill-current group-hover:scale-110 transition-transform" viewBox="0 0 24 24">
                    <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.24 1.07-.14 1.61.24 1.64 1.82 2.89 3.5 2.72 1.43-.06 2.7-1.07 3.08-2.45.16-.54.21-1.11.21-1.68V.02z"/>
                  </svg>
                </a>

                {/* WhatsApp */}
                <a
                  href={getUrl("مرحباً فريش هوم، أود الاستفسار والتواصل بخصوص الخدمات.")}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-9 h-9 rounded-xl bg-white dark:bg-white/5 border border-slate-200 dark:border-slate-800 hover:bg-[#25D366] hover:border-[#25D366] hover:text-white text-slate-600 dark:text-slate-300 flex items-center justify-center transition-all duration-200 shadow-2xs hover:scale-105 group"
                  aria-label="Fresh Home WhatsApp"
                  title="محادثة واتساب الرسمية"
                >
                  <svg className="w-4 h-4 fill-current group-hover:scale-110 transition-transform" viewBox="0 0 24 24">
                    <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/>
                  </svg>
                </a>
              </div>
            </div>
          </div>

          {/* Col 2: Quick Links */}
          <div>
            <h4 className="text-slate-900 dark:text-white font-extrabold text-sm mb-4">روابط سريعة</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">الرئيسية</Link>
              </li>
              <li>
                <Link href="/#services" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">الخدمات</Link>
              </li>
              <li>
                <Link href="/#how-it-works" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">كيف نعمل</Link>
              </li>
              <li>
                <Link href="/orders" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">طلباتي</Link>
              </li>
              <li>
                <Link href="/#why-us" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">لماذا Fresh Home</Link>
              </li>
            </ul>
          </div>

          {/* Col 3: Services */}
          <div>
            <h4 className="text-slate-900 dark:text-white font-extrabold text-sm mb-4">خدماتنا</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100009" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">تنظيف بعد التشطيب</Link>
              </li>
              <li>
                <Link href="/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100010" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">التنظيف العميق</Link>
              </li>
              <li>
                <Link href="/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100012" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">التنظيف الدوري</Link>
              </li>
              <li>
                <Link href="/services/details?serviceId=FH-S-100001&subServiceId=FH-S-100011" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">تنظيف الأثاث والمفروشات</Link>
              </li>
              <li>
                <Link href="/services/details?serviceId=FH-S-100002&subServiceId=FH-S-100020" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">صيانة التكييف</Link>
              </li>
              <li>
                <Link href="/#services" className="text-[#0091FF] dark:text-[#22A5FC] hover:underline font-bold">عرض كل الخدمات</Link>
              </li>
            </ul>
          </div>

          {/* Col 4: Info & Support */}
          <div>
            <h4 className="text-slate-900 dark:text-white font-extrabold text-sm mb-4">معلومات وتواصل</h4>
            <ul className="space-y-2.5 text-xs font-medium">
              <li>
                <Link href="/orders" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">تتبع الطلبات</Link>
              </li>
              <li>
                <Link href="/#faq" className="text-slate-600 dark:text-slate-400 hover:text-[#0091FF] dark:hover:text-white transition-colors">الأسئلة الشائعة</Link>
              </li>
              <li>
                <a
                  href={getUrl("مرحباً فريش هوم، أود الاستفسار والتواصل بخصوص الخدمات.")}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-slate-600 dark:text-slate-400 hover:text-[#25D366] transition-colors inline-flex items-center gap-1.5"
                >
                  <span>تواصل معنا عبر واتساب</span>
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Copyright */}
        <div className="pt-8 text-center text-xs text-slate-500 dark:text-slate-400 font-medium">
          © {new Date().getFullYear()} Fresh Home. جميع الحقوق محفوظة.
        </div>
      </div>
    </footer>
  );
}
