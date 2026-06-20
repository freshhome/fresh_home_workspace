"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { 
  ShieldCheck, ArrowLeft, ArrowRight, CheckCircle2, 
  MapPin, Calendar, CreditCard, Clock, Check, ShieldAlert
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";

// Step titles
const STEPS = ["حساب السعر", "اختيار الموعد", "العنوان", "المراجعة والتأكيد"];

function BookingFlowContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  // URL params pre-selection
  const initialServiceId = searchParams.get("serviceId") || "FH-S-100001"; // Default to cleaning
  const initialSubServiceId = searchParams.get("subServiceId") || "";

  // State Management
  const [currentStep, setCurrentStep] = useState(0);
  const [serviceId, setServiceId] = useState(initialServiceId);
  const [subServiceId, setSubServiceId] = useState(initialSubServiceId);

  // DB Loaded Data
  const [mainServices, setMainServices] = useState<any[]>([]);
  const [subServices, setSubServices] = useState<any[]>([]);
  const [selectedSubService, setSelectedSubService] = useState<any>(null);
  const [loadingServices, setLoadingServices] = useState(true);

  // Dynamic Pricing Form Inputs
  const [pricingInputs, setPricingInputs] = useState<Record<string, any>>({});
  const [selectedAddons, setSelectedAddons] = useState<string[]>([]);
  
  // Schedule Address & Phone States
  const [scheduledDate, setScheduledDate] = useState("");
  const [scheduledTime, setScheduledTime] = useState("");
  const [address, setAddress] = useState({
    governorate: "القاهرة",
    city: "المعادي",
    street: "",
    building: "",
    floor: "",
    apartment: ""
  });
  const [phone, setPhone] = useState("");
  const [name, setName] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("cash");

  // OTP Verification States
  const [isOtpSent, setIsOtpSent] = useState(false);
  const [otpCode, setOtpCode] = useState("");
  const [isPhoneVerified, setIsPhoneVerified] = useState(false);
  const [isSubmittingBooking, setIsSubmittingBooking] = useState(false);

  // DB Final Pricing Output State
  const [priceDetails, setPriceDetails] = useState({
    basePrice: 0,
    extraFees: 0,
    discount: 0,
    total: 0,
    metadata: {} as any
  });
  const [isCalculating, setIsCalculating] = useState(false);

  // 1. Fetch main service categories
  useEffect(() => {
    async function fetchMainServices() {
      try {
        const { data, error } = await supabase
          .from("services")
          .select("*")
          .is("parent_id", null)
          .eq("status", "active")
          .order("sort_order", { ascending: true });
        
        if (error) throw error;
        setMainServices(data || []);
      } catch (e) {
        console.error("Error fetching main services:", e);
      }
    }
    fetchMainServices();
  }, []);

  // 2. Fetch sub services for selected main category
  useEffect(() => {
    async function fetchSubServices() {
      if (!serviceId) return;
      setLoadingServices(true);
      try {
        const { data, error } = await supabase
          .from("services")
          .select("*")
          .eq("parent_id", serviceId)
          .eq("is_bookable", true)
          .eq("status", "active")
          .order("sort_order", { ascending: true });
        
        if (error) throw error;
        setSubServices(data || []);

        // Pick initial sub-service
        const initialSub = data?.find((s: any) => s.id === initialSubServiceId) || data?.[0];
        if (initialSub) {
          setSelectedSubService(initialSub);
          setSubServiceId(initialSub.id);
        } else {
          setSelectedSubService(null);
          setSubServiceId("");
        }
      } catch (e) {
        console.error("Error fetching sub services:", e);
      } finally {
        setLoadingServices(false);
      }
    }
    fetchSubServices();
  }, [serviceId]);

  // 3. Initialize pricing input schema defaults when sub-service changes
  useEffect(() => {
    if (selectedSubService?.price_config?.fields) {
      const defaults: Record<string, any> = {};
      selectedSubService.price_config.fields.forEach((field: any) => {
        if (field.type === "number") {
          defaults[field.id] = field.min || 0;
        } else if (field.type === "toggle") {
          defaults[field.id] = false;
        }
      });
      // Set a default area driver if it is per square meter and no min was set
      if (selectedSubService.price_config.type === "per_square_meter" && defaults.area === 0) {
        defaults.area = 100;
      }
      setPricingInputs(defaults);
      setSelectedAddons([]);
    }
  }, [selectedSubService]);

  // 4. Debounced call to DB calculate_booking_price RPC
  useEffect(() => {
    async function calculatePrice() {
      if (!subServiceId || subServiceId.includes("mock") || Object.keys(pricingInputs).length === 0) return;
      setIsCalculating(true);
      
      const inputs = { ...pricingInputs };
      if (selectedAddons.length > 0) {
        inputs.selected_options = selectedAddons;
      }

      try {
        const { data, error } = await supabase.rpc("calculate_booking_price", {
          p_sub_service_id: subServiceId,
          p_pricing_inputs: inputs
        });

        if (error) throw error;
        if (data) {
          setPriceDetails({
            basePrice: Number(data.basePrice) || 0,
            extraFees: Number(data.extraFees) || 0,
            discount: Number(data.discount) || 0,
            total: Number(data.total) || 0,
            metadata: data.metadata || {}
          });
        }
      } catch (e) {
        console.error("Pricing calculation error:", e);
      } finally {
        setIsCalculating(false);
      }
    }

    const timer = setTimeout(() => {
      calculatePrice();
    }, 350);

    return () => clearTimeout(timer);
  }, [subServiceId, pricingInputs, selectedAddons]);

  const handleToggleAddon = (id: string) => {
    if (selectedAddons.includes(id)) {
      setSelectedAddons(selectedAddons.filter((a) => a !== id));
    } else {
      setSelectedAddons([...selectedAddons, id]);
    }
  };

  const handleFieldChange = (fieldId: string, val: any) => {
    setPricingInputs({
      ...pricingInputs,
      [fieldId]: val
    });
  };

  const isStepValid = () => {
    switch (currentStep) {
      case 0:
        return subServiceId !== "" && priceDetails.total > 0;
      case 1:
        return scheduledDate !== "" && scheduledTime !== "";
      case 2:
        return address.street.trim() !== "" && address.building.trim() !== "";
      case 3:
        const phoneRegex = /^(010|011|012|015)\d{8}$/;
        return phoneRegex.test(phone.trim()) && name.trim() !== "";
      default:
        return false;
    }
  };

  const handleNext = () => {
    if (currentStep < STEPS.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  // Mock SMS verification
  const handleSendOtp = () => {
    const phoneRegex = /^(010|011|012|015)\d{8}$/;
    if (!phoneRegex.test(phone.trim())) {
      alert("يرجى إدخال رقم هاتف مصري صحيح مكون من 11 رقم (يبدأ بـ 010 أو 011 أو 012 أو 015)");
      return;
    }
    setIsOtpSent(true);
    alert("تم إرسال كود تفعيل تجريبي (1234) لهاتفك بنجاح!");
  };

  const handleVerifyOtp = () => {
    if (otpCode === "1234") {
      setIsPhoneVerified(true);
      alert("تم تفعيل رقم الهاتف بنجاح!");
    } else {
      alert("كود التفعيل خاطئ. يرجى إدخال (1234) للتجربة.");
    }
  };

  // Complete Booking flow calling create_atomic_booking
  const handleCompleteBooking = async () => {
    setIsSubmittingBooking(true);
    try {
      // 1. Check if there is an active logged-in user session
      let userId: string | null = null;
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        userId = session.user.id;
      }

      // 2. If user is logged in, attempt to register their phone number if not already present
      if (userId) {
        await supabase
          .from("user_phones")
          .insert({
            user_id: userId,
            phone_number: phone.trim(),
            is_primary: true,
            is_verified: true
          });
        // We do not throw on phone insert error for logged-in users to prevent blocking the booking
        // if the phone number already exists or is already linked.
      }

      // 4. Convert chosen time (e.g. "09:00 ص") to 24h format (e.g. "09:00:00")
      let time24 = "09:00:00";
      const timeClean = scheduledTime.replace(" ص", "").replace(" م", "").trim();
      const isPm = scheduledTime.includes("م");
      if (timeClean) {
        const parts = timeClean.split(":");
        let hour = parseInt(parts[0]);
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour === 12) hour = 0;
        time24 = `${hour.toString().padStart(2, '0')}:${parts[1] || '00'}:00`;
      }

      // Build snapshots payloads
      const addressSnapshot = {
        governorate: address.governorate,
        city: address.city,
        street: address.street,
        building_number: address.building,
        floor: address.floor,
        apartment: address.apartment
      };

      const serviceSnapshot = {
        title: selectedSubService?.title?.ar || selectedSubService?.title || "حجز خدمة ويب"
      };

      const pricingPayload = {
        ...pricingInputs,
        selected_options: selectedAddons,
        phone: phone.trim(),
        name: name.trim()
      };

      // 5. Invoke atomic booking transaction RPC
      const { data: bookingId, error: bookingError } = await supabase.rpc("create_atomic_booking", {
        p_user_id: userId,
        p_sub_service_id: subServiceId,
        p_technician_id: null, // Let system auto-assign available technician
        p_scheduled_day: scheduledDate,
        p_address_snapshot: addressSnapshot,
        p_service_snapshot: serviceSnapshot,
        p_pricing_inputs: pricingPayload,
        p_contact_name: name.trim(),
        p_contact_phones: [phone.trim()],
        p_start_time_slot: time24,
        p_is_whatsapp_confirmed: false
      });

      if (bookingError) throw bookingError;

      if (bookingId) {
        router.push(`/orders?bookingId=${bookingId}&success=true`);
      } else {
        throw new Error("فشلت عملية إدراج الحجز في قاعدة البيانات.");
      }
    } catch (e: any) {
      console.error("Booking creation failed:", e);
      alert(`عذراً، حدث خطأ أثناء تأكيد حجزك: ${e.message || JSON.stringify(e)}`);
    } finally {
      setIsSubmittingBooking(false);
    }
  };

  return (
    <>
      <Header />
      
      <main className="flex-1 bg-slate-50 py-10">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Stepper progress */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm mb-8">
            <div className="flex justify-between items-center relative">
              {STEPS.map((stepText, idx) => {
                const isCompleted = idx < currentStep;
                const isActive = idx === currentStep;
                return (
                  <div key={idx} className="flex flex-col items-center z-10 flex-1 relative">
                    <div 
                      className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 ${
                        isCompleted ? "bg-secondary text-white" : isActive ? "bg-primary text-white scale-110" : "bg-slate-100 text-slate-400"
                      }`}
                    >
                      {isCompleted ? <Check className="w-5 h-5 stroke-[2.5]" /> : idx + 1}
                    </div>
                    <span className={`text-[11px] font-bold mt-2 hidden sm:block ${isActive ? "text-primary font-black" : "text-slate-400"}`}>
                      {stepText}
                    </span>
                  </div>
                );
              })}
              
              {/* Connector line */}
              <div className="absolute left-6 right-6 top-[18px] h-0.5 bg-slate-100 -z-0">
                <div 
                  className="h-full bg-secondary transition-all duration-500" 
                  style={{ width: `${(currentStep / (STEPS.length - 1)) * 100}%` }}
                ></div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Step Content */}
            <div className="lg:col-span-8 bg-white rounded-2xl p-6 border border-slate-100 shadow-sm min-h-[400px] flex flex-col justify-between">
              
              {/* STEP 1: PRICING */}
              {currentStep === 0 && (
                <div className="space-y-6">
                  <div>
                    <h2 className="text-xl font-black text-slate-800">تعديل مواصفات وحساب تسعير الخدمة</h2>
                    <p className="text-slate-400 text-xs">أدخل المقاسات الحقيقية والتفاصيل للحصول على سعر نهائي موثوق.</p>
                  </div>
                  
                  {/* Category switcher */}
                  <div className="grid grid-cols-3 gap-3">
                    {mainServices.map((serve) => (
                      <button 
                        key={serve.id}
                        onClick={() => { setServiceId(serve.id); }}
                        className={`p-2.5 rounded-xl border text-xs font-bold text-center transition-all ${serviceId === serve.id ? "border-primary bg-primary/5 text-primary" : "border-slate-200 text-slate-500"}`}
                      >
                        {serve.title?.ar || serve.title}
                      </button>
                    ))}
                  </div>

                  {loadingServices ? (
                    <div className="py-12 flex justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
                    </div>
                  ) : (
                    <div className="space-y-6 pt-4 border-t border-slate-100">
                      {/* Sub-service Selection */}
                      <div className="space-y-2">
                        <label className="block text-sm font-bold text-slate-700">نوع الخدمة الفرعية</label>
                        <div className="grid grid-cols-2 gap-2">
                          {subServices.map((sub) => (
                            <button
                              key={sub.id}
                              onClick={() => { setSelectedSubService(sub); setSubServiceId(sub.id); }}
                              className={`p-3 rounded-xl border text-xs font-bold text-right transition-all ${subServiceId === sub.id ? "border-primary bg-primary/5 text-primary" : "border-slate-200 text-slate-600"}`}
                            >
                              <span className="block font-black">{sub.title?.ar || sub.title}</span>
                              <span className="block text-[9px] text-slate-400 font-normal mt-0.5 leading-normal">{sub.description?.ar || sub.description}</span>
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Dynamic price input fields based on active catalog schema */}
                      {selectedSubService?.price_config?.fields && selectedSubService.price_config.fields.length > 0 ? (
                        <div className="space-y-6 pt-4 border-t border-slate-100">
                          {selectedSubService.price_config.fields.map((field: any) => {
                            if (field.type === "number") {
                              const val = pricingInputs[field.id] || 0;
                              return (
                                <div key={field.id} className="space-y-2">
                                  <div className="flex justify-between items-center">
                                    <label className="block text-xs font-bold text-slate-700">
                                      {field.label?.ar || field.label} {field.unit ? `(${field.unit})` : ""}
                                    </label>
                                    {field.id === "area" && <span className="text-xs font-black text-primary">{val} {field.unit || "م²"}</span>}
                                  </div>
                                  
                                  {field.id === "area" ? (
                                    <div className="space-y-1.5">
                                      <input 
                                        type="range" 
                                        min={field.min || 50} 
                                        max={field.max || 400} 
                                        step={10}
                                        value={val}
                                        onChange={(e) => handleFieldChange(field.id, parseInt(e.target.value))}
                                        className="w-full h-2 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-primary"
                                      />
                                      <div className="flex justify-between text-[10px] text-slate-400 font-bold">
                                        <span>{field.min || 50} {field.unit || "م²"}</span>
                                        <span>{(field.max || 400) / 2} {field.unit || "م²"}</span>
                                        <span>{field.max || 400} {field.unit || "م²"}</span>
                                      </div>
                                    </div>
                                  ) : (
                                    <div className="flex items-center gap-4">
                                      <button 
                                        onClick={() => handleFieldChange(field.id, Math.max(field.min || 0, val - 1))}
                                        className="w-10 h-10 rounded-xl bg-slate-100 font-bold text-lg flex items-center justify-center hover:bg-slate-200"
                                      >
                                        -
                                      </button>
                                      <span className="text-xl font-black w-8 text-center">{val}</span>
                                      <button 
                                        onClick={() => handleFieldChange(field.id, val + 1)}
                                        className="w-10 h-10 rounded-xl bg-slate-100 font-bold text-lg flex items-center justify-center hover:bg-slate-200"
                                      >
                                        +
                                      </button>
                                    </div>
                                  )}
                                  {field.description?.ar && <p className="text-[10px] text-slate-400 leading-normal">{field.description.ar}</p>}
                                </div>
                              );
                            } else if (field.type === "toggle") {
                              const checked = !!pricingInputs[field.id];
                              return (
                                <div 
                                  key={field.id}
                                  onClick={() => handleFieldChange(field.id, !checked)}
                                  className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                                    checked ? "border-primary bg-primary/5 text-primary" : "border-slate-200 hover:border-slate-350"
                                  }`}
                                >
                                  <div className="space-y-0.5 text-right">
                                    <span className="text-xs font-bold text-slate-700 block">{field.label?.ar || field.label}</span>
                                    {field.description?.ar && <span className="text-[10px] text-slate-400 block">{field.description.ar}</span>}
                                  </div>
                                  <div className={`w-4 h-4 rounded-md border flex items-center justify-center transition-all ${
                                    checked ? "bg-primary border-primary text-white" : "border-slate-300 bg-white"
                                  }`}>
                                    {checked && <Check className="w-3 h-3 stroke-[3]" />}
                                  </div>
                                </div>
                              );
                            }
                            return null;
                          })}
                        </div>
                      ) : (
                        <div className="text-center text-xs text-slate-400 py-6">اختر خدمة لعرض خيارات تسعيرها التفصيلية.</div>
                      )}

                      {/* Add-ons selection */}
                      {selectedSubService?.price_config?.options && selectedSubService.price_config.options.length > 0 && (
                        <div className="space-y-3 pt-4 border-t border-slate-150">
                          <label className="block text-sm font-bold text-slate-700">خيارات وخدمات إضافية مقترحة</label>
                          <div className="space-y-2">
                            {selectedSubService.price_config.options.map((addon: any) => {
                              const isSelected = selectedAddons.includes(addon.key);
                              return (
                                <div 
                                  key={addon.key}
                                  onClick={() => handleToggleAddon(addon.key)}
                                  className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                                    isSelected ? "border-primary bg-primary/5 text-primary" : "border-slate-200 hover:border-slate-350"
                                  }`}
                                >
                                  <div className="flex items-center gap-3">
                                    <div className={`w-4 h-4 rounded-md border flex items-center justify-center transition-all ${
                                      isSelected ? "bg-primary border-primary text-white" : "border-slate-300 bg-white"
                                    }`}>
                                      {isSelected && <Check className="w-3 h-3 stroke-[3]" />}
                                    </div>
                                    <span className="text-xs font-bold text-slate-700">{addon.key}</span>
                                  </div>
                                  <span className="text-xs font-black text-slate-500">+{addon.value} ج.م</span>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* STEP 2: SCHEDULE */}
              {currentStep === 1 && (
                <div className="space-y-6">
                  <div>
                    <h2 className="text-xl font-black text-slate-800">اختر موعد وصول الفني المناسب</h2>
                    <p className="text-slate-400 text-xs">حدد اليوم والفترة الزمنية لتلبية الطلب.</p>
                  </div>

                  {/* Dates list (mocking next 7 days) */}
                  <div className="space-y-3">
                    <label className="block text-sm font-bold text-slate-700">الأيام المتاحة للحجز</label>
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                      {Array.from({ length: 8 }).map((_, i) => {
                        const dateObj = new Date();
                        dateObj.setDate(dateObj.getDate() + i + 1);
                        const formatted = dateObj.toISOString().split("T")[0];
                        const dayName = dateObj.toLocaleDateString("ar-EG", { weekday: "long" });
                        const dateLabel = dateObj.toLocaleDateString("ar-EG", { day: "numeric", month: "short" });

                        return (
                          <div
                            key={formatted}
                            onClick={() => setScheduledDate(formatted)}
                            className={`p-3 rounded-xl border text-center cursor-pointer transition-all flex flex-col justify-center gap-1 ${
                              scheduledDate === formatted 
                                ? "bg-primary border-primary text-white shadow-md shadow-primary/10" 
                                : "bg-white border-slate-200 hover:border-slate-300 text-slate-600"
                            }`}
                          >
                            <span className="text-[10px] block opacity-85 font-bold">{dayName}</span>
                            <span className="text-xs block font-black">{dateLabel}</span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Time Slots */}
                  <div className="space-y-3 pt-4 border-t border-slate-150">
                    <label className="block text-sm font-bold text-slate-700">الفترات الزمنية المتاحة لوصول الفني</label>
                    <div className="grid grid-cols-3 gap-2">
                      {["09:00 ص", "11:00 ص", "01:00 م", "03:00 م", "05:00 م"].map((time) => (
                        <div
                          key={time}
                          onClick={() => setScheduledTime(time)}
                          className={`p-3.5 rounded-xl border text-center cursor-pointer font-bold text-xs transition-all ${
                            scheduledTime === time 
                              ? "bg-primary border-primary text-white shadow-md shadow-primary/10" 
                              : "bg-white border-slate-200 hover:border-slate-300 text-slate-600"
                          }`}
                        >
                          {time}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* STEP 3: ADDRESS */}
              {currentStep === 2 && (
                <div className="space-y-6">
                  <div>
                    <h2 className="text-xl font-black text-slate-800">تفاصيل عنوان تسليم الخدمة</h2>
                    <p className="text-slate-400 text-xs">يرجى كتابة تفاصيل العنوان بدقة لسهولة وصول الفني.</p>
                  </div>

                  {/* Map Mock UI */}
                  <div className="w-full h-44 rounded-2xl bg-slate-200 border border-slate-300 overflow-hidden relative flex items-center justify-center text-slate-500 shadow-inner">
                    <div className="absolute inset-0 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] [background-size:16px_16px]"></div>
                    <div className="absolute w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary scale-125 z-10 animate-bounce">
                      <MapPin className="w-4 h-4 fill-primary" />
                    </div>
                    <span className="text-[10px] font-black z-10 bg-white border border-slate-200 text-slate-700 px-3 py-1.5 rounded-full shadow-sm">
                      تم تحديد الموقع تلقائياً بالـ GPS كضيف
                    </span>
                  </div>

                  {/* Manual form input fields */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">المحافظة</label>
                      <select 
                        value={address.governorate}
                        onChange={(e) => setAddress({...address, governorate: e.target.value})}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-primary focus:outline-none"
                      >
                        <option>القاهرة</option>
                        <option>الجيزة</option>
                        <option>القليوبية</option>
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">المنطقة / المدينة</label>
                      <input 
                        type="text"
                        value={address.city}
                        onChange={(e) => setAddress({...address, city: e.target.value})}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white"
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-600">اسم الشارع</label>
                    <input 
                      type="text"
                      placeholder="مثال: شارع 9، أمام مدرسة النصر"
                      value={address.street}
                      onChange={(e) => setAddress({...address, street: e.target.value})}
                      className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white"
                    />
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">رقم المبنى</label>
                      <input 
                        type="text"
                        value={address.building}
                        onChange={(e) => setAddress({...address, building: e.target.value})}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">رقم الدور</label>
                      <input 
                        type="text"
                        value={address.floor}
                        onChange={(e) => setAddress({...address, floor: e.target.value})}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">رقم الشقة</label>
                      <input 
                        type="text"
                        value={address.apartment}
                        onChange={(e) => setAddress({...address, apartment: e.target.value})}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* STEP 4: REVIEW & CONFIRM (Guest OTP Checkout) */}
              {currentStep === 3 && (
                <div className="space-y-6">
                  <div>
                    <h2 className="text-xl font-black text-slate-800">مراجعة البيانات والتحقق كضيف</h2>
                    <p className="text-slate-400 text-xs">يرجى كتابة الاسم ورقم الهاتف لإتمام حجزك كضيف.</p>
                  </div>

                  {/* Name and Phone Inputs */}
                  <div className="space-y-4 bg-slate-50 p-4 rounded-xl border border-slate-200/60">
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">الاسم بالكامل</label>
                      <input 
                        type="text"
                        placeholder="اكتب اسمك بالكامل"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white"
                      />
                    </div>

                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-slate-600">رقم الهاتف (الواتساب)</label>
                      <input 
                        type="tel"
                        placeholder="مثال: 01012345678"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white"
                      />
                    </div>
                  </div>

                  {/* Payment options */}
                  <div className="space-y-3">
                    <label className="block text-sm font-bold text-slate-700">طريقة الدفع المقترحة</label>
                    <div className="grid grid-cols-2 gap-3">
                      <div 
                        onClick={() => setPaymentMethod("cash")}
                        className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                          paymentMethod === "cash" ? "border-primary bg-primary/5 text-primary" : "border-slate-200 hover:border-slate-350"
                        }`}
                      >
                        <span className="text-xs font-bold">نقداً عند انتهاء الخدمة (كاش)</span>
                        <div className={`w-4 h-4 rounded-full border-4 ${paymentMethod === "cash" ? "border-primary" : "border-slate-300"}`}></div>
                      </div>
                      <div 
                        onClick={() => setPaymentMethod("instapay")}
                        className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                          paymentMethod === "instapay" ? "border-primary bg-primary/5 text-primary" : "border-slate-200 hover:border-slate-350"
                        }`}
                      >
                        <span className="text-xs font-bold">تحويل إنستا باي / فودافون كاش</span>
                        <div className={`w-4 h-4 rounded-full border-4 ${paymentMethod === "instapay" ? "border-primary" : "border-slate-300"}`}></div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Navigation Actions */}
              <div className="flex justify-between items-center pt-6 border-t border-slate-100 mt-8">
                {currentStep > 0 ? (
                  <button 
                    onClick={handleBack}
                    className="flex items-center gap-1 text-xs font-bold text-slate-500 hover:text-slate-700 transition-colors"
                  >
                    <ArrowRight className="w-4 h-4 rotate-180" />
                    <span>الرجوع للخلف</span>
                  </button>
                ) : (
                  <Link href="/" className="text-xs text-slate-400 hover:text-slate-500">
                    إلغاء والعودة للرئيسية
                  </Link>
                )}

                {currentStep < STEPS.length - 1 ? (
                  <button 
                    onClick={handleNext}
                    disabled={!isStepValid()}
                    className="flex items-center gap-1.5 bg-primary disabled:bg-slate-200 text-white disabled:text-slate-400 font-extrabold px-6 py-2.5 rounded-xl text-xs shadow-md disabled:shadow-none animate-all"
                  >
                    <span>الخطوة التالية</span>
                    <ArrowLeft className="w-4 h-4 rotate-180" />
                  </button>
                ) : (
                  <button 
                    onClick={handleCompleteBooking}
                    disabled={!isStepValid() || isSubmittingBooking}
                    className="flex items-center gap-2 bg-secondary disabled:bg-slate-200 text-slate-900 disabled:text-slate-400 font-black px-8 py-3 rounded-xl text-sm shadow-md disabled:shadow-none"
                  >
                    {isSubmittingBooking ? (
                      <span>جاري إتمام حجزك...</span>
                    ) : (
                      <>
                        <ShieldCheck className="w-5 h-5 stroke-[2]" />
                        <span>تأكيد وإتمام الحجز النهائي</span>
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>

            {/* Price invoice details block */}
            <div className="lg:col-span-4 space-y-6">
              <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-4">
                <h3 className="font-extrabold text-slate-800 text-base border-b border-slate-100 pb-3">ملخص الفاتورة المعتمدة</h3>
                
                <div className="space-y-3.5 text-xs text-slate-600">
                  <div className="flex justify-between items-start gap-3">
                    <span className="font-bold">الخدمة:</span>
                    <span className="text-left font-extrabold text-primary">
                      {selectedSubService?.title?.ar || selectedSubService?.title || "حساب السعر للخدمة..."}
                    </span>
                  </div>

                  {/* Render input specs breakdown */}
                  {Object.entries(pricingInputs).map(([k, v]) => {
                    const field = selectedSubService?.price_config?.fields?.find((f: any) => f.id === k);
                    if (!field || v === 0 || v === false) return null;
                    return (
                      <div key={k} className="flex justify-between">
                        <span className="font-bold">{field.label?.ar || field.label}:</span>
                        <span className="font-black text-slate-800">
                          {typeof v === "boolean" ? "نعم" : `${v} ${field.unit || ""}`}
                        </span>
                      </div>
                    );
                  })}
                  
                  {/* Selected Addons invoice display */}
                  {selectedAddons.length > 0 && selectedSubService?.price_config?.options && (
                    <div className="space-y-1.5 border-t border-slate-100 pt-3">
                      <span className="font-bold block text-slate-400">الإضافات المحددة:</span>
                      {selectedAddons.map((addId) => {
                        const addon = selectedSubService.price_config.options.find((a: any) => a.key === addId);
                        if (!addon) return null;
                        return (
                          <div key={addId} className="flex justify-between text-[11px] font-semibold text-slate-500">
                            <span>- {addon.key}</span>
                            <span className="font-bold">+{addon.value} ج.م</span>
                          </div>
                        );
                      })}
                    </div>
                  )}
                  
                  {/* Date & Time if selected */}
                  {(scheduledDate || scheduledTime) && (
                    <div className="space-y-2 border-t border-slate-100 pt-3">
                      <span className="font-bold block text-slate-400">الموعد المحدد:</span>
                      {scheduledDate && (
                        <div className="flex items-center gap-1.5 text-[11px] font-bold text-slate-800">
                          <Calendar className="w-3.5 h-3.5 text-secondary" />
                          <span>{scheduledDate}</span>
                        </div>
                      )}
                      {scheduledTime && (
                        <div className="flex items-center gap-1.5 text-[11px] font-bold text-slate-800">
                          <Clock className="w-3.5 h-3.5 text-secondary" />
                          <span>بين الساعة {scheduledTime}</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Governorate and city if step > 2 */}
                  {currentStep >= 3 && address.street && (
                    <div className="space-y-2 border-t border-slate-100 pt-3">
                      <span className="font-bold block text-slate-400">العنوان:</span>
                      <div className="flex items-start gap-1.5 text-[11px] text-slate-800 font-semibold leading-relaxed">
                        <MapPin className="w-3.5 h-3.5 text-secondary mt-0.5 shrink-0" />
                        <span>{address.governorate}، {address.city}، {address.street}، عمارة {address.building}</span>
                      </div>
                    </div>
                  )}
                </div>

                <div className="border-t border-slate-150 pt-4 space-y-2">
                  <div className="flex justify-between text-xs text-slate-500 font-semibold">
                    <span>قيمة الخدمة الأساسية والإضافات:</span>
                    <span>{isCalculating ? "..." : `${priceDetails.basePrice + priceDetails.extraFees} ج.م`}</span>
                  </div>
                  {priceDetails.discount > 0 && (
                    <div className="flex justify-between text-xs text-emerald-600 font-semibold">
                      <span>خصومات مطبقة:</span>
                      <span>-{priceDetails.discount} ج.م</span>
                    </div>
                  )}
                  <div className="flex justify-between text-xs text-slate-500 font-semibold">
                    <span>ضريبة القيمة المضافة (14%):</span>
                    <span>{isCalculating ? "..." : `${Math.round((priceDetails.basePrice + priceDetails.extraFees - priceDetails.discount) * 0.14)} ج.م`}</span>
                  </div>
                  <div className="flex justify-between text-base font-black text-primary border-t border-dashed border-slate-200 pt-3.5">
                    <span>إجمالي القيمة:</span>
                    <span>{isCalculating ? "جاري الحساب..." : `${priceDetails.total} ج.م`}</span>
                  </div>
                </div>
              </div>

              {/* Security guarantee box */}
              <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-5 flex gap-3 text-xs text-slate-600">
                <ShieldAlert className="w-5 h-5 text-secondary shrink-0 mt-0.5" />
                <div className="space-y-1">
                  <strong className="block text-slate-800">ضمان الأسعار المعتمد</strong>
                  <p className="leading-relaxed font-light text-slate-500">
                    الأسعار موضحة بشفافية وتخضع لقواعد التسعير الرسمية المعتمدة لشركة فريش هوم. لن يطلب منك الفني دفع أي مبالغ إضافية بخلاف الفاتورة الموضحة.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
      
      <Footer />
    </>
  );
}

export default function BookingFlow() {
  return (
    <Suspense fallback={
      <div className="flex-1 bg-slate-50 py-10 flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
      </div>
    }>
      <BookingFlowContent />
    </Suspense>
  );
}
