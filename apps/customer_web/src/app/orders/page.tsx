"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { 
  ShieldCheck, Phone, CheckCircle, Clock, MapPin, 
  Award, Star, Send, Check
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";

// Mock technician fallback data
const DEFAULT_TECH = {
  name: "م/ أحمد مصطفى - فني تبريد وتكييف معتمد",
  rating: 4.9,
  jobs: 324,
  phone: "01012345678"
};

// Lifecycle steps mapping
const TIMELINE_STEPS = [
  { status: "created", label: "تم تسجيل الطلب", time: "تحديث تلقائي" },
  { status: "assigned", label: "تم تعيين الفني", time: "تحديث تلقائي" },
  { status: "accepted", label: "تأكيد موعد الزيارة", time: "تحديث تلقائي" },
  { status: "on_the_way", label: "الفني في الطريق إليك", time: "قيد الانتظار" },
  { status: "arrived", label: "وصل الفني للموقع", time: "قيد الانتظار" },
  { status: "in_progress", label: "جاري تقديم الخدمة", time: "قيد الانتظار" },
  { status: "completed", label: "اكتملت الخدمة بنجاح", time: "قيد الانتظار" }
];

function OrderTrackingContent() {
  const searchParams = useSearchParams();
  const bookingId = searchParams.get("bookingId") || "";
  const isSuccess = searchParams.get("success") === "true";

  const [booking, setBooking] = useState<any>(null);
  const [technician, setTechnician] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeStep, setActiveStep] = useState(2); // Accepted as default fallback
  const [whatsappNumber, setWhatsappNumber] = useState("+201012345678");
  const [showConfirmModal, setShowConfirmModal] = useState(false);

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
        console.error("Error fetching whatsapp settings:", err);
      }
    }
    fetchWhatsappSettings();
  }, []);

  useEffect(() => {
    async function fetchBookingDetails() {
      if (!bookingId) {
        setLoading(false);
        return;
      }
      setLoading(true);
      try {
        // 1. Fetch booking record via get_guest_booking_details RPC
        const { data: bookingData, error: bookingError } = await supabase
          .rpc("get_guest_booking_details", {
            p_booking_id: bookingId
          });

        if (bookingError) throw bookingError;
        if (!bookingData) throw new Error("لم يتم العثور على الحجز");
        
        setBooking(bookingData);
        if (isSuccess && bookingData.is_whatsapp_confirmed === false) {
          setShowConfirmModal(true);
        }

        // 2. Map status to active step index
        const statusMap: Record<string, number> = {
          "created": 0,
          "assigned": 1,
          "accepted": 2,
          "on_the_way": 3,
          "arrived": 4,
          "in_progress": 5,
          "completed": 6,
          "cancelled": -1
        };

        const currentStatus = bookingData.status || "created";
        if (statusMap[currentStatus] !== undefined) {
          setActiveStep(statusMap[currentStatus]);
        }

        // 3. Set technician details from RPC data if assigned
        if (bookingData.technician) {
          setTechnician({
            name: `م/ ${bookingData.technician.name}`,
            rating: bookingData.technician.rating ? Number(bookingData.technician.rating).toFixed(1) : "4.9",
            jobs: bookingData.technician.completed_jobs || 120,
            phone: "01012345678" // Fallback number for testing
          });
        }
      } catch (e) {
        console.error("Error fetching booking details:", e);
      } finally {
        setLoading(false);
      }
    }

    fetchBookingDetails();

    // 4. Set up realtime subscription to listen for status changes
    if (bookingId) {
      const channel = supabase
        .channel(`realtime-booking-${bookingId}`)
        .on(
          "postgres_changes",
          {
            event: "UPDATE",
            schema: "public",
            table: "bookings",
            filter: `id=eq.${bookingId}`
          },
          async (payload: any) => {
            console.log("Realtime update received for booking:", payload.new);
            
            // Re-fetch the full booking details using get_guest_booking_details RPC to update UI state safely
            try {
              const { data: updatedBooking } = await supabase
                .rpc("get_guest_booking_details", { p_booking_id: bookingId });
              
              if (updatedBooking) {
                setBooking(updatedBooking);
                const statusMap: Record<string, number> = {
                  "created": 0,
                  "assigned": 1,
                  "accepted": 2,
                  "on_the_way": 3,
                  "arrived": 4,
                  "in_progress": 5,
                  "completed": 6,
                  "cancelled": -1
                };
                const currentStatus = updatedBooking.status || "created";
                if (statusMap[currentStatus] !== undefined) {
                  setActiveStep(statusMap[currentStatus]);
                }
                if (updatedBooking.technician) {
                  setTechnician({
                    name: `م/ ${updatedBooking.technician.name}`,
                    rating: updatedBooking.technician.rating ? Number(updatedBooking.technician.rating).toFixed(1) : "4.9",
                    jobs: updatedBooking.technician.completed_jobs || 120,
                    phone: "01012345678"
                  });
                }
              }
            } catch (err) {
              console.error("Error updating booking via RPC on realtime event:", err);
            }
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(channel);
      };
    }
  }, [bookingId]);

  if (loading) {
    return (
      <div className="flex-1 bg-slate-50 py-20 flex flex-col items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary mb-4"></div>
        <p className="text-xs font-bold text-slate-500">جاري تحميل بيانات تتبع طلبك من قاعدة البيانات...</p>
      </div>
    );
  }

  if (!booking && !bookingId.includes("FH-")) {
    return (
      <div className="flex-1 bg-slate-50 py-20 text-center space-y-4">
        <h1 className="text-xl font-black text-slate-800">الحجز المطلوب غير موجود</h1>
        <p className="text-xs text-slate-500">يرجى التحقق من صحة رابط التتبع أو رقم الطلب المرفق.</p>
        <Link href="/" className="bg-primary text-white text-xs font-bold px-6 py-2.5 rounded-xl inline-block">
          العودة للرئيسية
        </Link>
      </div>
    );
  }

  // Formatting final date displays
  const displayDay = booking?.scheduled_day || "قيد التعيين";
  const displayTime = booking?.start_time_slot ? `${booking.start_time_slot.substring(0, 5)}` : "بين الساعة 09:00 ص";
  const finalBookingId = booking?.id || bookingId || "FH-894723";
  const finalTech = technician || DEFAULT_TECH;
  const addressSnap = booking?.address_snapshot || {};

  return (
    <>
      <Header />
      
      <main className="flex-1 bg-slate-50 py-10">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-8">
          
          {/* WhatsApp Pending Confirmation Banner */}
          {booking?.is_whatsapp_confirmed === false && (
            <div className="bg-amber-50 border border-amber-200 rounded-3xl p-6 text-center space-y-4 shadow-sm">
              <div className="w-14 h-14 bg-amber-500 text-white rounded-full flex items-center justify-center mx-auto shadow-lg shadow-amber-500/20">
                <Clock className="w-8 h-8 stroke-[2.5] animate-pulse" />
              </div>
              <div className="space-y-1">
                <h1 className="text-xl sm:text-2xl font-black text-amber-800">طلبك في انتظار التأكيد عبر واتساب</h1>
                <p className="text-amber-700 text-xs sm:text-sm max-w-2xl mx-auto leading-relaxed">
                  تم استلام طلبك بنجاح. تم إرسال رسالة تأكيد إلى واتساب. يرجى تأكيد الطلب خلال <strong>60 دقيقة</strong> حتى يتم الاحتفاظ بالموعد وتجنب إلغائه تلقائياً.
                </p>
              </div>
              <div className="flex flex-col sm:flex-row gap-3 justify-center pt-2">
                <a 
                  href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}?text=${encodeURIComponent(
                    `مرحباً، أود تأكيد حجزي الجديد كضيف عبر موقع فريش هوم:
- رقم الطلب: ${booking?.readable_id || finalBookingId}
- الاسم: ${booking?.contact_name || ""}
- الخدمة: ${booking?.service_snapshot?.title || "خدمة منزلية"}
- التاريخ: ${displayDay}
- الموعد: ${displayTime}`
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center gap-2 bg-[#25D366] hover:bg-[#20ba56] text-white font-bold px-6 py-2.5 rounded-xl text-xs transition-all shadow-md shadow-emerald-500/10"
                >
                  <Send className="w-4 h-4 fill-white" />
                  <span>تأكيد سريع عبر واتساب الشركة</span>
                </a>
                <Link 
                  href="/"
                  className="bg-white border border-amber-200 text-amber-800 hover:bg-amber-50 font-bold px-6 py-2.5 rounded-xl text-xs"
                >
                  العودة للرئيسية
                </Link>
              </div>
            </div>
          )}

          {/* Success Banner Celebration (Only for confirmed bookings) */}
          {isSuccess && booking?.is_whatsapp_confirmed !== false && (
            <div className="bg-emerald-50 border border-emerald-100 rounded-3xl p-6 text-center space-y-4 shadow-sm">
              <div className="w-14 h-14 bg-secondary text-slate-900 rounded-full flex items-center justify-center mx-auto shadow-lg shadow-secondary/20">
                <CheckCircle className="w-8 h-8 stroke-[2.5]" />
              </div>
              <div className="space-y-1">
                <h1 className="text-xl sm:text-2xl font-black text-slate-800">تهانينا! تم تسجيل طلبك بنجاح</h1>
                <p className="text-slate-500 text-xs sm:text-sm">
                  تم إرسال حجزك لقاعدة بيانات فريش هوم بنجاح. رقم الحجز الخاص بك هو <strong className="text-primary font-black select-all">{finalBookingId}</strong>.
                </p>
              </div>
              <div className="flex flex-col sm:flex-row gap-3 justify-center pt-2">
                <a 
                  href={`https://wa.me/${whatsappNumber.replace("+", "").trim()}?text=مرحباً، أود الاستفسار بخصوص حجزي برقم ${finalBookingId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center gap-2 bg-[#25D366] hover:bg-[#20ba56] text-white font-bold px-6 py-2.5 rounded-xl text-xs transition-all shadow-md shadow-emerald-500/10"
                >
                  <Send className="w-4 h-4 fill-white" />
                  <span>تواصل عبر واتساب الشركة</span>
                </a>
                <Link 
                  href="/"
                  className="bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 font-bold px-6 py-2.5 rounded-xl text-xs"
                >
                  العودة للرئيسية
                </Link>
              </div>
            </div>
          )}

          {/* Grid layout */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Live tracking timeline */}
            <div className="lg:col-span-8 bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-6">
              <div className="flex justify-between items-center border-b border-slate-100 pb-4">
                <div>
                  <span className="text-[10px] text-slate-400 font-bold block">معرف الحجز الخاص بك</span>
                  <h2 className="text-base sm:text-lg font-black text-primary font-sans select-all">{finalBookingId}</h2>
                </div>
                <div className="flex items-center gap-1.5 text-xs text-secondary bg-emerald-50 border border-emerald-100 px-3 py-1 rounded-full font-bold">
                  <span className="w-2 h-2 rounded-full bg-secondary animate-ping"></span>
                  <span>تحديث فوري نشط</span>
                </div>
              </div>

              {/* Steps timeline view */}
              <div className="relative pl-4 space-y-6">
                {activeStep === -1 ? (
                  <div className="bg-rose-50 border border-rose-100 rounded-xl p-4 flex gap-3 text-xs text-rose-800">
                    <span className="font-black">تم إلغاء هذا الطلب من قبل الإدارة أو العميل.</span>
                  </div>
                ) : (
                  TIMELINE_STEPS.map((step, idx) => {
                    const isCompleted = idx < activeStep;
                    const isActive = idx === activeStep;
                    
                    return (
                      <div key={idx} className="flex gap-4 relative">
                        {/* Timeline dot and connector */}
                        <div className="flex flex-col items-center relative">
                          <div 
                            className={`w-6 h-6 rounded-full flex items-center justify-center z-10 transition-all border-4 bg-white ${
                              isCompleted ? "border-secondary text-secondary" : isActive ? "border-primary text-primary scale-110" : "border-slate-100 text-slate-300"
                            }`}
                          >
                            {isCompleted && <Check className="w-3.5 h-3.5 text-white bg-secondary rounded-full" />}
                          </div>
                          {idx < TIMELINE_STEPS.length - 1 && (
                            <div className={`absolute top-6 bottom-0 w-0.5 -z-0 ${
                              idx < activeStep ? "bg-secondary" : "bg-slate-100"
                            }`}></div>
                          )}
                        </div>

                        {/* Step Labels */}
                        <div className="flex-1 pb-2">
                          <h4 className={`text-xs font-black ${isActive ? "text-primary" : isCompleted ? "text-slate-700" : "text-slate-400"}`}>
                            {step.label}
                          </h4>
                          <span className="text-[9px] font-bold text-slate-400 block mt-0.5">
                            {isActive ? "نشط حالياً" : isCompleted ? "مكتمل" : step.time}
                          </span>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            {/* Side Details Column */}
            <div className="lg:col-span-4 space-y-6">
              
              {/* Technician details card */}
              <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-4">
                <span className="text-[10px] text-slate-400 font-bold block border-b border-slate-100 pb-2">الفني المخصص لطلبك</span>
                
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-primary/10 text-primary flex items-center justify-center rounded-xl font-bold shrink-0">
                    <Award className="w-6 h-6 stroke-[2]" />
                  </div>
                  <div>
                    <h4 className="text-xs font-extrabold text-slate-800 leading-normal">{finalTech.name}</h4>
                    <div className="flex items-center gap-1.5 mt-1 text-xs">
                      <div className="flex items-center text-amber-500 font-bold gap-0.5">
                        <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                        <span>{finalTech.rating}</span>
                      </div>
                      <span className="text-slate-400">• {finalTech.jobs} خدمة منجزة</span>
                    </div>
                  </div>
                </div>

                {/* Call buttons */}
                <div className="grid grid-cols-2 gap-2 pt-3 border-t border-slate-100">
                  <a 
                    href={`tel:${finalTech.phone}`}
                    className="flex items-center justify-center gap-1.5 border border-primary text-primary hover:bg-primary/5 font-bold py-2.5 rounded-xl text-[10px] sm:text-xs transition-colors"
                  >
                    <Phone className="w-3.5 h-3.5" />
                    <span>اتصال تلفني</span>
                  </a>
                  <a 
                    href={`https://wa.me/20${finalTech.phone}?text=مرحباً، أود الاستفسار بخصوص الحجز رقم ${finalBookingId}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center gap-1.5 border border-emerald-500 text-emerald-600 hover:bg-emerald-50 font-bold py-2.5 rounded-xl text-[10px] sm:text-xs transition-colors"
                  >
                    <span>واتساب الفني</span>
                  </a>
                </div>
              </div>

              {/* Order Info Summary */}
              {booking && (
                <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-3.5 text-xs">
                  <span className="text-[10px] text-slate-400 font-bold block border-b border-slate-100 pb-2">بيانات تفاصيل الحجز</span>
                  <div className="flex justify-between">
                    <span className="text-slate-500 font-bold">تاريخ الزيارة:</span>
                    <span className="font-extrabold text-slate-800">{displayDay}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500 font-bold">موعد الوصول:</span>
                    <span className="font-extrabold text-slate-800">ساعة {displayTime}</span>
                  </div>
                  {addressSnap.street && (
                    <div className="border-t border-slate-100 pt-3 space-y-1">
                      <span className="text-slate-500 font-bold block">العنوان المسجل للخدمة:</span>
                      <p className="text-[11px] text-slate-700 font-semibold leading-relaxed">
                        {addressSnap.governorate}، {addressSnap.city}، {addressSnap.street}، عمارة {addressSnap.building}، دور {addressSnap.floor}، شقة {addressSnap.apartment}
                      </p>
                    </div>
                  )}
                  {booking.price_snapshot?.total && (
                    <div className="border-t border-slate-100 pt-3 flex justify-between font-black text-primary text-sm">
                      <span>القيمة الإجمالية للطلب:</span>
                      <span>{booking.price_snapshot.total} ج.م</span>
                    </div>
                  )}
                </div>
              )}

              {/* Quick support info block */}
              <div className="bg-primary/5 border border-primary/10 rounded-2xl p-5 space-y-3">
                <h4 className="font-extrabold text-primary text-sm">هل لديك أي استفسار أو مشكلة؟</h4>
                <p className="text-slate-500 text-xs leading-relaxed font-light">
                  خدمة العملاء في فريش هوم متوفرة لمساعدتك في أي وقت. يمكنك الاتصال بخط المساعدة أو النقر على الرابط للتواصل المباشر معنا.
                </p>
                <div className="pt-2">
                  <a 
                    href="tel:19999" 
                    className="bg-primary hover:bg-primary/95 text-white font-bold px-4 py-2 rounded-xl text-xs shadow-md inline-block"
                  >
                    تواصل مع الدعم الفني
                  </a>
                </div>
              </div>
            </div>

          </div>
        </div>
      </main>
      
      {/* WhatsApp Confirmation Dialog Modal */}
      {showConfirmModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4" dir="rtl">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full border border-slate-100 shadow-2xl space-y-6 transform transition-all scale-100 relative text-right">
            <div className="w-16 h-16 bg-amber-500 text-white rounded-full flex items-center justify-center mx-auto shadow-lg shadow-amber-500/20">
              <Clock className="w-8 h-8 stroke-[2.5] animate-pulse" />
            </div>
            
            <div className="space-y-2 text-center">
              <h2 className="text-xl sm:text-2xl font-black text-slate-800">خطوة أخيرة لتأكيد حجزك ⚠️</h2>
              <p className="text-slate-500 text-xs sm:text-sm leading-relaxed">
                يرجى إرسال تفاصيل حجزك عبر الواتساب لتأكيد الموعد مع الإدارة.
              </p>
              <div className="bg-amber-50 border border-amber-100 rounded-2xl p-4 text-[11px] sm:text-xs text-amber-800 text-right space-y-1">
                <strong>لماذا هذه الخطوة؟</strong>
                <p className="leading-relaxed">
                  لحجز الموعد وتأكيده وضمان عدم إلغائه تلقائياً بعد مرور 60 دقيقة.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              <a
                href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}?text=${encodeURIComponent(
                  `مرحباً، أود تأكيد حجزي الجديد كضيف عبر موقع فريش هوم:
- رقم الطلب: ${booking?.readable_id || finalBookingId}
- الاسم: ${booking?.contact_name || ""}
- الخدمة: ${booking?.service_snapshot?.title || "خدمة منزلية"}
- التاريخ: ${displayDay}
- الموعد: ${displayTime}`
                )}`}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => setShowConfirmModal(false)}
                className="w-full inline-flex items-center justify-center gap-2 bg-[#25D366] hover:bg-[#20ba56] text-white font-extrabold py-3.5 px-6 rounded-2xl text-xs sm:text-sm transition-all shadow-md shadow-emerald-500/10 text-center"
              >
                <Send className="w-4 h-4 fill-white" />
                <span>إرسال تفاصيل الحجز وتأكيده عبر واتساب</span>
              </a>
              
              <button
                onClick={() => setShowConfirmModal(false)}
                className="w-full bg-slate-50 hover:bg-slate-100 text-slate-500 font-bold py-3.5 px-6 rounded-2xl text-xs transition-colors"
              >
                سأقوم بالتأكيد لاحقاً (خلال المهلة)
              </button>
            </div>
          </div>
        </div>
      )}
      
      <Footer />
    </>
  );
}

export default function OrderTracking() {
  return (
    <Suspense fallback={
      <div className="flex-1 bg-slate-50 py-20 flex flex-col items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary mb-4"></div>
        <p className="text-xs font-bold text-slate-500">جاري تحميل صفحة التتبع...</p>
      </div>
    }>
      <OrderTrackingContent />
    </Suspense>
  );
}
