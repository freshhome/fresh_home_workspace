import { ShieldAlert, RefreshCw, BadgePercent, Lock } from "lucide-react";

export default function TrustSection() {
  return (
    <section id="trust" className="py-16 bg-slate-50 border-t border-b border-slate-100 scroll-mt-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center max-w-xl mx-auto mb-14 space-y-3">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">لماذا يختار العملاء فريش هوم؟</h2>
          <div className="w-12 h-1 bg-secondary mx-auto rounded-full"></div>
          <p className="text-slate-500 text-sm">
            نسعى لتقديم تجربة حجز سهلة، وتسعير واضح، ومتابعة مستمرة للطلبات، مع الاهتمام بجودة تنفيذ الخدمة في جميع مراحلها.
          </p>
        </div>

        {/* Grid of Trust Factors */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Card 1 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <ShieldAlert className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">التحقق من الفنيين</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              يخضع الفنيون لإجراءات تحقق ومراجعة قبل الانضمام إلى المنصة، لضمان الالتزام بمعايير فريش هوم.
            </p>
          </div>

          {/* Card 2 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <RefreshCw className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">الجودة</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              إذا كانت لديك أي ملاحظات على الخدمة، يعمل فريقنا على مراجعتها والتعامل معها وفق سياسة الجودة الخاصة بفريش هوم.
            </p>
          </div>

          {/* Card 3 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <Lock className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">سلامة المنزل</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              نحرص على تنفيذ الخدمات بعناية للمساعدة في الحفاظ على سلامة منزلك ومحتوياته أثناء العمل.
            </p>
          </div>

          {/* Card 4 */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl mx-auto">
              <BadgePercent className="w-6 h-6 stroke-[2]" />
            </div>
            <h3 className="font-extrabold text-slate-800 text-base">الأسعار</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              يعتمد تسعير الخدمات على البيانات التي تدخلها أثناء الحجز، ويتم مراجعة أي اختلافات قبل بدء التنفيذ عند الحاجة.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
