"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { 
  ShieldCheck, Phone, CheckCircle, Clock, MapPin, 
  Award, Star, Send, Check, AlertCircle, ChevronLeft
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
  const router = useRouter();
  const searchParams = useSearchParams();
  const bookingId = searchParams.get("bookingId") || "";
  const isSuccess = searchParams.get("success") === "true";

  const [booking, setBooking] = useState<any>(null);
  const [technician, setTechnician] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeStep, setActiveStep] = useState(2); // Accepted as default fallback
  const [whatsappNumber, setWhatsappNumber] = useState("+201012345678");
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [timeLeft, setTimeLeft] = useState<number | null>(null);

  const [user, setUser] = useState<any>(null);
  const [userBookings, setUserBookings] = useState<any[]>([]);
  const [loadingUserBookings, setLoadingUserBookings] = useState(false);
  const [searchInput, setSearchInput] = useState("");

  useEffect(() => {
    if (!booking || booking.is_whatsapp_confirmed) {
      setTimeLeft(null);
      return;
    }

    let createdTimeStr = booking.created_at;
    if (!createdTimeStr && typeof window !== "undefined") {
      createdTimeStr = localStorage.getItem(`booking_created_${bookingId}`);
    }

    const createdAt = createdTimeStr ? new Date(createdTimeStr).getTime() : Date.now();
    const expiryTime = createdAt + 60 * 60 * 1000; // 60 minutes

    const updateTimer = () => {
      const remainingMs = expiryTime - Date.now();
      if (remainingMs <= 0) {
        setTimeLeft(0);
      } else {
        setTimeLeft(Math.floor(remainingMs / 1000));
      }
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);

    return () => clearInterval(interval);
  }, [booking, bookingId]);

  const formatTimeLeft = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  };

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
    async function checkUserAndLoadBookings() {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        setUser(session.user);
        if (!bookingId) {
          setLoadingUserBookings(true);
          try {
            const { data } = await supabase
              .from("bookings")
              .select("id, readable_id, status, created_at, scheduled_day, start_time_slot, service_snapshot, pricing_inputs")
              .eq("user_id", session.user.id)
              .order("created_at", { ascending: false });
            if (data) {
              setUserBookings(data);
            }
          } catch (e) {
            console.error("Error loading user bookings in orders page:", e);
          } finally {
            setLoadingUserBookings(false);
          }
        }
      }
    }
    checkUserAndLoadBookings();
  }, [bookingId]);

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

  if (!bookingId) {
    return (
      <>
        <Header />
        <main className="flex-1 bg-slate-50 py-10">
          <div className="max-w-xl mx-auto px-4 text-right">
            {user ? (
              <div className="space-y-6">
                <div>
                  <h1 className="text-2xl font-black text-slate-800 font-sans">حجوزاتي وطلباتي</h1>
                  <p className="text-slate-400 text-xs mt-1">قائمة بجميع الطلبات المرتبطة بحسابك.</p>
                </div>
                
                {loadingUserBookings ? (
                  <div className="py-12 flex justify-center bg-white rounded-3xl border border-slate-200/50">
                    <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
                  </div>
                ) : userBookings.length === 0 ? (
                  <div className="bg-white p-8 rounded-3xl border border-slate-200/60 shadow-xs text-center space-y-4">
                    <Clock className="w-8 h-8 mx-auto text-slate-300" />
                    <p className="text-xs font-bold text-slate-500 font-sans">لم تقم بإجراء أي حجوزات بعد.</p>
                    <Link href="/" className="bg-primary hover:bg-primary/95 text-white font-extrabold px-6 py-2.5 rounded-xl text-xs inline-block shadow-sm">
                      احجز خدمة جديدة الآن
                    </Link>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Active Bookings Section */}
                    {userBookings.some((b) => !["completed", "cancelled"].includes(b.status)) && (
                      <div className="space-y-3">
                        <span className="block text-[11px] font-black text-primary bg-primary/5 p-2 px-3.5 rounded-xl self-start">الحجوزات النشطة الحالية</span>
                        {userBookings
                          .filter((b) => !["completed", "cancelled"].includes(b.status))
                          .map((b) => (
                            <Link 
                              href={`/orders?bookingId=${b.id}`}
                              key={b.id}
                              className="block p-4 bg-white hover:bg-slate-50/50 rounded-2xl border border-slate-200/60 shadow-xs transition-all hover:border-slate-350"
                            >
                              <div className="flex justify-between items-center gap-4">
                                <div className="space-y-1 text-right">
                                  <span className="text-xs font-black text-slate-800 block">{b.service_snapshot?.title || "خدمة منزلية"}</span>
                                  <div className="text-[10px] text-slate-400 font-bold flex gap-2">
                                    <span>الرقم: {b.readable_id}</span>
                                    <span>•</span>
                                    <span>{new Date(b.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short" })}</span>
                                  </div>
                                </div>
                                <span className="text-[9px] font-black px-2.5 py-0.5 rounded-full border bg-primary/5 border-primary/10 text-primary">
                                  {b.status === "created" && "تم تسجيل الطلب"}
                                  {b.status === "assigned" && "تم التعيين"}
                                  {b.status === "accepted" && "مؤكد"}
                                  {b.status === "on_the_way" && "الفني بالطريق"}
                                  {b.status === "arrived" && "الفني بالموقع"}
                                  {b.status === "in_progress" && "جاري العمل"}
                                </span>
                              </div>
                            </Link>
                          ))}
                      </div>
                    )}

                    {/* Past/Completed Bookings Section */}
                    {userBookings.some((b) => ["completed", "cancelled"].includes(b.status)) && (
                      <div className="space-y-3">
                        <span className="block text-[11px] font-black text-slate-400 bg-slate-100 p-2 px-3.5 rounded-xl self-start animate-fade-in">الحجوزات السابقة والمكتملة</span>
                        {userBookings
                          .filter((b) => ["completed", "cancelled"].includes(b.status))
                          .map((b) => {
                            const isCompleted = b.status === "completed";
                            return (
                              <Link 
                                href={`/orders?bookingId=${b.id}`}
                                key={b.id}
                                className="block p-4 bg-white hover:bg-slate-50/50 rounded-2xl border border-slate-250/60 shadow-xs transition-all hover:border-slate-350 opacity-80 hover:opacity-100"
                              >
                                <div className="flex justify-between items-center gap-4">
                                  <div className="space-y-1 text-right">
                                    <span className="text-xs font-black text-slate-800 block">{b.service_snapshot?.title || "خدمة منزلية"}</span>
                                    <div className="text-[10px] text-slate-400 font-bold flex gap-2">
                                      <span>الرقم: {b.readable_id}</span>
                                      <span>•</span>
                                      <span>{new Date(b.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short" })}</span>
                                    </div>
                                  </div>
                                  <span className={`text-[9px] font-black px-2.5 py-0.5 rounded-full border ${
                                    isCompleted 
                                      ? "bg-emerald-50 border-emerald-100 text-emerald-700" 
                                      : "bg-rose-50 border-rose-100 text-rose-700"
                                  }`}>
                                    {isCompleted ? "اكتمل بنجاح" : "ملغي"}
                                  </span>
                                </div>
                              </Link>
                            );
                          })}
                      </div>
                    )}
                  </div>
                )}
              </div>
            ) : (
              <div className="bg-white/80 backdrop-blur-md rounded-3xl p-8 border border-slate-200/60 shadow-xs space-y-6">
                <div>
                  <h1 className="text-xl font-black text-slate-800 font-sans">تتبع الطلبات والحجوزات</h1>
                  <p className="text-slate-400 text-xs mt-1">تتبع حالة زيارة الفني وتأكيد حجزك كضيف.</p>
                </div>

                <form 
                  onSubmit={(e) => {
                    e.preventDefault();
                    if (searchInput.trim()) {
                      router.push(`/orders?bookingId=${searchInput.trim()}`);
                    }
                  }}
                  className="space-y-4"
                >
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-600">رقم الحجز الفرعي (Booking ID)</label>
                    <input 
                      type="text" 
                      placeholder="مثال: FH-100293 أو معرف الحجز الخاص بك"
                      value={searchInput}
                      onChange={(e) => setSearchInput(e.target.value)}
                      className="w-full p-3 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-left font-mono"
                      required
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md shadow-primary/10 hover:bg-primary/95 transition-all cursor-pointer"
                  >
                    تتبع الطلب الآن
                  </button>
                </form>

                <div className="text-center pt-4 border-t border-slate-100 text-xs text-slate-500">
                  <span>سجل دخولك لعرض قائمة حجوزاتك كاملة تلقائياً: </span>
                  <Link href="/login" className="text-primary font-black hover:underline">
                    تسجيل الدخول
                  </Link>
                </div>
              </div>
            )}
          </div>
        </main>
        <Footer />
      </>
    );
  }

  if (!booking) {
    return (
      <>
        <Header />
        <main className="flex-grow bg-slate-50 py-20">
          <div className="max-w-md mx-auto px-4 text-center space-y-4 bg-white p-8 rounded-3xl border border-slate-200/60 shadow-xs">
            <AlertCircle className="w-12 h-12 text-rose-500 mx-auto" />
            <h1 className="text-xl font-black text-slate-800">الحجز المطلوب غير موجود</h1>
            <p className="text-xs text-slate-500 font-bold leading-relaxed">
              يرجى التحقق من صحة رمز التتبع المكتوب. أو اضغط على الزر للعودة وتصفح طلبات حسابك.
            </p>
            <div className="pt-2 flex flex-col gap-2">
              <Link href="/orders" className="bg-primary hover:bg-primary/95 text-white text-xs font-black py-2.5 rounded-xl block shadow-sm">
                الذهاب لصفحة تتبع الطلبات
              </Link>
              <Link href="/" className="bg-slate-100 hover:bg-slate-200 text-slate-600 text-xs font-black py-2.5 rounded-xl block">
                العودة للرئيسية
              </Link>
            </div>
          </div>
        </main>
        <Footer />
      </>
    );
  }

  // Formatting final date displays
  const rawDisplayDay = booking?.scheduled_day || "قيد التعيين";
  const displayDay = rawDisplayDay.includes('T') ? rawDisplayDay.split('T')[0] : rawDisplayDay;
  const displayTime = booking?.start_time_slot ? `${booking.start_time_slot.substring(0, 5)}` : "بين الساعة 09:00 ص";
  const finalBookingId = booking?.readable_id || bookingId || "FH-894723";
  const finalTech = technician || DEFAULT_TECH;
  const addressSnap = booking?.address_snapshot || {};

  const getServiceTitle = (snapshot: any) => {
    if (!snapshot) return "خدمة منزلية";
    if (typeof snapshot.title === "string") return snapshot.title;
    if (snapshot.title && typeof snapshot.title === "object") {
      return snapshot.title.ar || snapshot.title.en || "خدمة منزلية";
    }
    return "خدمة منزلية";
  };

  return (
    <>
      <Header />
      
      <main className="flex-1 bg-slate-50 py-10">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-8">
          
          {/* WhatsApp Pending Confirmation Banner */}
          {booking?.is_whatsapp_confirmed === false && (
            <div className="relative overflow-hidden bg-white/70 backdrop-blur-md border border-amber-250/30 rounded-3xl p-6 sm:p-8 text-center space-y-6 shadow-[0_8px_32px_0_rgba(245,158,11,0.06)]">
              {/* Decorative gradient blur background blobs */}
              <div className="absolute -left-12 -top-12 w-32 h-32 bg-amber-500/10 rounded-full blur-2xl -z-10"></div>
              <div className="absolute -right-12 -bottom-12 w-32 h-32 bg-amber-600/10 rounded-full blur-2xl -z-10"></div>

              <div className="flex flex-col items-center gap-3">
                <div className="w-16 h-16 bg-amber-500/10 border border-amber-500/20 text-amber-600 rounded-full flex items-center justify-center shadow-inner animate-pulse">
                  <Clock className="w-8 h-8 stroke-[2.5]" />
                </div>
                
                {timeLeft !== null && (
                  <div className={`px-4 py-1.5 rounded-full text-xs font-black font-mono border tracking-wider transition-all duration-300 shadow-sm ${
                    timeLeft === 0 
                      ? "bg-rose-50 border-rose-200/50 text-rose-600" 
                      : timeLeft < 600 
                        ? "bg-rose-50 border-rose-200/50 text-rose-500 animate-pulse" 
                        : "bg-amber-50 border-amber-250/50 text-amber-600"
                  }`}>
                    {timeLeft === 0 ? (
                      "انتهت صلاحية مهلة التأكيد التلقائي ⚠️"
                    ) : (
                      `الوقت المتبقي للتأكيد: ${formatTimeLeft(timeLeft)}`
                    )}
                  </div>
                )}
              </div>

              <div className="space-y-2">
                <h1 className="text-xl sm:text-2xl font-black text-slate-800">طلبك في انتظار التأكيد عبر واتساب</h1>
                <p className="text-slate-500 text-xs sm:text-sm max-w-2xl mx-auto leading-relaxed">
                  تم تسجيل حجزك بنجاح كضيف. يرجى إرسال رسالة التأكيد عبر واتساب للحفاظ على موعد الزيارة وتجنب إلغاء الحجز تلقائياً خلال 60 دقيقة.
                </p>
              </div>

              <div className="flex flex-col sm:flex-row gap-3 justify-center pt-2">
                <a 
                  href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}?text=${encodeURIComponent(
                    `مرحباً،

أرغب في تأكيد الحجز التالي:

📋 رقم الطلب: ${booking?.readable_id || finalBookingId}
🏠 الخدمة: ${booking?.service_snapshot?.title || "خدمة منزلية"}
💰 السعر: ${booking?.price_snapshot?.total || ""} جنيه
📅 التاريخ: ${displayDay.includes('T') ? displayDay.split('T')[0] : displayDay}
⏰ الموعد: ${booking?.start_time_slot ? booking.start_time_slot.substring(0, 5) : "09:00"}
👤 الاسم: ${booking?.contact_name || ""}
📞 الهاتف: ${booking?.contact_phones?.[0] || ""}
📍 المحافظة: ${addressSnap.governorate || ""}
📍 المدينة: ${addressSnap.city || ""}

بإرسال هذه الرسالة أؤكد صحة بيانات الحجز ورغبتي في تنفيذ الخدمة بالسعر الموضح أعلاه. 
شكراً لكم.`
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center gap-2 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-extrabold px-8 py-3 rounded-2xl text-xs transition-all shadow-lg shadow-emerald-500/20 hover:scale-[1.02] active:scale-95 duration-200"
                >
                  <Send className="w-4 h-4 fill-white" />
                  <span>تأكيد سريع عبر واتساب الشركة</span>
                </a>
                <Link 
                  href="/"
                  className="inline-flex items-center justify-center bg-white border border-slate-250 hover:bg-slate-50 text-slate-700 font-extrabold px-8 py-3 rounded-2xl text-xs transition-all duration-200 shadow-sm"
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

                  <div className="flex justify-between border-t border-slate-100 pt-3">
                    <span className="text-slate-500 font-bold">الخدمة المطلوبة:</span>
                    <span className="font-extrabold text-primary">{getServiceTitle(booking.service_snapshot)}</span>
                  </div>

                  {/* مواصفات الخدمة والمدخلات */}
                  {booking.price_config?.fields && (() => {
                    const fieldsToRender = booking.price_config.fields.filter((field: any) => {
                      const val = booking.pricing_inputs?.[field.id];
                      if (field.type === "toggle") return !!val;
                      if (field.type === "number") return val !== undefined && val > 0;
                      return val !== undefined && val !== "";
                    });

                    if (fieldsToRender.length === 0) return null;

                    return (
                      <div className="border-t border-slate-100 pt-3 space-y-2">
                        <span className="text-slate-500 font-bold block mb-1">المواصفات والتفاصيل:</span>
                        <div className="grid grid-cols-1 gap-1.5">
                          {fieldsToRender.map((field: any) => {
                            const val = booking.pricing_inputs?.[field.id];
                            const label = field.label?.ar || field.label?.en || field.label;
                            const unit = field.unit || "";
                            
                            return (
                              <div key={field.id} className="flex justify-between text-[11px] bg-slate-50/70 px-2.5 py-1.5 rounded-lg border border-slate-100/80">
                                <span className="text-slate-550 font-medium">{label}:</span>
                                <span className="font-bold text-slate-850">
                                  {field.type === "toggle" ? "نعم" : `${val} ${unit}`}
                                </span>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    );
                  })()}

                  {/* الخدمات الإضافية */}
                  {booking.pricing_inputs?.selected_options && booking.pricing_inputs.selected_options.length > 0 && (
                    <div className="border-t border-slate-100 pt-3 space-y-2">
                      <span className="text-slate-500 font-bold block mb-1">الخدمات الإضافية:</span>
                      <div className="space-y-1.5">
                        {booking.pricing_inputs.selected_options.map((addonKey: string, idx: number) => {
                          const optionObj = booking.price_config?.options?.find((opt: any) => opt.key === addonKey);
                          const addonPrice = optionObj ? ` (+${optionObj.value} ج.م)` : "";
                          
                          return (
                            <div key={idx} className="flex justify-between text-[11px] bg-emerald-50/30 text-emerald-800 px-2.5 py-1.5 rounded-lg border border-emerald-100/40">
                              <span className="font-semibold">✨ {addonKey}</span>
                              {addonPrice && <span className="font-bold text-emerald-600">{addonPrice}</span>}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}

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

                  {/* Cancel Booking option for logged-in users */}
                  {user && !["completed", "cancelled"].includes(booking.status) && (
                    <div className="border-t border-slate-100 pt-4 mt-3">
                      <button
                        type="button"
                        onClick={async () => {
                          if (!confirm("هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟")) return;
                          try {
                            const { error } = await supabase
                              .from("bookings")
                              .update({ status: "cancelled" })
                              .eq("id", booking.id);
                            if (error) throw error;
                            alert("تم إلغاء الحجز بنجاح.");
                            window.location.reload();
                          } catch (err: any) {
                            alert("فشل إلغاء الحجز: " + err.message);
                          }
                        }}
                        className="w-full py-2.5 rounded-xl border border-rose-250 hover:bg-rose-50 text-rose-600 font-extrabold text-xs transition-all cursor-pointer text-center"
                      >
                        إلغاء هذا الحجز (Cancel Booking)
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* Quick support info block */}
              <div className="bg-primary/5 border border-primary/10 rounded-2xl p-5 space-y-3">
                <h4 className="font-extrabold text-primary text-sm">هل لديك أي استفسار أو مشكلة؟</h4>
                <p className="text-slate-500 text-xs leading-relaxed font-light">
                  خدمة العملاء في فريش هوم متوفرة لمساعدتك في أي وقت. يمكنك النقر على الرابط للتواصل المباشر معنا عبر الواتساب.
                </p>
                <div className="pt-2">
                  <a 
                    href={`https://wa.me/${whatsappNumber.replace(/\+/g, "")}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-emerald-650 hover:bg-emerald-700 text-white font-bold px-5 py-2.5 rounded-xl text-xs shadow-md inline-block transition-colors"
                  >
                    تواصل عبر الواتساب
                  </a>
                </div>
              </div>
            </div>

          </div>
        </div>
      </main>
      
      {/* WhatsApp Confirmation Dialog Modal */}
      {showConfirmModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-md flex items-center justify-center z-50 p-4 transition-all duration-300" dir="rtl">
          <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 sm:p-8 max-w-md w-full border border-white/20 shadow-[0_20px_50px_rgba(0,0,0,0.15)] space-y-6 transform transition-all scale-100 relative text-right">
            
            {/* Decorative colored glow in modal */}
            <div className="absolute -right-8 -top-8 w-24 h-24 bg-amber-500/15 rounded-full blur-2xl -z-10"></div>
            <div className="absolute -left-8 -bottom-8 w-24 h-24 bg-emerald-500/10 rounded-full blur-2xl -z-10"></div>

            <div className="w-16 h-16 bg-amber-500/10 text-amber-600 rounded-full flex items-center justify-center mx-auto shadow-inner border border-amber-500/20 animate-pulse">
              <Clock className="w-8 h-8 stroke-[2.5]" />
            </div>
            
            <div className="space-y-3 text-center">
              <h2 className="text-xl sm:text-2xl font-black text-slate-800">تأكيد حجزك عبر الواتساب ⚠️</h2>
              
              {timeLeft !== null && (
                <div className={`inline-block px-4 py-1.5 rounded-full text-xs font-black font-mono border tracking-wider transition-all duration-300 shadow-sm ${
                  timeLeft === 0 
                    ? "bg-rose-50 border-rose-200/50 text-rose-600" 
                    : timeLeft < 600 
                      ? "bg-rose-50 border-rose-200/50 text-rose-500 animate-pulse" 
                      : "bg-amber-50 border-amber-250/50 text-amber-600"
                }`}>
                  {timeLeft === 0 ? (
                    "انتهت صلاحية مهلة التأكيد ⚠️"
                  ) : (
                    `الوقت المتبقي للتأكيد: ${formatTimeLeft(timeLeft)}`
                  )}
                </div>
              )}
              
              <p className="text-slate-500 text-xs sm:text-sm leading-relaxed max-w-xs mx-auto">
                يرجى إرسال تفاصيل حجزك عبر الواتساب لتأكيد الموعد مع الإدارة خلال المهلة الزمنية.
              </p>
              
              <div className="bg-amber-500/5 border border-amber-200/40 rounded-2xl p-4 text-[11px] sm:text-xs text-amber-800 text-right space-y-1">
                <strong>لماذا هذه الخطوة؟</strong>
                <p className="leading-relaxed text-slate-600">
                  لحجز الموعد وتأكيده وضمان عدم إلغائه تلقائياً بعد مرور 60 دقيقة من تسجيل الطلب.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              <a
                href={`https://wa.me/${whatsappNumber.replace("+", "").replace(/\s/g, "").trim()}?text=${encodeURIComponent(
                  `مرحباً،

أرغب في تأكيد الحجز التالي:

📋 رقم الطلب: ${booking?.readable_id || finalBookingId}
🏠 الخدمة: ${booking?.service_snapshot?.title || "خدمة منزلية"}
💰 السعر: ${booking?.price_snapshot?.total || ""} جنيه
📅 التاريخ: ${displayDay.includes('T') ? displayDay.split('T')[0] : displayDay}
⏰ الموعد: ${booking?.start_time_slot ? booking.start_time_slot.substring(0, 5) : "09:00"}
👤 الاسم: ${booking?.contact_name || ""}
📞 الهاتف: ${booking?.contact_phones?.[0] || ""}
📍 المحافظة: ${addressSnap.governorate || ""}
📍 المدينة: ${addressSnap.city || ""}

بإرسال هذه الرسالة أؤكد صحة بيانات الحجز ورغبتي في تنفيذ الخدمة بالسعر الموضح أعلاه. 
شكراً لكم.`
                )}`}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => setShowConfirmModal(false)}
                className="w-full inline-flex items-center justify-center gap-2 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-extrabold py-3.5 px-6 rounded-2xl text-xs sm:text-sm transition-all shadow-md shadow-emerald-500/20 hover:scale-[1.01] active:scale-[0.99] text-center"
              >
                <Send className="w-4 h-4 fill-white" />
                <span>إرسال تفاصيل الحجز وتأكيده عبر واتساب</span>
              </a>
              
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                className="w-full bg-slate-100/80 hover:bg-slate-200/80 text-slate-650 font-bold py-3.5 px-6 rounded-2xl text-xs transition-colors"
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
