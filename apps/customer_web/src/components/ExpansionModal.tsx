"use client";

import { useState } from "react";
import { X, MapPin, Phone, Send, CheckCircle2, Loader2, Sparkles } from "lucide-react";
import { supabase } from "@/lib/supabase";

interface ExpansionModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialGovernorate?: string;
  initialCity?: string;
}

const POPULAR_EXPANSION_GOVERNORATES = [
  "الإسكندرية",
  "الشرقية",
  "الدقهلية",
  "القليوبية",
  "الغربية",
  "المنوفية",
  "البحيرة",
  "دمياط",
  "بورسعيد",
  "الإسماعيلية",
  "السويس",
  "البحر الأحمر",
  "جنوب سيناء",
  "بني سويف",
  "الفيوم",
  "المنيا",
  "أسيوط",
  "سوهاج",
  "محافظة أخرى"
];

export default function ExpansionModal({
  isOpen,
  onClose,
  initialGovernorate = "",
  initialCity = ""
}: ExpansionModalProps) {
  const [phone, setPhone] = useState("");
  const [governorate, setGovernorate] = useState(initialGovernorate || "الإسكندرية");
  const [customGov, setCustomGov] = useState("");
  const [city, setCity] = useState(initialCity || "");
  const [notes, setNotes] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");

    const cleanPhone = phone.trim();
    const phoneRegex = /^(010|011|012|015)\d{8}$/;
    if (!phoneRegex.test(cleanPhone)) {
      setErrorMsg("يرجى إدخال رقم هاتف مصري صحيح (11 رقم يبدأ بـ 010، 011، 012، أو 015)");
      return;
    }

    const finalGov = governorate === "محافظة أخرى" ? customGov.trim() : governorate.trim();
    if (!finalGov) {
      setErrorMsg("يرجى تحديد المحافظة أو كتابتها");
      return;
    }

    setIsSubmitting(true);
    try {
      const { error } = await supabase.from("service_expansion_leads").insert({
        phone_number: cleanPhone,
        governorate: finalGov,
        city: city.trim() || null,
        notes: notes.trim() || null,
        source: "booking_out_of_coverage"
      });

      if (error) throw error;
      setIsSuccess(true);
    } catch (err: any) {
      console.error("Error submitting expansion lead:", err);
      setErrorMsg("تعذر إرسال الطلب حالياً، يرجى المحاولة مرة أخرى لاحقاً.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleResetAndClose = () => {
    setIsSuccess(false);
    setErrorMsg("");
    setPhone("");
    setCity("");
    setNotes("");
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fadeIn">
      <div 
        className="relative w-full max-w-lg bg-white dark:bg-[#071739] border border-slate-200 dark:border-blue-900/60 rounded-3xl shadow-2xl overflow-hidden transition-all text-right"
        dir="rtl"
      >
        {/* Close Button */}
        <button
          onClick={handleResetAndClose}
          aria-label="إغلاق"
          className="absolute top-4 left-4 p-2 rounded-full text-slate-400 hover:text-slate-700 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors z-10 cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {isSuccess ? (
          <div className="p-8 sm:p-10 text-center space-y-4">
            <div className="w-16 h-16 bg-emerald-50 dark:bg-emerald-950/60 text-emerald-500 rounded-2xl flex items-center justify-center mx-auto border border-emerald-200 dark:border-emerald-900/50 shadow-sm">
              <CheckCircle2 className="w-10 h-10 stroke-[2.5]" />
            </div>
            <h3 className="text-xl font-black text-slate-900 dark:text-white">
              تم تسجيل رغبتك بنجاح! ✨
            </h3>
            <p className="text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed font-medium">
              شكراً لاهتمامك بخدمات فريش هوم. سنكون أول من يتواصل معك عبر الواتساب فور توفر الخدمة في منطقتك، مع إتاحة خصم ترحيبي خاص 🎁
            </p>
            <div className="pt-3">
              <button
                onClick={handleResetAndClose}
                className="w-full py-3 px-6 rounded-xl bg-[#21A5FB] hover:bg-[#1b8cd5] text-white font-black text-xs shadow-md transition-all cursor-pointer"
              >
                حسناً، فهمت
              </button>
            </div>
          </div>
        ) : (
          <div className="p-6 sm:p-8 space-y-5">
            {/* Header */}
            <div className="space-y-1.5">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900/40 text-[#21A5FB] text-[11px] font-black">
                <Sparkles className="w-3.5 h-3.5" />
                <span>خطة التوسع الجغرافي</span>
              </div>
              <h3 className="text-lg sm:text-xl font-black text-slate-900 dark:text-white">
                أخبرنا بأين تريد الخدمة 🚀
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed">
                خدماتنا تغطي حالياً القاهرة والجيزة. سجّل مدينتك ورقمك لنخطرك فور وصول فنيينا إلى منطقتك.
              </p>
            </div>

            {errorMsg && (
              <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900/50 text-rose-600 dark:text-rose-400 text-xs font-bold">
                {errorMsg}
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Phone */}
              <div className="space-y-1.5">
                <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                  رقم الهاتف (الواتساب) <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type="tel"
                    required
                    placeholder="مثال: 01012345678"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full p-2.5 sm:p-3 pl-10 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#050D24] text-slate-900 dark:text-white text-xs font-bold focus:border-[#21A5FB] focus:outline-none"
                  />
                  <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                    <Phone className="w-4 h-4" />
                  </div>
                </div>
              </div>

              {/* Governorate Selection */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                    المحافظة <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={governorate}
                    onChange={(e) => setGovernorate(e.target.value)}
                    className="w-full p-2.5 sm:p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#050D24] text-slate-900 dark:text-white text-xs font-bold focus:border-[#21A5FB] focus:outline-none cursor-pointer"
                  >
                    {POPULAR_EXPANSION_GOVERNORATES.map((gov) => (
                      <option key={gov} value={gov}>
                        {gov}
                      </option>
                    ))}
                  </select>
                </div>

                {/* City */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                    المدينة / المنطقة
                  </label>
                  <div className="relative">
                    <input
                      type="text"
                      placeholder="مثال: سموحة / طنطا / الزقازيق"
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      className="w-full p-2.5 sm:p-3 pl-10 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#050D24] text-slate-900 dark:text-white text-xs font-bold focus:border-[#21A5FB] focus:outline-none"
                    />
                    <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                      <MapPin className="w-4 h-4" />
                    </div>
                  </div>
                </div>
              </div>

              {governorate === "محافظة أخرى" && (
                <div className="space-y-1.5">
                  <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                    اكتب اسم المحافظة
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="اكتب اسم محافظتك بالتفصيل..."
                    value={customGov}
                    onChange={(e) => setCustomGov(e.target.value)}
                    className="w-full p-2.5 sm:p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#050D24] text-slate-900 dark:text-white text-xs font-bold focus:border-[#21A5FB] focus:outline-none"
                  />
                </div>
              )}

              {/* Notes / Desired Service */}
              <div className="space-y-1.5">
                <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                  الخدمة المطلوبة أو ملاحظات (اختياري)
                </label>
                <input
                  type="text"
                  placeholder="مثال: تنظيف بعد التشطيب / مكافحة حشرات"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full p-2.5 sm:p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#050D24] text-slate-900 dark:text-white text-xs font-bold focus:border-[#21A5FB] focus:outline-none"
                />
              </div>

              {/* Submit */}
              <div className="pt-2">
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full py-3 px-6 rounded-xl bg-[#21A5FB] hover:bg-[#1b8cd5] text-white font-black text-xs shadow-md shadow-blue-500/20 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span>جاري الحفظ...</span>
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      <span>أبلغوني فور التوسع</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        )}
      </div>
    </div>
  );
}
