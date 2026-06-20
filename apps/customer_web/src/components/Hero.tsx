import Link from "next/link";
import { ShieldCheck, Sparkles, Check, ChevronLeft, ArrowRight } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-primary via-primary/95 to-slate-900 text-white py-20 lg:py-28">
      {/* Background decoration elements */}
      <div className="absolute top-0 right-0 w-96 h-96 rounded-full bg-secondary/10 blur-3xl -mr-20 -mt-20"></div>
      <div className="absolute bottom-0 left-0 w-96 h-96 rounded-full bg-blue-500/10 blur-3xl -ml-20 -mb-20"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Main Info */}
          <div className="lg:col-span-7 space-y-6 text-center lg:text-right">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/10 backdrop-blur-md border border-white/10 text-xs font-bold text-secondary">
              <Sparkles className="w-3.5 h-3.5" />
              <span>خدمات صيانة وتنظيف منزلية بضمان الجودة في مصر</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black leading-tight sm:leading-tight lg:leading-none tracking-tight">
              منزلك في أيدٍ أمينة مع محترفي <span className="text-secondary">فريش هوم</span>
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 max-w-xl mx-auto lg:mx-0 leading-relaxed font-light">
              احجز خدمات التنظيف العميق، مكافحة الآفات، وصيانة التكييفات والسباكة في دقائق معدودة. احصل على تسعير فوري ودقيق دون مفاجآت وبدون اشتراط تسجيل الدخول المسبق.
            </p>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start pt-2">
              <Link 
                href="/booking" 
                className="flex items-center justify-center gap-2 bg-secondary hover:bg-secondary/95 text-slate-900 font-extrabold px-8 py-3.5 rounded-xl transition-all shadow-lg shadow-secondary/20 transform hover:-translate-y-0.5"
              >
                <span>احجز خدمة الآن كضيف</span>
                <ChevronLeft className="w-5 h-5 stroke-[2.5]" />
              </Link>
              <Link 
                href="#services" 
                className="flex items-center justify-center gap-2 bg-white/10 hover:bg-white/15 text-white font-bold px-8 py-3.5 rounded-xl transition-all border border-white/10"
              >
                <span>تصفح الخدمات</span>
              </Link>
            </div>

            {/* Key Trust Factors */}
            <div className="grid grid-cols-3 gap-4 pt-8 border-t border-white/10 max-w-md mx-auto lg:mx-0">
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">100%</span>
                <span className="text-xs text-slate-300">أمان وموثوقية</span>
              </div>
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">30 يوم</span>
                <span className="text-xs text-slate-300">ضمان على الصيانة</span>
              </div>
              <div className="flex flex-col items-center lg:items-start gap-1">
                <span className="text-secondary font-black text-xl">فوري</span>
                <span className="text-xs text-slate-300">تسعير ديناميكي</span>
              </div>
            </div>
          </div>

          {/* Graphical showcase (Visual Trust Element) */}
          <div className="lg:col-span-5 hidden lg:flex justify-center">
            <div className="relative w-80 h-96 rounded-3xl bg-slate-800/80 border border-slate-700/50 p-6 shadow-2xl flex flex-col justify-between overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-primary/20 rounded-full blur-2xl"></div>
              
              {/* Fake app card header */}
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-4">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-secondary/20 flex items-center justify-center text-secondary">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="text-xs font-bold block text-white">فريش هوم جارانتي</span>
                    <span className="text-[8px] text-slate-400 block -mt-0.5">Fresh Home Guarantee</span>
                  </div>
                </div>
                <span className="bg-emerald-500/20 text-emerald-400 text-[9px] font-bold px-2 py-0.5 rounded-full">نشط</span>
              </div>

              {/* Trust list items */}
              <div className="space-y-4 my-8">
                <div className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                  <p className="text-xs text-slate-300 leading-relaxed">
                    <strong>فحص الحالة الجنائية:</strong> جميع الفنيين يخضعون للتحريات والفيش والتشبيه الفعلي.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                  <p className="text-xs text-slate-300 leading-relaxed">
                    <strong>تدريب عملي صارم:</strong> فنيونا مؤهلون وحاصلون على تقييمات نجاح تتعدى 4.8★.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                  <p className="text-xs text-slate-300 leading-relaxed">
                    <strong>التأمين ضد الأضرار:</strong> المنصة مأمنة بالكامل لحماية منزلك ومقتنياتك.
                  </p>
                </div>
              </div>

              {/* Fake app card footer */}
              <div className="bg-slate-750 border border-slate-700/60 rounded-xl p-3.5 flex items-center justify-between text-xs">
                <div>
                  <span className="text-slate-400 block text-[9px]">متوسط الأسعار يبدأ من</span>
                  <span className="text-white font-extrabold text-sm block">150 ج.م</span>
                </div>
                <Link 
                  href="/booking" 
                  className="bg-primary hover:bg-primary/95 text-white font-bold px-3 py-2 rounded-lg text-[10px] flex items-center gap-1"
                >
                  <span>اطلب الآن</span>
                  <ArrowRight className="w-3.5 h-3.5 rotate-180" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
