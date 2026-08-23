"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ShieldCheck, CheckCircle2, XCircle, Loader2, ArrowLeft } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { buildWhatsAppUrl } from "@/lib/whatsapp";

function ConfirmBookingContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const id = searchParams.get("id");
  const token = searchParams.get("token");

  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState("");
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
        console.error("Error fetching whatsapp settings in confirm page:", err);
      }
    }
    fetchWhatsappSettings();
  }, []);

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
          p_token: token,
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
    <div className="min-h-screen flex flex-col bg-[#F8FAFC] font-sans">
      <Header />
      
      <main className="flex-1 flex items-center justify-center pt-28 pb-20 px-4">
        <div className="max-w-md w-full bg-white rounded-3xl p-8 border border-slate-200 shadow-xl text-center space-y-6">
          
          {status === "loading" && (
            <div className="space-y-4 py-8">
              <Loader2 className="w-14 h-14 stroke-[2] text-[#0091FF] animate-spin mx-auto" />
              <h2 className="text-lg font-black text-slate-800">جاري تأكيد حجزك...</h2>
              <p className="text-xs text-slate-500 font-medium">
                نقوم الآن بالتحقق من رمز التأكيد وتثبيت موعدك في نظام Fresh Home.
              </p>
            </div>
          )}

          {status === "success" && (
            <div className="space-y-4 py-4">
              <div className="w-16 h-16 bg-emerald-50 text-emerald-500 rounded-2xl flex items-center justify-center mx-auto border border-emerald-200 shadow-lg">
                <CheckCircle2 className="w-9 h-9 stroke-[2.5]" />
              </div>
              <h2 className="text-xl font-black text-slate-900">تم تأكيد حجزك بنجاح!</h2>
              <p className="text-xs text-emerald-700 font-bold bg-emerald-50 py-2 px-4 rounded-full inline-block border border-emerald-100">
                تم تثبيت موعدك وتنبيه الفريق المختص ✨
              </p>
              <p className="text-xs text-slate-400 font-medium pt-2">
                جاري توجيهك لصفحة تتبع الطلب خلال ثوانٍ...
              </p>
            </div>
          )}

          {status === "error" && (
            <div className="space-y-4 py-4">
              <div className="w-16 h-16 bg-rose-50 text-rose-500 rounded-2xl flex items-center justify-center mx-auto border border-rose-200">
                <XCircle className="w-9 h-9 stroke-[2]" />
              </div>
              <h2 className="text-lg font-black text-slate-900">فشل تأكيد الحجز</h2>
              <p className="text-xs text-rose-600 leading-relaxed font-bold bg-rose-50 p-3 rounded-xl border border-rose-100">
                {errorMessage}
              </p>
              <div className="pt-4 space-y-2.5">
                <button
                  onClick={() => router.push("/")}
                  className="w-full bg-[#0091FF] hover:bg-[#0077E6] text-white font-black py-3.5 px-6 rounded-xl text-xs transition-all shadow-md shadow-blue-500/20"
                >
                  العودة للصفحة الرئيسية
                </button>
                <a
                  href={buildWhatsAppUrl(whatsappNumber, "مرحباً، أود المساعدة في تأكيد حجزي لدى Fresh Home.")}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full border border-slate-200 hover:bg-slate-50 text-slate-700 font-bold py-3.5 px-6 rounded-xl text-xs transition-colors inline-block"
                >
                  التواصل مع خدمة العملاء
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
      <div className="min-h-screen flex flex-col bg-[#F8FAFC]">
        <Header />
        <main className="flex-1 flex items-center justify-center py-20">
          <div className="flex flex-col items-center">
            <Loader2 className="w-10 h-10 stroke-[2] text-[#0091FF] animate-spin mb-4" />
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
