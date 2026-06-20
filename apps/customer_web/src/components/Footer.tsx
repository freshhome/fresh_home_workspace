import Link from "next/link";
import { Shield, Phone, Mail, MapPin, CheckCircle } from "lucide-react";

export default function Footer() {
  return (
    <footer className="bg-slate-900 text-slate-300 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Logo & Intro */}
          <div className="space-y-4 col-span-1 md:col-span-2">
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-white">
                <Shield className="w-6 h-6 stroke-[2.5]" />
              </div>
              <div>
                <span className="text-xl font-black text-white tracking-tight">فريش هوم</span>
                <span className="block text-[9px] text-secondary font-bold -mt-1 tracking-wider uppercase">Fresh Home</span>
              </div>
            </div>
            <p className="text-sm text-slate-400 max-w-sm leading-relaxed">
              فريش هوم هي منصة الخدمات المنزلية الرائدة في مصر. نوفر باقة متكاملة من خدمات التنظيف، مكافحة الحشرات، والصيانة بأعلى معايير الأمان والجودة وبأسعار عادلة ومحسوبة بدقة.
            </p>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <CheckCircle className="w-4 h-4 text-secondary shrink-0" />
              <span>فنيون خاضعون للبحث الجنائي والمراجعة الأمنية الكاملة.</span>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-white font-bold text-base mb-4">روابط سريعة</h3>
            <ul className="space-y-2.5 text-sm">
              <li>
                <Link href="/" className="hover:text-white transition-colors">الرئيسية</Link>
              </li>
              <li>
                <Link href="#services" className="hover:text-white transition-colors">خدماتنا</Link>
              </li>
              <li>
                <Link href="#trust" className="hover:text-white transition-colors">لماذا فريش هوم؟</Link>
              </li>
              <li>
                <Link href="/orders" className="hover:text-white transition-colors">تتبع الطلبات كضيف</Link>
              </li>
              <li>
                <Link href="/booking" className="hover:text-white transition-colors font-bold text-secondary">احجز خدمة الآن</Link>
              </li>
            </ul>
          </div>

          {/* Contact Details */}
          <div>
            <h3 className="text-white font-bold text-base mb-4">اتصل بنا</h3>
            <ul className="space-y-3.5 text-sm">
              <li className="flex items-start gap-2.5">
                <Phone className="w-4 h-4 text-secondary shrink-0 mt-0.5" />
                <div>
                  <span className="block font-bold text-white">الخط الساخن: 19999</span>
                  <span className="text-xs text-slate-500">متاح طوال الـ 24 ساعة للرد على استفساراتكم</span>
                </div>
              </li>
              <li className="flex items-center gap-2.5">
                <Mail className="w-4 h-4 text-secondary shrink-0" />
                <span>support@freshhome.com.eg</span>
              </li>
              <li className="flex items-start gap-2.5">
                <MapPin className="w-4 h-4 text-secondary shrink-0 mt-0.5" />
                <span>المعادي، القاهرة، جمهورية مصر العربية</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom copyright */}
        <div className="mt-12 pt-8 border-t border-slate-800 flex flex-col md:flex-row justify-between items-center gap-4 text-xs text-slate-500">
          <p>© {new Date().getFullYear()} فريش هوم للخدمات المنزلية. جميع الحقوق محفوظة.</p>
          <div className="flex gap-4">
            <a href="#" className="hover:text-white transition-colors">الشروط والأحكام</a>
            <span>•</span>
            <a href="#" className="hover:text-white transition-colors">سياسة الخصوصية</a>
            <span>•</span>
            <a href="#" className="hover:text-white transition-colors">سياسة الإلغاء والاسترداد</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
