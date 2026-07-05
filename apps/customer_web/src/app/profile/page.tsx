"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  User, MapPin, Phone, Clock, AlertCircle, 
  CheckCircle, Plus, Trash2, ShieldCheck, LogOut, ChevronLeft 
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

const REGIONS_MAP: Record<string, string[]> = {
  "القاهرة": [
    "الزمالك",
    "جاردن سيتي",
    "المعادي",
    "مصر الجديدة",
    "التجمع الخامس",
    "القاهرة الجديدة",
    "الرحاب",
    "مدينتي",
    "مدينة نصر",
    "المقطم",
    "الشروق",
    "أخرى"
  ],
  "الجيزة": [
    "الشيخ زايد",
    "6 أكتوبر",
    "المهندسين",
    "الدقي",
    "العجوزة",
    "حدائق الأهرام",
    "الهرم",
    "فيصل",
    "إمبابة",
    "أخرى"
  ]
};

function ProfileContent() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState("info"); // info | addresses | phones | bookings
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // Profile fields state
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [updatingProfile, setUpdatingProfile] = useState(false);
  const [profileSuccess, setProfileSuccess] = useState("");

  // Phone numbers state
  const [phones, setPhones] = useState<any[]>([]);
  const [newPhone, setNewPhone] = useState("");
  const [addingPhone, setAddingPhone] = useState(false);
  const [phoneError, setPhoneError] = useState("");

  // Addresses state
  const [addresses, setAddresses] = useState<any[]>([]);
  const [addingAddress, setAddingAddress] = useState(false);
  const [newAddress, setNewAddress] = useState({
    governorate: "القاهرة",
    city: "المعادي",
    street: "",
    building: "",
    floor: "",
    apartment: "",
  });
  const [addressError, setAddressError] = useState("");

  // Bookings state
  const [bookings, setBookings] = useState<any[]>([]);
  const [loadingBookings, setLoadingBookings] = useState(false);

  // Authenticate user & load initial details
  useEffect(() => {
    async function loadSession() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push("/login?redirect=/profile");
        return;
      }
      setUser(session.user);

      // Load name from public.profiles table (Single Source of Truth)
      try {
        const { data: profileData, error: profileError } = await supabase
          .from("profiles")
          .select("first_name, last_name")
          .eq("id", session.user.id)
          .single();
        
        if (!profileError && profileData) {
          setFirstName(profileData.first_name || "");
          setLastName(profileData.last_name || "");
        } else {
          setFirstName(session.user.user_metadata?.first_name || "");
          setLastName(session.user.user_metadata?.last_name || "");
        }
      } catch (e) {
        console.error("Error loading profiles name:", e);
        setFirstName(session.user.user_metadata?.first_name || "");
        setLastName(session.user.user_metadata?.last_name || "");
      }

      setLoading(false);
      
      // Load tables asynchronously
      loadPhones(session.user.id);
      loadAddresses(session.user.id);
      loadBookings(session.user.id);
    }
    loadSession();
  }, [router]);

  // Load phones
  async function loadPhones(userId: string) {
    try {
      const { data, error } = await supabase
        .from("user_phones")
        .select("*")
        .eq("user_id", userId)
        .order("is_primary", { ascending: false });
      if (!error && data) {
        setPhones(data);
      }
    } catch (e) {
      console.error(e);
    }
  }

  // Load addresses
  async function loadAddresses(userId: string) {
    try {
      const { data, error } = await supabase
        .from("user_addresses")
        .select("*")
        .eq("user_id", userId)
        .order("is_primary", { ascending: false });
      if (!error && data) {
        setAddresses(data);
      }
    } catch (e) {
      console.error(e);
    }
  }

  // Load bookings
  async function loadBookings(userId: string) {
    setLoadingBookings(true);
    try {
      const { data, error } = await supabase
        .from("bookings")
        .select(`
          id, 
          status, 
          created_at, 
          scheduled_day, 
          start_time_slot, 
          contact_name, 
          service_snapshot, 
          pricing_inputs
        `)
        .eq("user_id", userId)
        .order("created_at", { ascending: false });
      
      if (!error && data) {
        setBookings(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingBookings(false);
    }
  }

  // Update profile handler
  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSuccess("");
    setUpdatingProfile(true);

    try {
      // 1. Update public.profiles table directly (Single Source of Truth)
      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          first_name: firstName.trim(),
          last_name: lastName.trim()
        })
        .eq("id", user.id);
      
      if (profileError) throw profileError;

      // 2. Update auth metadata for consistency
      const { data, error } = await supabase.auth.updateUser({
        data: {
          first_name: firstName.trim(),
          last_name: lastName.trim()
        }
      });

      if (error) throw error;

      setUser(data.user);
      setProfileSuccess("تم تحديث بيانات ملفك الشخصي بنجاح.");
    } catch (err: any) {
      console.error("Update profile error:", err);
      alert("فشل تحديث البيانات: " + err.message);
    } finally {
      setUpdatingProfile(false);
    }
  };

  // Add phone handler
  const handleAddPhone = async (e: React.FormEvent) => {
    e.preventDefault();
    setPhoneError("");
    const phoneClean = newPhone.trim();
    const phoneRegex = /^(010|011|012|015)\d{8}$/;

    if (!phoneRegex.test(phoneClean)) {
      setPhoneError("رقم الهاتف غير صحيح. أدخل رقم محمول مصري مكون من 11 رقماً.");
      return;
    }

    setAddingPhone(true);
    try {
      const { error } = await supabase
        .from("user_phones")
        .insert({
          user_id: user.id,
          phone_number: phoneClean,
          is_primary: phones.length === 0, // Mark as primary if it's the first number
          is_verified: true
        });

      if (error) throw error;

      setNewPhone("");
      loadPhones(user.id);
    } catch (err: any) {
      console.error("Add phone error:", err);
      setPhoneError(err.message || "فشل إدراج رقم الهاتف. قد يكون مضافاً مسبقاً.");
    } finally {
      setAddingPhone(false);
    }
  };

  // Delete phone handler
  const handleDeletePhone = async (phoneId: string) => {
    if (!confirm("هل أنت متأكد من حذف رقم الهاتف هذا؟")) return;
    try {
      const { error } = await supabase
        .from("user_phones")
        .delete()
        .eq("id", phoneId);
      if (error) throw error;
      loadPhones(user.id);
    } catch (err: any) {
      alert("فشل الحذف: " + err.message);
    }
  };

  // Add address handler
  const handleAddAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddressError("");

    if (!newAddress.street.trim() || !newAddress.building.trim()) {
      setAddressError("يرجى ملء اسم الشارع ورقم المبنى.");
      return;
    }

    setAddingAddress(true);
    try {
      const { error } = await supabase
        .from("user_addresses")
        .insert({
          user_id: user.id,
          governorate: newAddress.governorate,
          city: newAddress.city,
          street: newAddress.street.trim(),
          building_number: newAddress.building.trim(),
          floor: newAddress.floor.trim(),
          apartment: newAddress.apartment.trim(),
          is_primary: addresses.length === 0,
        });

      if (error) throw error;

      setNewAddress({
        governorate: "القاهرة",
        city: "المعادي",
        street: "",
        building: "",
        floor: "",
        apartment: "",
      });
      loadAddresses(user.id);
    } catch (err: any) {
      console.error("Add address error:", err);
      setAddressError(err.message || "حدث خطأ أثناء حفظ العنوان.");
    } finally {
      setAddingAddress(false);
    }
  };

  // Delete address handler
  const handleDeleteAddress = async (addressId: string) => {
    if (!confirm("هل أنت متأكد من حذف هذا العنوان؟")) return;
    try {
      const { error } = await supabase
        .from("user_addresses")
        .delete()
        .eq("id", addressId);
      if (error) throw error;
      loadAddresses(user.id);
    } catch (err: any) {
      alert("فشل الحذف: " + err.message);
    }
  };

  // Set primary phone handler
  const handleSetPrimaryPhone = async (phoneId: string) => {
    try {
      await supabase
        .from("user_phones")
        .update({ is_primary: false })
        .eq("user_id", user.id);
      
      const { error } = await supabase
        .from("user_phones")
        .update({ is_primary: true })
        .eq("id", phoneId);
      
      if (error) throw error;
      loadPhones(user.id);
    } catch (err: any) {
      alert("فشل تعيين الرقم كأولوي: " + err.message);
    }
  };

  // Set primary address handler
  const handleSetPrimaryAddress = async (addressId: string) => {
    try {
      await supabase
        .from("user_addresses")
        .update({ is_primary: false })
        .eq("user_id", user.id);
      
      const { error } = await supabase
        .from("user_addresses")
        .update({ is_primary: true })
        .eq("id", addressId);
      
      if (error) throw error;
      loadAddresses(user.id);
    } catch (err: any) {
      alert("فشل تعيين العنوان كأولوي: " + err.message);
    }
  };

  // Handle LogOut
  const handleLogOut = async () => {
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  };

  if (loading) {
    return (
      <div className="py-24 flex justify-center items-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-10 text-right">
      {/* Title section */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-200 pb-6 mb-8">
        <div>
          <h1 className="text-2xl font-black text-slate-800">الملف الشخصي والحساب</h1>
          <p className="text-slate-400 text-xs mt-1">أهلاً بك، يمكنك إدارة بياناتك وعناوينك وتتبع سجل حجوزاتك هنا.</p>
        </div>
        <button
          onClick={handleLogOut}
          className="flex items-center gap-2 p-2 px-4 rounded-xl border border-rose-200 text-rose-600 hover:bg-rose-50 text-xs font-bold transition-all cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
          <span>تسجيل الخروج</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Navigation Sidebar */}
        <aside className="lg:col-span-3 space-y-2 bg-white p-4 rounded-2xl border border-slate-200/60 shadow-xs">
          <button
            onClick={() => setActiveTab("info")}
            className={`w-full flex items-center gap-3 p-3 rounded-xl text-xs font-bold transition-all ${
              activeTab === "info" ? "bg-primary text-white" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <User className="w-4 h-4 shrink-0" />
            <span>البيانات الأساسية</span>
          </button>
          <button
            onClick={() => setActiveTab("phones")}
            className={`w-full flex items-center gap-3 p-3 rounded-xl text-xs font-bold transition-all ${
              activeTab === "phones" ? "bg-primary text-white" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <Phone className="w-4 h-4 shrink-0" />
            <span>أرقام الهاتف</span>
          </button>
          <button
            onClick={() => setActiveTab("addresses")}
            className={`w-full flex items-center gap-3 p-3 rounded-xl text-xs font-bold transition-all ${
              activeTab === "addresses" ? "bg-primary text-white" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <MapPin className="w-4 h-4 shrink-0" />
            <span>العناوين المحفوظة</span>
          </button>
          <button
            onClick={() => setActiveTab("bookings")}
            className={`w-full flex items-center gap-3 p-3 rounded-xl text-xs font-bold transition-all ${
              activeTab === "bookings" ? "bg-primary text-white" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <Clock className="w-4 h-4 shrink-0" />
            <span>سجل الحجوزات</span>
          </button>
        </aside>

        {/* Dynamic Panels */}
        <section className="lg:col-span-9 bg-white rounded-2xl border border-slate-200/60 p-6 shadow-xs min-h-[380px]">
          
          {/* TAB 1: BASIC INFO */}
          {activeTab === "info" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-800">البيانات الأساسية لحسابك</h3>
                <p className="text-slate-400 text-xs">تحديث اسمك ومعلومات الاتصال الأساسية.</p>
              </div>

              {profileSuccess && (
                <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-700 text-xs font-bold flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-emerald-600" />
                  <span>{profileSuccess}</span>
                </div>
              )}

              <form onSubmit={handleUpdateProfile} className="space-y-4 max-w-lg">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-600">الاسم الأول</label>
                    <input 
                      type="text" 
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-600">الاسم الأخير</label>
                    <input 
                      type="text" 
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800"
                      required
                    />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-bold text-slate-400">البريد الإلكتروني (غير قابل للتعديل)</label>
                  <input 
                    type="email" 
                    value={user?.email || ""}
                    disabled
                    className="w-full p-2.5 rounded-xl border border-slate-100 bg-slate-50 text-slate-400 text-xs font-bold focus:outline-none text-left"
                  />
                </div>

                <button
                  type="submit"
                  disabled={updatingProfile}
                  className="py-2.5 px-6 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md shadow-primary/10 hover:bg-primary/95 transition-all active:scale-[0.99] disabled:opacity-50"
                >
                  {updatingProfile ? "جاري التحديث..." : "حفظ التغييرات"}
                </button>
              </form>
            </div>
          )}

          {/* TAB 2: PHONES */}
          {activeTab === "phones" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-800">إدارة أرقام الهواتف</h3>
                <p className="text-slate-400 text-xs">أرقام الهواتف المستخدمة لتأكيد طلباتك والتواصل معك عبر واتساب.</p>
              </div>

              {phoneError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-100 text-rose-700 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{phoneError}</span>
                </div>
              )}

              {/* Add phone number form */}
              <form onSubmit={handleAddPhone} className="flex gap-2 items-end max-w-md">
                <div className="flex-1 space-y-1.5">
                  <label className="block text-xs font-bold text-slate-600">إضافة رقم هاتف جديد</label>
                  <input 
                    type="tel" 
                    placeholder="مثال: 01012345678"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800 text-left"
                    required
                  />
                </div>
                <button
                  type="submit"
                  disabled={addingPhone}
                  className="p-2.5 rounded-xl bg-primary hover:bg-primary/95 text-white font-extrabold text-xs shadow-md transition-all shrink-0 flex items-center gap-1.5 cursor-pointer h-[41px]"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة</span>
                </button>
              </form>

              {/* Phones List */}
              <div className="space-y-2 pt-4 border-t border-slate-100 max-w-lg">
                {phones.length === 0 ? (
                  <p className="text-xs font-bold text-slate-400 py-4">لم تقم بإضافة أي أرقام هواتف حتى الآن.</p>
                ) : (
                  phones.map((p) => (
                    <div key={p.id} className="flex items-center justify-between p-3 rounded-xl border border-slate-100 bg-slate-50/50">
                      <div className="flex items-center gap-3">
                        <span className="text-xs font-black text-slate-700 font-sans tracking-wide">{p.phone_number}</span>
                        {p.is_primary ? (
                          <span className="text-[9px] font-black text-secondary bg-secondary/10 px-2 py-0.5 rounded-full">
                            الرقم الأساسي
                          </span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => handleSetPrimaryPhone(p.id)}
                            className="text-[9px] font-bold text-slate-400 hover:text-primary hover:underline transition-colors cursor-pointer"
                          >
                            تعيين كأساسي
                          </button>
                        )}
                      </div>
                      {!p.is_primary && (
                        <button
                          onClick={() => handleDeletePhone(p.id)}
                          className="text-slate-400 hover:text-rose-600 p-1 transition-colors cursor-pointer"
                          title="حذف الرقم"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* TAB 3: ADDRESSES */}
          {activeTab === "addresses" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-800">إدارة العناوين المسجلة</h3>
                <p className="text-slate-400 text-xs">احفظ عناوينك لتسريع عملية حجز الخدمات وتعبئتها تلقائياً.</p>
              </div>

              {addressError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-100 text-rose-700 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{addressError}</span>
                </div>
              )}

              {/* Add Address Form */}
              <form onSubmit={handleAddAddress} className="bg-slate-50/50 p-4 rounded-xl border border-slate-100 space-y-4 max-w-xl">
                <span className="block text-xs font-black text-slate-700">إضافة عنوان تسليم جديد</span>
                
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1.5">
                    <label className="block text-[10px] font-bold text-slate-500">المحافظة</label>
                    <select 
                      value={newAddress.governorate}
                      onChange={(e) => {
                        const gov = e.target.value;
                        const defaultCity = REGIONS_MAP[gov]?.[0] || "";
                        setNewAddress({ ...newAddress, governorate: gov, city: defaultCity });
                      }}
                      className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:outline-none"
                    >
                      {Object.keys(REGIONS_MAP).map((g) => (
                        <option key={g} value={g}>{g}</option>
                      ))}
                    </select>
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-[10px] font-bold text-slate-500">المنطقة</label>
                    <select 
                      value={newAddress.city}
                      onChange={(e) => setNewAddress({ ...newAddress, city: e.target.value })}
                      className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:outline-none"
                    >
                      {(REGIONS_MAP[newAddress.governorate] || []).map((c) => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-[10px] font-bold text-slate-500">اسم الشارع</label>
                  <input 
                    type="text" 
                    placeholder="مثال: شارع 9، أمام بنك مصر"
                    value={newAddress.street}
                    onChange={(e) => setNewAddress({ ...newAddress, street: e.target.value })}
                    className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800"
                    required
                  />
                </div>

                <div className="grid grid-cols-3 gap-2">
                  <div className="space-y-1.5">
                    <label className="block text-[10px] font-bold text-slate-500">رقم المبنى</label>
                    <input 
                      type="text"
                      value={newAddress.building}
                      onChange={(e) => setNewAddress({ ...newAddress, building: e.target.value })}
                      className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-[10px] font-bold text-slate-500">رقم الدور</label>
                    <input 
                      type="text"
                      value={newAddress.floor}
                      onChange={(e) => setNewAddress({ ...newAddress, floor: e.target.value })}
                      className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-[10px] font-bold text-slate-500">رقم الشقة</label>
                    <input 
                      type="text"
                      value={newAddress.apartment}
                      onChange={(e) => setNewAddress({ ...newAddress, apartment: e.target.value })}
                      className="w-full p-2 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none text-center bg-white"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={addingAddress}
                  className="py-2 px-5 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md hover:bg-primary/95 transition-all cursor-pointer"
                >
                  {addingAddress ? "جاري الحفظ..." : "حفظ العنوان"}
                </button>
              </form>

              {/* Address List */}
              <div className="space-y-3 pt-4 border-t border-slate-100 max-w-xl">
                {addresses.length === 0 ? (
                  <p className="text-xs font-bold text-slate-400 py-4">لم تقم بإضافة أي عناوين حتى الآن.</p>
                ) : (
                  addresses.map((addr) => (
                    <div key={addr.id} className="flex items-center justify-between p-3.5 rounded-xl border border-slate-100 bg-slate-50/50">
                      <div className="space-y-1 text-right">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-black text-slate-800">
                            {addr.governorate}، {addr.city}
                          </span>
                          {addr.is_primary ? (
                            <span className="text-[9px] font-black text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100">
                              الأساسي
                            </span>
                          ) : (
                            <button
                              type="button"
                              onClick={() => handleSetPrimaryAddress(addr.id)}
                              className="text-[9px] font-bold text-slate-400 hover:text-primary hover:underline transition-colors cursor-pointer"
                            >
                              تعيين كأساسي
                            </button>
                          )}
                        </div>
                        <p className="text-[10px] font-bold text-slate-500">
                          {addr.street} - مبنى {addr.building_number} {addr.floor ? `- الدور ${addr.floor}` : ""} {addr.apartment ? `- شقة ${addr.apartment}` : ""}
                        </p>
                      </div>
                      {!addr.is_primary && (
                        <button
                          onClick={() => handleDeleteAddress(addr.id)}
                          className="text-slate-400 hover:text-rose-600 p-1 transition-colors cursor-pointer"
                          title="حذف العنوان"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* TAB 4: BOOKING HISTORY */}
          {activeTab === "bookings" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-800">سجل حجوزات الخدمات</h3>
                <p className="text-slate-400 text-xs">قائمة بالخدمات التي قمت بطلبها وحالة تتبعها.</p>
              </div>

              {loadingBookings ? (
                <div className="py-12 flex justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
                </div>
              ) : bookings.length === 0 ? (
                <div className="py-12 text-center text-slate-400 space-y-2">
                  <Clock className="w-8 h-8 mx-auto text-slate-350" />
                  <p className="text-xs font-bold">لا توجد حجوزات مسجلة تحت حسابك بعد.</p>
                  <Link href="/" className="text-primary font-black text-xs hover:underline inline-block mt-2">
                    احجز أولى خدماتك الآن من هنا
                  </Link>
                </div>
              ) : (
                <div className="space-y-3">
                  {bookings.map((b) => {
                    const servTitle = b.service_snapshot?.title || "خدمة منزلية";
                    const isCompleted = b.status === "completed";
                    const isCancelled = b.status === "cancelled";
                    const createdDate = new Date(b.created_at).toLocaleDateString("ar-EG", {
                      day: "numeric",
                      month: "short",
                      year: "numeric"
                    });
                    
                    return (
                      <div key={b.id} className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl border border-slate-150 bg-white/80 hover:bg-slate-50/50 hover:border-slate-300 transition-all gap-4">
                        <div className="space-y-1 text-right">
                          <div className="flex items-center gap-2.5 flex-wrap">
                            <span className="text-xs font-black text-slate-800">{servTitle}</span>
                            <span className="text-[9px] text-slate-400 font-bold">({createdDate})</span>
                          </div>
                          <div className="text-[10px] text-slate-500 font-bold flex items-center gap-3">
                            <span>موعد الزيارة: {b.scheduled_day}</span>
                            <span>الساعة: {b.start_time_slot}</span>
                          </div>
                        </div>

                        <div className="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end border-t sm:border-t-0 pt-2 sm:pt-0">
                          {/* Status Badge */}
                          <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full border ${
                            isCompleted 
                              ? "bg-emerald-50 border-emerald-100 text-emerald-700" 
                              : isCancelled 
                                ? "bg-rose-50 border-rose-100 text-rose-700" 
                                : "bg-primary/5 border-primary/10 text-primary"
                          }`}>
                            {b.status === "created" && "تم تسجيل الطلب"}
                            {b.status === "assigned" && "تم التعيين"}
                            {b.status === "accepted" && "مؤكد"}
                            {b.status === "on_the_way" && "الفني بالطريق"}
                            {b.status === "arrived" && "الفني بالموقع"}
                            {b.status === "in_progress" && "جاري العمل"}
                            {b.status === "completed" && "اكتمل بنجاح"}
                            {b.status === "cancelled" && "ملغي"}
                          </span>

                          <Link
                            href={`/orders?bookingId=${b.id}`}
                            className="flex items-center gap-1.5 text-xs font-black text-primary hover:underline hover:text-primary/80 transition-colors"
                          >
                            <span>تتبع وتفاصيل</span>
                            <ChevronLeft className="w-3.5 h-3.5 transform rotate-180 sm:rotate-0" />
                          </Link>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

export default function ProfilePage() {
  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Header />
      <main className="flex-grow">
        <Suspense fallback={
          <div className="flex justify-center items-center py-24">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
          </div>
        }>
          <ProfileContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
