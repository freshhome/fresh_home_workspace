"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { Mail } from "lucide-react";
import { supabase } from "@/lib/supabase";

const WhatsAppIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg viewBox="0 0 24 24" fill="currentColor" {...props}>
    <path d="M12.012 2c-5.506 0-9.989 4.478-9.99 9.984a9.96 9.96 0 001.37 5.054L2 22l5.13-1.346a9.921 9.921 0 004.882 1.28h.005c5.507 0 9.99-4.479 9.99-9.986C22.007 6.478 17.518 2 12.012 2zm6.09 13.982c-.268.76-1.531 1.393-2.13 1.462-.599.07-1.192.327-3.834-.72-2.641-1.047-4.329-3.73-4.462-3.907-.133-.177-1.082-1.442-1.082-2.75 0-1.307.683-1.95.927-2.215.244-.265.532-.332.71-.332.177 0 .354.004.51.011.165.008.387-.06.608.48.221.54.757 1.848.823 1.98.066.133.11.288.022.464-.088.177-.133.288-.266.442-.133.155-.28.346-.4.496-.133.167-.277.348-.12.62.156.27.691 1.139 1.482 1.842.92.818 1.693 1.07 1.936 1.193.244.122.388.106.532-.06.144-.167.62-.72.787-.962.167-.243.332-.2.554-.117.221.083 1.405.663 1.649.785.244.122.409.182.469.288.06.106.06.612-.208 1.372z"/>
  </svg>
);

export default function Footer() {
  const [whatsappNumber, setWhatsappNumber] = useState("+201000000000");

  useEffect(() => {
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
        console.error("Error fetching whatsapp settings in footer:", err);
      }
    }

    fetchWhatsappSettings();
  }, []);

  return (
    <footer className="bg-slate-900 text-slate-300 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Logo & Intro */}
          <div className="space-y-4 col-span-1 md:col-span-2">
            <div className="flex items-center gap-3">
              <img 
                src="/app_icon_customer.png" 
                alt="فريش هوم" 
                className="w-10 h-10 object-contain rounded-xl shadow-md" 
              />
              <div>
                <span className="text-xl font-black text-white tracking-tight">فريش هوم</span>
                <span className="block text-[9px] text-secondary font-bold -mt-1 tracking-wider uppercase">Fresh Home</span>
              </div>
            </div>
            <p className="text-sm text-slate-400 max-w-sm leading-relaxed">
              فريش هوم منصة متخصصة لتسهيل حجز الخدمات المنزلية، وتوفر خدمات التنظيف، الصيانة، ومكافحة الحشرات من خلال تجربة حجز بسيطة، وتسعير واضح، ومتابعة مستمرة للطلبات.
            </p>
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
                <a 
                  href={`https://wa.me/${whatsappNumber.replace(/\+/g, "")}`} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-start gap-2.5 group hover:text-emerald-400 transition-colors"
                >
                  <WhatsAppIcon className="w-4 h-4 text-secondary shrink-0 mt-0.5 group-hover:text-emerald-400" />
                  <div>
                    <span className="block font-bold text-white group-hover:text-emerald-400">التواصل عبر الواتساب</span>
                    <span 
                      className="text-xs text-slate-400 group-hover:text-slate-200 inline-block mt-0.5"
                      style={{ direction: "ltr" }}
                    >
                      {whatsappNumber}
                    </span>
                    <span className="block text-[10px] text-slate-500 mt-1">يسعدنا الرد على استفساراتكم خلال ساعات العمل</span>
                  </div>
                </a>
              </li>
              <li className="flex items-center gap-2.5">
                <Mail className="w-4 h-4 text-secondary shrink-0" />
                <span>support@freshhome.com.eg</span>
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
