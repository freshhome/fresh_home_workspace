"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ShieldCheck, CheckCircle2, XCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

function ConfirmBookingContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const id = searchParams.get("id");
  const token = searchParams.get("token");

  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    async function confirmBooking() {
      if (!id || !token) {
        setStatus("error");
        setErrorMessage("رابط التأكيد غير مكتمل. يرجى التأكد من الضغط على الرابط بالكامل كما وصلك في رسالة واتساب.");
        return;
      }

      try {
        const { data, error } = await supabase.rpc("confirm_whatsapp_booking", {
          p_booking_id: id,
          p_token: token
        });

        if (error) throw error;

        if (data === true) {
          setStatus("success");
          // Redirect to tracking page after 3 seconds
          setTimeout(() => {
            router.push(`/orders?bookingId=${id}&success=true`);
          }, 3000);
        } else {
          throw new Error("فشلت عملية التأكيد.");
        }
      } catch (e: any) {
        console.error("WhatsApp confirmation failed:", e);
        setStatus("error");
        setErrorMessage(e.message || "حدث خطأ غير متوقع أثناء تأكيد الحجز. قد يكون الرابط منتهي الصلاحية أو غير صالح.");
      }
    }

    confirmBooking();
  }, [id, token, router]);

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Header />
      
      <main className="flex-1 flex items-center justify-center py-20 px-4">
        <div className="max-w-md w-full bg-white rounded-3xl p-8 border border-slate-100 shadow-xl text-center space-y-6">
          
          {status === "loading" && (
            <div className="space-y-4 py-8">
              <Loader2 className="w-16 h-16 stroke-[1.5] text-primary animate-spin mx-auto" />
              <h2 className="text-lg font-black text-slate-800">جاري تأكيد حجزك...</h2>
              <p className="text-xs text-slate-500">نقوم الآن بالتحقق من رمز التأكيد وتحديث حالة الموعد في فريش هوم.</p>
            </div>
          )}

          {status === "success" && (
            <div className="space-y-4 py-6">
              <div className="w-16 h-16 bg-secondary text-slate-900 rounded-full flex items-center justify-center mx-auto shadow-lg shadow-secondary/20">
                <CheckCircle2 className="w-10 h-10 stroke-[2.5] animate-bounce" />
              </div>
              <h2 className="text-xl font-black text-slate-800">تم تأكيد حجزك بنجاح!</h2>
              <p className="text-xs text-emerald-600 font-bold bg-emerald-50 py-2 px-4 rounded-full inline-block">
                تم تثبيت موعدك وتنبيه الفني بنجاح ✨
              </p>
              <p className="text-xs text-slate-500 pt-2">
                جاري توجيهك لصفحة تتبع الطلب خلال ثوانٍ معدودة...
              </p>
            </div>
          )}

          {status === "error" && (
            <div className="space-y-4 py-6">
              <div className="w-16 h-16 bg-rose-50 text-rose-500 rounded-full flex items-center justify-center mx-auto border border-rose-100">
                <XCircle className="w-10 h-10 stroke-[2]" />
              </div>
              <h2 className="text-lg font-black text-slate-800">فشل تأكيد الحجز</h2>
              <p className="text-xs text-rose-600 leading-relaxed font-semibold">
                {errorMessage}
              </p>
              <div className="pt-4 space-y-2">
                <button
                  onClick={() => router.push("/")}
                  className="w-full bg-primary hover:bg-primary/95 text-white font-bold py-3 px-6 rounded-2xl text-xs transition-colors shadow-lg shadow-primary/20"
                >
                  العودة للصفحة الرئيسية للحجز من جديد
                </button>
                <a
                  href="tel:19999"
                  className="w-full border border-slate-200 hover:bg-slate-50 text-slate-700 font-bold py-3 px-6 rounded-2xl text-xs transition-colors inline-block"
                >
                  الاتصال بالدعم الفني للمساعدة
                </a>
              </div>
            </div>
          )}

        </div>
      </main>

      <Footer />
    </div>
  );
}

export default function ConfirmBookingPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex flex-col bg-slate-50">
        <Header />
        <main className="flex-1 flex items-center justify-center py-20">
          <div className="flex flex-col items-center">
            <Loader2 className="w-12 h-12 stroke-[2] text-primary animate-spin mb-4" />
            <p className="text-xs font-bold text-slate-500">جاري تحميل صفحة التأكيد...</p>
          </div>
        </main>
        <Footer />
      </div>
    }>
      <ConfirmBookingContent />
    </Suspense>
  );
}
