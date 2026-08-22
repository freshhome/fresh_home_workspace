"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  User, MapPin, Phone, Clock, AlertCircle, 
  CheckCircle, Plus, Trash2, ShieldCheck, LogOut, ChevronLeft, ArrowRight 
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
          service_snapshot, 
          pricing_inputs
        `)
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

      if (!error && data) {
        setBookings(data);
      }
    } catch (e) {
      console.error("Error loading bookings:", e);
    } finally {
      setLoadingBookings(false);
    }
  }

  // Update profile handler (Writes to profiles table as SSOT)
  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setUpdatingProfile(true);
    setProfileSuccess("");

    try {
      // 1. Update public.profiles
      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          first_name: firstName.trim(),
          last_name: lastName.trim(),
        })
        .eq("id", user.id);

      if (profileError) throw profileError;

      // 2. Sync user metadata for backward compatibility
      await supabase.auth.updateUser({
        data: {
          first_name: firstName.trim(),
          last_name: lastName.trim(),
        }
      });

      setProfileSuccess("تم تحديث البيانات بنجاح!");
      setTimeout(() => setProfileSuccess(""), 4000);
    } catch (err: any) {
      alert("فشل تحديث البيانات: " + err.message);
    } finally {
      setUpdatingProfile(false);
    }
  };

  // Add phone handler
  const handleAddPhone = async (e: React.FormEvent) => {
    e.preventDefault();
    setPhoneError("");

    const phoneRegex = /^(010|011|012|015)\d{8}$/;
    if (!phoneRegex.test(newPhone.trim())) {
      setPhoneError("رقم الهاتف غير صحيح. يرجى إدخال رقم محمول مصري صحيح (مثال: 01012345678).");
      return;
    }

    setAddingPhone(true);
    try {
      const { error } = await supabase
        .from("user_phones")
        .insert({
          user_id: user.id,
          phone_number: newPhone.trim(),
          is_primary: phones.length === 0,
          is_verified: true,
        });

      if (error) throw error;

      setNewPhone("");
      loadPhones(user.id);
    } catch (err: any) {
      console.error("Add phone error:", err);
      setPhoneError(err.message || "حدث خطأ أثناء إضافة رقم الهاتف.");
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
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-10 text-right font-sans">
      {/* Title section */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-200 pb-6 mb-8">
        <div>
          <h1 className="text-2xl font-black text-slate-900">الملف الشخصي والحساب</h1>
          <p className="text-slate-500 text-xs mt-1 font-medium">أهلاً بك، يمكنك إدارة بياناتك وعناوينك وتتبع سجل طلباتك هنا.</p>
        </div>
        <button
          onClick={handleLogOut}
          className="flex items-center gap-2 py-2 px-4 rounded-xl border border-rose-200 text-rose-600 hover:bg-rose-50 text-xs font-bold transition-all cursor-pointer shadow-sm"
        >
          <LogOut className="w-4 h-4" />
          <span>تسجيل الخروج</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Navigation Sidebar */}
        <aside className="lg:col-span-3 space-y-2 bg-white p-4 rounded-3xl border border-slate-200 shadow-sm">
          <button
            onClick={() => setActiveTab("info")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all ${
              activeTab === "info" ? "bg-[#0D327D] text-white shadow-md shadow-blue-900/20" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <User className="w-4 h-4 shrink-0" />
            <span>البيانات الأساسية</span>
          </button>
          <button
            onClick={() => setActiveTab("phones")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all ${
              activeTab === "phones" ? "bg-[#0D327D] text-white shadow-md shadow-blue-900/20" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <Phone className="w-4 h-4 shrink-0" />
            <span>أرقام الهاتف</span>
          </button>
          <button
            onClick={() => setActiveTab("addresses")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all ${
              activeTab === "addresses" ? "bg-[#0D327D] text-white shadow-md shadow-blue-900/20" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <MapPin className="w-4 h-4 shrink-0" />
            <span>العناوين المحفوظة</span>
          </button>
          <button
            onClick={() => setActiveTab("bookings")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all ${
              activeTab === "bookings" ? "bg-[#0D327D] text-white shadow-md shadow-blue-900/20" : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <Clock className="w-4 h-4 shrink-0" />
            <span>سجل الحجوزات</span>
          </button>
        </aside>

        {/* Dynamic Panels */}
        <section className="lg:col-span-9 bg-white rounded-3xl border border-slate-200 p-6 sm:p-8 shadow-sm min-h-[380px]">
          
          {/* TAB 1: BASIC INFO */}
          {activeTab === "info" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-900">البيانات الأساسية لحسابك</h3>
                <p className="text-slate-500 text-xs font-medium">تحديث اسمك ومعلومات الاتصال الأساسية.</p>
              </div>

              {profileSuccess && (
                <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-emerald-600" />
                  <span>{profileSuccess}</span>
                </div>
              )}

              <form onSubmit={handleUpdateProfile} className="space-y-4 max-w-lg">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-700">الاسم الأول</label>
                    <input 
                      type="text" 
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      className="w-full p-3 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-slate-800 font-sans"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-700">الاسم الأخير</label>
                    <input 
                      type="text" 
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      className="w-full p-3 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-slate-800 font-sans"
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
                    className="w-full p-3 rounded-xl border border-slate-100 bg-slate-100/70 text-slate-400 text-xs font-bold focus:outline-none text-left font-sans"
                  />
                </div>

                <button
                  type="submit"
                  disabled={updatingProfile}
                  className="py-3 px-8 rounded-xl bg-[#0091FF] hover:bg-[#0077E6] text-white font-black text-xs shadow-md shadow-blue-500/20 transition-all glow-button disabled:opacity-50 cursor-pointer"
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
                <h3 className="text-base font-black text-slate-900">إدارة أرقام الهواتف</h3>
                <p className="text-slate-500 text-xs font-medium">أرقام الهواتف المستخدمة لتأكيد طلباتك والتواصل معك عبر واتساب.</p>
              </div>

              {phoneError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{phoneError}</span>
                </div>
              )}

              {/* Add phone number form */}
              <form onSubmit={handleAddPhone} className="flex gap-2 items-end max-w-md">
                <div className="flex-1 space-y-1.5">
                  <label className="block text-xs font-bold text-slate-700">إضافة رقم هاتف جديد</label>
                  <input 
                    type="tel" 
                    placeholder="مثال: 01012345678"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full p-3 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-slate-800 text-left font-sans"
                    required
                  />
                </div>
                <button
                  type="submit"
                  disabled={addingPhone}
                  className="p-3 rounded-xl bg-[#0091FF] hover:bg-[#0077E6] text-white font-black text-xs shadow-md transition-all shrink-0 flex items-center gap-1.5 cursor-pointer h-[44px]"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة</span>
                </button>
              </form>

              {/* Phones List */}
              <div className="space-y-2.5 pt-4 border-t border-slate-100 max-w-lg">
                {phones.length === 0 ? (
                  <p className="text-xs font-bold text-slate-400 py-4">لم تقم بإضافة أي أرقام هواتف حتى الآن.</p>
                ) : (
                  phones.map((p) => (
                    <div key={p.id} className="flex items-center justify-between p-3.5 rounded-2xl border border-slate-100 bg-[#F8FAFC]">
                      <div className="flex items-center gap-3">
                        <span className="text-xs font-black text-slate-800 font-sans tracking-wide">{p.phone_number}</span>
                        {p.is_primary ? (
                          <span className="text-[10px] bg-emerald-50 text-emerald-600 border border-emerald-200 px-2 py-0.5 rounded-md font-bold">
                            رئيسي
                          </span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => handleSetPrimaryPhone(p.id)}
                            className="text-[10px] text-[#0091FF] hover:underline font-bold"
                          >
                            تعيين كرئيسي
                          </button>
                        )}
                      </div>
                      <button
                        type="button"
                        onClick={() => handleDeletePhone(p.id)}
                        className="text-slate-400 hover:text-rose-600 p-1 transition-colors"
                        title="حذف الرقم"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
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
                <h3 className="text-base font-black text-slate-900">العناوين المسجلة</h3>
                <p className="text-slate-500 text-xs font-medium">إدارة وتحديد عناوين منزلك أو مقرات عملك لتسريع عملية الحجز.</p>
              </div>

              {addressError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{addressError}</span>
                </div>
              )}

              {/* Add address toggle */}
              {!addingAddress ? (
                <button
                  type="button"
                  onClick={() => setAddingAddress(true)}
                  className="flex items-center gap-2 py-2.5 px-5 rounded-xl border border-[#0091FF]/30 bg-blue-50 text-[#0091FF] hover:bg-blue-100 text-xs font-black transition-all cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة عنوان جديد</span>
                </button>
              ) : (
                <form onSubmit={handleAddAddress} className="space-y-4 p-5 rounded-2xl border border-slate-200 bg-[#F8FAFC] max-w-xl">
                  <h4 className="text-xs font-black text-slate-800">بيانات العنوان الجديد</h4>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700">المحافظة</label>
                      <select
                        value={newAddress.governorate}
                        onChange={(e) => setNewAddress({ ...newAddress, governorate: e.target.value, city: REGIONS_MAP[e.target.value][0] })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                      >
                        {Object.keys(REGIONS_MAP).map((gov) => (
                          <option key={gov} value={gov}>{gov}</option>
                        ))}
                      </select>
                    </div>
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700">المدينة / المنطقة</label>
                      <select
                        value={newAddress.city}
                        onChange={(e) => setNewAddress({ ...newAddress, city: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                      >
                        {REGIONS_MAP[newAddress.governorate]?.map((c) => (
                          <option key={c} value={c}>{c}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="block text-xs font-bold text-slate-700">اسم الشارع</label>
                    <input 
                      type="text" 
                      placeholder="مثال: شارع مصدق"
                      value={newAddress.street}
                      onChange={(e) => setNewAddress({ ...newAddress, street: e.target.value })}
                      className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700">رقم العمارة</label>
                      <input 
                        type="text" 
                        placeholder="14"
                        value={newAddress.building}
                        onChange={(e) => setNewAddress({ ...newAddress, building: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                        required
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700">الدور</label>
                      <input 
                        type="text" 
                        placeholder="3"
                        value={newAddress.floor}
                        onChange={(e) => setNewAddress({ ...newAddress, floor: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700">رقم الشقة</label>
                      <input 
                        type="text" 
                        placeholder="5"
                        value={newAddress.apartment}
                        onChange={(e) => setNewAddress({ ...newAddress, apartment: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 text-xs font-bold bg-white focus:border-[#0091FF] focus:outline-none"
                      />
                    </div>
                  </div>

                  <div className="flex gap-2 pt-2">
                    <button
                      type="submit"
                      className="py-2 px-5 rounded-xl bg-[#0091FF] text-white text-xs font-black shadow-sm cursor-pointer hover:bg-[#0077E6]"
                    >
                      حفظ العنوان
                    </button>
                    <button
                      type="button"
                      onClick={() => setAddingAddress(false)}
                      className="py-2 px-4 rounded-xl border border-slate-200 text-slate-600 text-xs font-bold hover:bg-slate-100"
                    >
                      إلغاء
                    </button>
                  </div>
                </form>
              )}

              {/* Addresses List */}
              <div className="space-y-3 pt-2">
                {addresses.length === 0 ? (
                  <p className="text-xs font-bold text-slate-400 py-4">لم تقم بحفظ أي عناوين بعد.</p>
                ) : (
                  addresses.map((addr) => (
                    <div key={addr.id} className="p-4 rounded-2xl border border-slate-100 bg-[#F8FAFC] flex items-center justify-between gap-4">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-black text-slate-900">{addr.city}، {addr.governorate}</span>
                          {addr.is_primary && (
                            <span className="text-[10px] bg-emerald-50 text-emerald-600 border border-emerald-200 px-2 py-0.5 rounded-md font-bold">
                              العنوان الافتراضي
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-slate-500 font-medium">
                          شارع {addr.street} - مبنى {addr.building_number} {addr.floor ? `- دور ${addr.floor}` : ""} {addr.apartment ? `- شقة ${addr.apartment}` : ""}
                        </p>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        {!addr.is_primary && (
                          <button
                            type="button"
                            onClick={() => handleSetPrimaryAddress(addr.id)}
                            className="text-[10px] text-[#0091FF] hover:underline font-bold"
                          >
                            جعله افتراضي
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => handleDeleteAddress(addr.id)}
                          className="text-slate-400 hover:text-rose-600 p-1 transition-colors"
                          title="حذف العنوان"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* TAB 4: BOOKINGS */}
          {activeTab === "bookings" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-900">سجل الحجوزات والطلبات</h3>
                <p className="text-slate-500 text-xs font-medium">عرض ومتابعة كافة الطلبات السابقة والحالية.</p>
              </div>

              {loadingBookings ? (
                <div className="py-12 flex justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
                </div>
              ) : bookings.length === 0 ? (
                <div className="text-center py-12 space-y-3">
                  <Clock className="w-10 h-10 text-slate-300 mx-auto" />
                  <p className="text-xs font-bold text-slate-500">لا توجد لديك أي طلبات سابقة حتى الآن.</p>
                  <Link href="/" className="inline-block px-5 py-2.5 rounded-xl bg-[#0091FF] text-white text-xs font-bold shadow-sm">
                    احجز خدمة جديدة
                  </Link>
                </div>
              ) : (
                <div className="space-y-3">
                  {bookings.map((b) => (
                    <Link
                      key={b.id}
                      href={`/orders?bookingId=${b.id}`}
                      className="block p-4 rounded-2xl border border-slate-100 bg-[#F8FAFC] hover:border-[#0091FF]/30 transition-all group"
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <h4 className="text-xs font-black text-slate-900 group-hover:text-[#0091FF] transition-colors">
                            {b.service_snapshot?.title || "خدمة منزلية"}
                          </h4>
                          <span className="text-[10px] text-slate-400 font-bold block mt-1">
                            تاريخ الحجز: {new Date(b.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short", year: "numeric" })}
                          </span>
                        </div>
                        
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-bold px-3 py-1 rounded-full bg-blue-50 text-[#0091FF] border border-blue-100">
                            {b.status}
                          </span>
                          <ChevronLeft className="w-4 h-4 text-slate-400 group-hover:text-[#0091FF] group-hover:-translate-x-1 transition-all" />
                        </div>
                      </div>
                    </Link>
                  ))}
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
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
      <Header />
      <main className="flex-1 pt-24 pb-16">
        <Suspense fallback={
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
        }>
          <ProfileContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
