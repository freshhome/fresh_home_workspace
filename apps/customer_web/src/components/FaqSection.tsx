"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";

interface FaqItem {
  question: string;
  answer: string;
}

const faqs: FaqItem[] = [
  {
    question: "ما الخدمات التي تقدمها Fresh Home؟",
    answer:
      "نقدم باقة متكاملة من الخدمات المنزلية تشمل: تنظيف ما بعد التشطيب، التنظيف العميق، التنظيف الدوري، غسيل الأثاث والمفروشات بالبخار، صيانة وغسيل التكييفات، السباكة، الكهرباء، ومكافحة وإبادة الحشرات.",
  },
  {
    question: "كيف يتم حساب السعر؟",
    answer:
      "يتم حساب السعر بدقة وشفافية وفق محرك تسعير ذكي يعتمد على مدخلاتك الحقيقية (المساحة بالمتر، عدد الغرف والحمامات، أو نوع القطع المطلوبة) دون أي رسوم إضافية مخفية.",
  },
  {
    question: "هل أحتاج لإنشاء حساب للحجز؟",
    answer:
      "لا، يمكنك الحجز مباشرة كزائر (Guest Checkout) بإدخال رقم هاتفك واسمك فقط، وسيتم تأكيد حجزك ومتابعته عبر رسائل الواتساب والتطبيق بكل سهولة.",
  },
  {
    question: "هل يمكنني اختيار الموعد المناسب؟",
    answer:
      "بالتأكيد، يوفر نظام الحجز تقويمًا متكاملًا يتيح لك اختيار اليوم والفترة الزمنية المتاحة (صباحية أو مسائية) الأنسب لجدولك اليومي.",
  },
  {
    question: "كيف يتم تنفيذ الحجز؟",
    answer:
      "فور تأكيد الحجز، يتم تعيين فني محترف ومعتمد يصلك في الموعد المحدد ومعه كافة المعدات والمواد المخصصة لتنفيذ الخدمة بأعلى معايير الجودة.",
  },
  {
    question: "ما المناطق التي تخدمها Fresh Home؟",
    answer:
      "نخدم حاليًا كافة أحياء ومناطق محافظتي القاهرة والجيزة (التجمع، المعادي، مصر الجديدة، الشيخ زايد، 6 أكتوبر، وغيرها) ونتوسع تدريجيًا لباقي المحافظات.",
  },
];

export default function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggleFaq = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <section className="py-20 bg-[#07132F] text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Left Side: 3D Glowing Question Mark & Chair Illustration */}
          <div className="lg:col-span-5 flex justify-center order-2 lg:order-1">
            <div className="relative rounded-3xl overflow-hidden shadow-2xl border border-white/10 max-w-sm group">
              <img
                src="/images/faq_glow_chair.jpg"
                alt="أسئلة شائعة Fresh Home"
                className="w-full h-auto object-cover group-hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#07132F] via-transparent to-transparent opacity-60" />
            </div>
          </div>

          {/* Right Side: FAQ Accordion */}
          <div className="lg:col-span-7 text-right order-1 lg:order-2 space-y-6">
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              أسئلة شائعة
            </h2>

            <div className="space-y-3">
              {faqs.map((faq, idx) => {
                const isOpen = openIndex === idx;

                return (
                  <div
                    key={idx}
                    className="rounded-2xl bg-[#0C1E4A]/80 border border-blue-900/50 overflow-hidden transition-all"
                  >
                    <button
                      onClick={() => toggleFaq(idx)}
                      className="w-full p-4 sm:p-5 flex items-center justify-between text-right gap-4 hover:bg-white/5 transition-colors"
                      aria-expanded={isOpen}
                    >
                      <span className="text-xs sm:text-sm font-extrabold text-slate-100">
                        {faq.question}
                      </span>
                      <ChevronDown
                        className={`w-4 h-4 text-[#22A5FC] shrink-0 transition-transform duration-300 ${
                          isOpen ? "rotate-180" : ""
                        }`}
                      />
                    </button>

                    {isOpen && (
                      <div className="px-5 pb-5 text-xs text-slate-300 leading-relaxed font-normal border-t border-white/5 pt-3 animate-fade-in-up">
                        {faq.answer}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
