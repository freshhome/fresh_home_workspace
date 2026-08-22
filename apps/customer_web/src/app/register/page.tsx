"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, User, Phone, ArrowRight, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Logo from "@/components/Logo";

function RegisterContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectPath = searchParams.get("redirect") || "/";

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  // Check if already logged in
  useEffect(() => {
    async function checkUser() {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        router.push(redirectPath);
      }
    }
    checkUser();
  }, [router, redirectPath]);

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");
    setSuccessMsg("");

    // Validations
    if (!firstName.trim() || !lastName.trim() || !email.trim() || !phone.trim() || !password.trim()) {
      setErrorMsg("يرجى ملء جميع الحقول المطلوبة.");
      return;
    }

    const phoneRegex = /^(010|011|012|015)\d{8}$/;
    if (!phoneRegex.test(phone.trim())) {
      setErrorMsg("رقم الهاتف غير صحيح. يرجى إدخال رقم محمول مصري صحيح (مثال: 01012345678).");
      return;
    }

    if (password.length < 6) {
      setErrorMsg("كلمة المرور يجب أن لا تقل عن 6 أحرف.");
      return;
    }

    if (password !== confirmPassword) {
      setErrorMsg("كلمتا المرور غير متطابقتين.");
      return;
    }

    setLoading(true);
    try {
      // 1. Sign up user via Supabase Auth
      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password: password.trim(),
        options: {
          data: {
            first_name: firstName.trim(),
            last_name: lastName.trim(),
            app_type: "client",
          }
        }
      });

      if (error) throw error;

      if (data?.user) {
        // 2. Check if session exists
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user) {
          // 3. Save phone number in user_phones
          try {
            await supabase
              .from("user_phones")
              .insert({
                user_id: session.user.id,
                phone_number: phone.trim(),
                is_primary: true,
                is_verified: true
              });
          } catch (phoneErr) {
            console.error("Phone registration warning:", phoneErr);
          }

          setSuccessMsg("تم إنشاء الحساب بنجاح! جاري تحويلك...");
          setTimeout(() => {
            router.push(redirectPath);
            router.refresh();
          }, 1500);
        } else {
          setSuccessMsg("تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني لتأكيد الحساب.");
        }
      } else {
        throw new Error("فشلت عملية إنشاء الحساب.");
      }
    } catch (err: any) {
      console.error("Registration error:", err);
      setErrorMsg(err.message || "حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة مرة أخرى.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto my-10 px-4 font-sans">
      <div className="bg-white rounded-3xl p-8 border border-slate-200 shadow-xl text-right">
        {/* Top Header Navigation */}
        <div className="flex items-center justify-between mb-4">
          <Link 
            href="/login" 
            className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-400 hover:text-[#0091FF] transition-colors"
          >
            <span>لديك حساب؟ تسجيل الدخول</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {/* Centered Lottie Logo Animation Header */}
        <div className="flex flex-col items-center text-center mb-6">
          <Logo size="lg" animated={true} />
          <h2 className="text-xl font-black text-slate-900 font-sans mt-4">إنشاء حساب جديد</h2>
          <p className="text-slate-500 text-xs mt-1 font-medium max-w-xs">
            سجل معنا في Fresh Home للاستفادة من حفظ عناوينك ومتابعة طلباتك بسهولة.
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-500" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 shrink-0 text-emerald-600" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={handleRegister} className="space-y-3.5">
          {/* Name Row */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700">الاسم الأول</label>
              <div className="relative flex items-center">
                <input 
                  type="text" 
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="محمد"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-right font-sans"
                  required
                />
                <User className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700">اسم العائلة</label>
              <div className="relative flex items-center">
                <input 
                  type="text" 
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="أحمد"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-right font-sans"
                  required
                />
                <User className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>
          </div>

          {/* Email Field */}
          <div className="space-y-1">
            <label className="block text-xs font-bold text-slate-700">البريد الإلكتروني</label>
            <div className="relative flex items-center">
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full p-3 pl-9 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-left font-sans"
                required
              />
              <Mail className="w-4 h-4 text-slate-400 absolute left-3" />
            </div>
          </div>

          {/* Phone Field */}
          <div className="space-y-1">
            <label className="block text-xs font-bold text-slate-700">رقم الهاتف (محمول مصري)</label>
            <div className="relative flex items-center">
              <input 
                type="tel" 
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="01012345678"
                className="w-full p-3 pl-9 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-left font-sans"
                required
              />
              <Phone className="w-4 h-4 text-slate-400 absolute left-3" />
            </div>
          </div>

          {/* Password Row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700">كلمة المرور</label>
              <div className="relative flex items-center">
                <input 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-left font-sans"
                  required
                />
                <Lock className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700">تأكيد كلمة المرور</label>
              <div className="relative flex items-center">
                <input 
                  type="password" 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] text-left font-sans"
                  required
                />
                <Lock className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white font-black text-xs shadow-md transition-all flex items-center justify-center gap-2 glow-button cursor-pointer"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            <span>إنشاء الحساب</span>
          </button>

          <div className="text-center pt-3 border-t border-slate-100 text-xs text-slate-500 font-medium">
            <span>لديك حساب بالفعل؟ </span>
            <Link href={`/login?redirect=${encodeURIComponent(redirectPath)}`} className="text-[#0091FF] font-black hover:underline">
              تسجيل الدخول
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
      <Header />
      <main className="flex-1 flex items-center justify-center pt-24 pb-16">
        <Suspense fallback={
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
        }>
          <RegisterContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
