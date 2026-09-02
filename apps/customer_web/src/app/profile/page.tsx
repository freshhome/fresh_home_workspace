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

import { GEOGRAPHIC_HIERARCHY, isCoverageSupported } from "@/lib/geo";

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

  // Addresses state (Address V2)
  const [addresses, setAddresses] = useState<any[]>([]);
  const [addingAddress, setAddingAddress] = useState(false);
  const [newAddress, setNewAddress] = useState({
    governorate: "القاهرة",
    city: "التجمع الخامس",
    district: "الحي الأول",
    street_or_compound: "",
    building_identifier: "",
    floor: "",
    apartment_or_unit: "",
    landmark: ""
  });
  const [profileCustomDistrict, setProfileCustomDistrict] = useState("");
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
      } catch (err) {
        console.error("Profile load warning:", err);
      }

      loadPhones(session.user.id);
      loadAddresses(session.user.id);
      loadBookings(session.user.id);
      setLoading(false);
    }
    loadSession();
  }, [router]);

  // Fetch phone numbers from user_phones
  const loadPhones = async (userId: string) => {
    const { data } = await supabase
      .from("user_phones")
      .select("*")
      .eq("user_id", userId)
      .order("is_primary", { ascending: false });
    if (data) setPhones(data);
  };

  // Fetch addresses from user_addresses
  const loadAddresses = async (userId: string) => {
    const { data } = await supabase
      .from("user_addresses")
      .select("*")
      .eq("user_id", userId)
      .order("is_primary", { ascending: false });
    if (data) setAddresses(data);
  };

  // Fetch past and active bookings
  const loadBookings = async (userId: string) => {
    setLoadingBookings(true);
    const { data } = await supabase
      .from("bookings")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });
    if (data) setBookings(data);
    setLoadingBookings(false);
  };

  // Update profile handler (Writes to public.profiles and auth user metadata)
  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSuccess("");
    setUpdatingProfile(true);

    try {
      // 1. Update public.profiles
      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          first_name: firstName.trim(),
          last_name: lastName.trim(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", user.id);

      if (profileError) throw profileError;

      // 2. Sync to auth user metadata
      await supabase.auth.updateUser({
        data: {
          first_name: firstName.trim(),
          last_name: lastName.trim(),
        }
      });

      setProfileSuccess("تم تحديث البيانات الشخصية بنجاح!");
      setTimeout(() => setProfileSuccess(""), 4000);
    } catch (err: any) {
      console.error("Profile update error:", err);
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
      setPhoneError("رقم الهاتف غير صحيح. يرجى إدخال رقم محمول مصري مكون من 11 رقم.");
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

  // Add address handler (Address V2)
  const handleAddAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddressError("");

    const effDistrict = newAddress.district === "أخرى" ? profileCustomDistrict.trim() : newAddress.district.trim();

    if (!isCoverageSupported(newAddress.governorate)) {
      setAddressError("عذراً، خدمات فريش هوم متاحة حالياً فقط داخل نطاق القاهرة والجيزة.");
      return;
    }

    if (!newAddress.street_or_compound.trim() || !newAddress.building_identifier.trim() || !effDistrict) {
      setAddressError("يرجى ملء كافة الحقول الإجبارية (المحافظة، المدينة، الحي، الشارع، المبنى).");
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
          district: effDistrict,
          street_or_compound: newAddress.street_or_compound.trim(),
          building_identifier: newAddress.building_identifier.trim(),
          floor: newAddress.floor.trim() || null,
          apartment_or_unit: newAddress.apartment_or_unit.trim() || null,
          landmark: newAddress.landmark.trim() || null,
          is_primary: addresses.length === 0,
        });

      if (error) throw error;

      setNewAddress({
        governorate: "القاهرة",
        city: "التجمع الخامس",
        district: "الحي الأول",
        street_or_compound: "",
        building_identifier: "",
        floor: "",
        apartment_or_unit: "",
        landmark: ""
      });
      setProfileCustomDistrict("");
      setAddingAddress(false);
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
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-200 dark:border-blue-900/40 pb-6 mb-8">
        <div>
          <h1 className="text-2xl font-black text-slate-900 dark:text-white">الملف الشخصي والحساب</h1>
          <p className="text-slate-500 dark:text-slate-400 text-xs mt-1 font-medium">أهلاً بك، يمكنك إدارة بياناتك وعناوينك وتتبع سجل طلباتك هنا.</p>
        </div>
        <button
          onClick={handleLogOut}
          className="flex items-center gap-2 py-2 px-4 rounded-xl border border-rose-200 dark:border-rose-900/50 bg-rose-50/50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 hover:bg-rose-100 dark:hover:bg-rose-950/40 text-xs font-bold transition-all cursor-pointer shadow-xs"
        >
          <LogOut className="w-4 h-4" />
          <span>تسجيل الخروج</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Navigation Sidebar */}
        <aside className="lg:col-span-3 space-y-2 bg-white dark:bg-[#071739] p-4 rounded-3xl border border-slate-200/80 dark:border-blue-900/50 shadow-sm">
          <button
            onClick={() => setActiveTab("info")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all cursor-pointer ${
              activeTab === "info" ? "bg-[#0D327D] dark:bg-[#0091FF] text-white shadow-md shadow-blue-900/20" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-blue-900/20"
            }`}
          >
            <User className="w-4 h-4 shrink-0" />
            <span>البيانات الأساسية</span>
          </button>
          <button
            onClick={() => setActiveTab("phones")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all cursor-pointer ${
              activeTab === "phones" ? "bg-[#0D327D] dark:bg-[#0091FF] text-white shadow-md shadow-blue-900/20" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-blue-900/20"
            }`}
          >
            <Phone className="w-4 h-4 shrink-0" />
            <span>أرقام الهاتف</span>
          </button>
          <button
            onClick={() => setActiveTab("addresses")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all cursor-pointer ${
              activeTab === "addresses" ? "bg-[#0D327D] dark:bg-[#0091FF] text-white shadow-md shadow-blue-900/20" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-blue-900/20"
            }`}
          >
            <MapPin className="w-4 h-4 shrink-0" />
            <span>العناوين المحفوظة</span>
          </button>
          <button
            onClick={() => setActiveTab("bookings")}
            className={`w-full flex items-center gap-3 p-3.5 rounded-2xl text-xs font-black transition-all cursor-pointer ${
              activeTab === "bookings" ? "bg-[#0D327D] dark:bg-[#0091FF] text-white shadow-md shadow-blue-900/20" : "text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-blue-900/20"
            }`}
          >
            <Clock className="w-4 h-4 shrink-0" />
            <span>سجل الحجوزات</span>
          </button>
        </aside>

        {/* Dynamic Panels */}
        <section className="lg:col-span-9 bg-white dark:bg-[#071739] rounded-3xl border border-slate-200/80 dark:border-blue-900/50 p-6 sm:p-8 shadow-sm min-h-[380px] transition-colors">
          
          {/* TAB 1: BASIC INFO */}
          {activeTab === "info" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-900 dark:text-white">البيانات الأساسية لحسابك</h3>
                <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">تحديث اسمك ومعلومات الاتصال الأساسية.</p>
              </div>

              {profileSuccess && (
                <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900/60 text-emerald-700 dark:text-emerald-300 text-xs font-bold flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-emerald-600" />
                  <span>{profileSuccess}</span>
                </div>
              )}

              <form onSubmit={handleUpdateProfile} className="space-y-4 max-w-lg">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">الاسم الأول</label>
                    <input 
                      type="text" 
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white font-sans"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">الاسم الأخير</label>
                    <input 
                      type="text" 
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white font-sans"
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
                    className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/40 bg-slate-100/70 dark:bg-[#050D24]/50 text-slate-400 text-xs font-bold focus:outline-none text-left font-sans"
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
                <h3 className="text-base font-black text-slate-900 dark:text-white">إدارة أرقام الهواتف</h3>
                <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">أرقام الهواتف المستخدمة لتأكيد طلباتك والتواصل معك عبر واتساب.</p>
              </div>

              {phoneError && (
                <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/60 text-rose-700 dark:text-rose-300 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{phoneError}</span>
                </div>
              )}

              {/* Add phone number form */}
              <form onSubmit={handleAddPhone} className="flex gap-2 items-end max-w-md">
                <div className="flex-1 space-y-1.5">
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">إضافة رقم هاتف جديد</label>
                  <input 
                    type="tel" 
                    placeholder="مثال: 01012345678"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
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
              <div className="space-y-2.5 pt-4 border-t border-slate-100 dark:border-blue-900/40 max-w-lg">
                {phones.length === 0 ? (
                  <p className="text-xs font-bold text-slate-400 py-4">لم تقم بإضافة أي أرقام هواتف حتى الآن.</p>
                ) : (
                  phones.map((p) => (
                    <div key={p.id} className="flex items-center justify-between p-3.5 rounded-2xl border border-slate-100 dark:border-blue-900/40 bg-[#F8FAFC] dark:bg-[#050D24]">
                      <div className="flex items-center gap-3">
                        <span className="text-xs font-black text-slate-900 dark:text-white font-sans tracking-wide">{p.phone_number}</span>
                        {p.is_primary ? (
                          <span className="text-[10px] bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/50 px-2 py-0.5 rounded-md font-bold">
                            رئيسي
                          </span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => handleSetPrimaryPhone(p.id)}
                            className="text-[10px] text-[#0091FF] dark:text-[#22A5FC] hover:underline font-bold"
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
                <h3 className="text-base font-black text-slate-900 dark:text-white">العناوين المسجلة (Address V2)</h3>
                <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">حدد عناوين منزلك أو مقرات عملك لاستخدامها بضغطة زر عند الحجز.</p>
              </div>

              {addressError && (
                <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/60 text-rose-700 dark:text-rose-300 text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-500" />
                  <span>{addressError}</span>
                </div>
              )}

              {/* Add address toggle */}
              {!addingAddress ? (
                <button
                  type="button"
                  onClick={() => setAddingAddress(true)}
                  className="flex items-center gap-2 py-2.5 px-5 rounded-xl border border-[#0091FF]/30 bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] hover:bg-blue-100 dark:hover:bg-blue-900/40 text-xs font-black transition-all cursor-pointer shadow-xs"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة عنوان جديد</span>
                </button>
              ) : (
                <form onSubmit={handleAddAddress} className="space-y-4 p-5 rounded-2xl border border-slate-200 dark:border-blue-900/50 bg-[#F8FAFC] dark:bg-[#050D24] max-w-xl">
                  <h4 className="text-xs font-black text-slate-800 dark:text-white">بيانات العنوان الجديد</h4>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    {/* 1. Governorate */}
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                        المحافظة
                      </label>
                      <select
                        value={newAddress.governorate}
                        onChange={(e) => {
                          const gov = e.target.value;
                          const defaultCity = Object.keys(GEOGRAPHIC_HIERARCHY[gov] || {})[0] || "";
                          const defaultDistricts = GEOGRAPHIC_HIERARCHY[gov]?.[defaultCity] || [];
                          setNewAddress({
                            ...newAddress,
                            governorate: gov,
                            city: defaultCity,
                            district: defaultDistricts[0] || ""
                          });
                          setProfileCustomDistrict("");
                        }}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      >
                        {Object.keys(GEOGRAPHIC_HIERARCHY).map((gov) => (
                          <option key={gov} value={gov}>{gov}</option>
                        ))}
                      </select>
                    </div>

                    {/* 2. City */}
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                        المدينة / المنطقة
                      </label>
                      <select
                        value={newAddress.city}
                        onChange={(e) => {
                          const c = e.target.value;
                          const defaultDistricts = GEOGRAPHIC_HIERARCHY[newAddress.governorate]?.[c] || [];
                          setNewAddress({
                            ...newAddress,
                            city: c,
                            district: defaultDistricts[0] || ""
                          });
                          setProfileCustomDistrict("");
                        }}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      >
                        {Object.keys(GEOGRAPHIC_HIERARCHY[newAddress.governorate] || {}).map((c) => (
                          <option key={c} value={c}>{c}</option>
                        ))}
                      </select>
                    </div>

                    {/* 3. District */}
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                        الحي / المجاورة
                      </label>
                      <select
                        value={newAddress.district}
                        onChange={(e) => setNewAddress({ ...newAddress, district: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      >
                        {(GEOGRAPHIC_HIERARCHY[newAddress.governorate]?.[newAddress.city] || ["أخرى"]).map((d) => (
                          <option key={d} value={d}>{d}</option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {newAddress.district === "أخرى" && (
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                        اسم الحي / المنطقة المخصصة
                      </label>
                      <input 
                        type="text" 
                        placeholder="اكتب اسم الحي..."
                        value={profileCustomDistrict}
                        onChange={(e) => setProfileCustomDistrict(e.target.value)}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      />
                    </div>
                  )}

                  <div className="space-y-1">
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                      اسم الشارع أو الكومباوند
                    </label>
                    <input 
                      type="text" 
                      placeholder="مثال: شارع التسعين الشمالي / كمبوند ميفيدا"
                      value={newAddress.street_or_compound}
                      onChange={(e) => setNewAddress({ ...newAddress, street_or_compound: e.target.value })}
                      className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                        رقم / اسم المبنى أو الفيلا
                      </label>
                      <input 
                        type="text" 
                        placeholder="14 ب"
                        value={newAddress.building_identifier}
                        onChange={(e) => setNewAddress({ ...newAddress, building_identifier: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                        required
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">الدور / الطابق</label>
                      <input 
                        type="text" 
                        placeholder="3"
                        value={newAddress.floor}
                        onChange={(e) => setNewAddress({ ...newAddress, floor: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">رقم الشقة / الوحدة</label>
                      <input 
                        type="text" 
                        placeholder="5"
                        value={newAddress.apartment_or_unit}
                        onChange={(e) => setNewAddress({ ...newAddress, apartment_or_unit: e.target.value })}
                        className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                      />
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">علامة مميزة (اختياري)</label>
                    <input 
                      type="text" 
                      placeholder="مثال: بجوار مستشفى الجوي"
                      value={newAddress.landmark}
                      onChange={(e) => setNewAddress({ ...newAddress, landmark: e.target.value })}
                      className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold bg-white dark:bg-[#071739] text-slate-900 dark:text-white focus:border-[#0091FF] focus:outline-none"
                    />
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
                      className="py-2 px-4 rounded-xl border border-slate-200 dark:border-blue-900/50 text-slate-600 dark:text-slate-300 text-xs font-bold hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
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
                  addresses.map((addr) => {
                    const fullDetails = `${addr.street_or_compound || addr.street || ""} - مبنى ${addr.building_identifier || addr.building_number || ""}${addr.floor ? ` - دور ${addr.floor}` : ""}${addr.apartment_or_unit || addr.apartment ? ` - شقة ${addr.apartment_or_unit || addr.apartment}` : ""}${addr.landmark ? ` (${addr.landmark})` : ""}`;
                    return (
                      <div key={addr.id} className="p-4 rounded-2xl border border-slate-100 dark:border-blue-900/40 bg-[#F8FAFC] dark:bg-[#050D24] flex items-center justify-between gap-4">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-black text-slate-900 dark:text-white">
                              {addr.city}، {addr.district ? `${addr.district} - ` : ""}{addr.governorate}
                            </span>
                            {addr.is_primary && (
                              <span className="text-[10px] bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/50 px-2 py-0.5 rounded-md font-bold">
                                العنوان الافتراضي
                              </span>
                            )}
                          </div>
                          <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                            {fullDetails}
                          </p>
                        </div>

                        <div className="flex items-center gap-3 shrink-0">
                          {!addr.is_primary && (
                            <button
                              type="button"
                              onClick={() => handleSetPrimaryAddress(addr.id)}
                              className="text-[10px] text-[#0091FF] dark:text-[#22A5FC] hover:underline font-bold cursor-pointer"
                            >
                              جعله افتراضي
                            </button>
                          )}
                          <button
                            type="button"
                            onClick={() => handleDeleteAddress(addr.id)}
                            className="text-slate-400 hover:text-rose-600 p-1 transition-colors cursor-pointer"
                            title="حذف العنوان"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          )}

          {/* TAB 4: BOOKINGS */}
          {activeTab === "bookings" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-black text-slate-900 dark:text-white">سجل الحجوزات والطلبات</h3>
                <p className="text-slate-500 dark:text-slate-400 text-xs font-medium">عرض ومتابعة كافة الطلبات السابقة والحالية.</p>
              </div>

              {loadingBookings ? (
                <div className="py-12 flex justify-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
                </div>
              ) : bookings.length === 0 ? (
                <div className="text-center py-12 space-y-3">
                  <Clock className="w-10 h-10 text-slate-300 mx-auto" />
                  <p className="text-xs font-bold text-slate-500 dark:text-slate-400">لا توجد لديك أي طلبات سابقة حتى الآن.</p>
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
                      className="block p-4 rounded-2xl border border-slate-100 dark:border-blue-900/40 bg-[#F8FAFC] dark:bg-[#050D24] hover:border-[#0091FF]/30 transition-all group"
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <h4 className="text-xs font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors">
                            {b.service_snapshot?.title || "خدمة منزلية"}
                          </h4>
                          <span className="text-[10px] text-slate-400 font-bold block mt-1">
                            تاريخ الحجز: {new Date(b.created_at).toLocaleDateString("ar-EG", { day: "numeric", month: "short", year: "numeric" })}
                          </span>
                        </div>
                        
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-bold px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50">
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
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans transition-colors duration-300">
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
