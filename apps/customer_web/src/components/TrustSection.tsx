import { ShieldAlert, RefreshCw, BadgePercent, Lock } from "lucide-react";

export default function TrustSection() {
  return (
    <section id="trust" className="py-16 bg-slate-50 border-t border-b border-slate-100 scroll-mt-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center max-w-xl mx-auto mb-14 space-y-3">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">أمانك وثقتك هما أولويتنا القصوى</h2>
          <div className="w-12 h-1 bg-secondary mx-auto rounded-full"></div>
          <p className="text-slate-500 text-sm">
            بصفتنا منصة متكاملة ولسنا مجرد وسيط، نحن نتحمل المسؤولية الكاملة عن جودة خدماتنا وسلامة منزلك.
          </p>
        </div>

        {/* Grid of Trust Factors */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Card 1 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <ShieldAlert className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">فحص جنائي صارم</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              جميع الفنيين المسجلين يخضعون لفحص صحيفة الحالة الجنائية والفيش والتشبيه الفعلي لضمان أعلى مستويات الأمان لأهلك ومنزلك.
            </p>
          </div>

          {/* Card 2 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <RefreshCw className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">ضمان إعادة العمل مجاناً</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              إذا لم تكن راضياً عن جودة التنظيف أو الصيانة المنجزة، تلتزم فريش هوم بإرسال فني آخر لإعادة العمل بالكامل مجاناً وبدون أي تكلفة.
            </p>
          </div>

          {/* Card 3 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <Lock className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">حماية وأمان الأثاث</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              جميع الزيارات والخدمات مغطاة بضمان مالي وتأمين ضد أي تلفيات أو أضرار غير مقصودة قد تحدث لمقتنيات منزلك أثناء الخدمة.
            </p>
          </div>

          {/* Card 4 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <BadgePercent className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">أسعار عادلة ومثبتة</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              نظام التسعير لدينا مؤتمت بالكامل ولا مجال للفصال أو التغيير عند الباب؛ الأسعار نهائية وتعتمد على المقاسات والخيارات التي حددتها.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
