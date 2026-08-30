"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, User, Phone, ArrowRight, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Logo from "@/components/Logo";
import { trackSignUp } from "@/lib/gtm";

const GoogleIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
    <path d="M3.98918 10.8777L3.36263 13.2167L1.07258 13.2652C0.388195 11.9958 0 10.5435 0 9.0001C0 7.50768 0.362953 6.10031 1.00631 4.86108H1.0068L3.04559 5.23486L3.9387 7.26141C3.75177 7.80637 3.64989 8.39137 3.64989 9.0001C3.64996 9.66076 3.76963 10.2937 3.98918 10.8777Z" fill="#FBBB00"/>
    <path d="M17.8427 7.3186C17.9461 7.86303 18 8.42529 18 8.99992C18 9.64426 17.9322 10.2728 17.8032 10.8791C17.3651 12.9421 16.2203 14.7436 14.6344 16.0184L14.6339 16.0179L12.066 15.8869L11.7025 13.6181C12.7548 13.001 13.5772 12.0352 14.0104 10.8791H9.19785V7.3186H17.8427Z" fill="#518EF8"/>
    <path d="M14.6339 16.0181L14.6344 16.0185C13.092 17.2583 11.1328 18 8.99999 18C5.57257 18 2.59269 16.0843 1.07257 13.2651L3.98917 10.8777C4.74921 12.9061 6.70597 14.3501 8.99999 14.3501C9.98602 14.3501 10.9098 14.0835 11.7024 13.6182L14.6339 16.0181Z" fill="#28B446"/>
    <path d="M14.7447 2.07197L11.8291 4.45894C11.0087 3.94615 10.0389 3.64992 9 3.64992C6.65406 3.64992 4.6607 5.16013 3.93874 7.26131L1.00681 4.86098H1.00632C2.50418 1.97307 5.52165 0 9 0C11.1837 0 13.186 0.777867 14.7447 2.07197Z" fill="#F14336"/>
  </svg>
);

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

  const handleGoogleLogin = async () => {
    setErrorMsg("");
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: typeof window !== "undefined" ? `${window.location.origin}${redirectPath}` : undefined,
          queryParams: {
            access_type: "offline",
            prompt: "consent"
          }
        }
      });
      if (error) throw error;
    } catch (err: any) {
      console.error("Google registration error:", err);
      setErrorMsg(err.message || "حدث خطأ أثناء الاتصال بخدمة Google.");
    }
  };

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
        // Zero-PII: Track successful registration (CompleteRegistration)
        trackSignUp({ method: "email_password" });

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
    <div className="max-w-md mx-auto my-10 px-4 font-sans w-full">
      <div className="bg-white dark:bg-[#071739] rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-blue-900/50 shadow-xl dark:shadow-2xl text-right transition-colors">
        {/* Top Header Navigation */}
        <div className="flex items-center justify-between mb-4">
          <Link 
            href="/login" 
            className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-400 hover:text-[#0091FF] dark:hover:text-[#22A5FC] transition-colors"
          >
            <span>لديك حساب؟ تسجيل الدخول</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {/* Centered Logo Animation Header */}
        <div className="flex flex-col items-center text-center mb-6">
          <Logo size="lg" animated={true} />
          <h2 className="text-xl font-black text-slate-900 dark:text-white font-sans mt-4">إنشاء حساب جديد</h2>
          <p className="text-slate-500 dark:text-slate-400 text-xs mt-1 font-medium max-w-xs">
            سجل معنا في Fresh Home للاستفادة من حفظ عناوينك ومتابعة طلباتك بسهولة.
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/60 text-rose-700 dark:text-rose-300 text-xs font-bold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-500" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900/60 text-emerald-700 dark:text-emerald-300 text-xs font-bold flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 shrink-0 text-emerald-600" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={handleRegister} className="space-y-3.5">
          {/* Name Row */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">الاسم الأول</label>
              <div className="relative flex items-center">
                <input 
                  type="text" 
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="محمد"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-right font-sans"
                  required
                />
                <User className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">اسم العائلة</label>
              <div className="relative flex items-center">
                <input 
                  type="text" 
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="أحمد"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-right font-sans"
                  required
                />
                <User className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>
          </div>

          {/* Email Field */}
          <div className="space-y-1">
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">البريد الإلكتروني</label>
            <div className="relative flex items-center">
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full p-3 pl-9 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                required
              />
              <Mail className="w-4 h-4 text-slate-400 absolute left-3" />
            </div>
          </div>

          {/* Phone Field */}
          <div className="space-y-1">
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">رقم الهاتف (محمول مصري)</label>
            <div className="relative flex items-center">
              <input 
                type="tel" 
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="01012345678"
                className="w-full p-3 pl-9 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                required
              />
              <Phone className="w-4 h-4 text-slate-400 absolute left-3" />
            </div>
          </div>

          {/* Password Row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">كلمة المرور</label>
              <div className="relative flex items-center">
                <input 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                  required
                />
                <Lock className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">تأكيد كلمة المرور</label>
              <div className="relative flex items-center">
                <input 
                  type="password" 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full p-3 pl-8 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                  required
                />
                <Lock className="w-3.5 h-3.5 text-slate-400 absolute left-2.5" />
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white font-black text-xs shadow-md shadow-blue-500/25 transition-all flex items-center justify-center gap-2 glow-button cursor-pointer"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            <span>إنشاء الحساب</span>
          </button>

          {/* Google OAuth Login */}
          <div className="pt-2">
            <div className="relative flex py-2 items-center">
              <div className="flex-grow border-t border-slate-200 dark:border-blue-900/40"></div>
              <span className="flex-shrink mx-3 text-[11px] font-bold text-slate-400">أو من خلال</span>
              <div className="flex-grow border-t border-slate-200 dark:border-blue-900/40"></div>
            </div>

            <button
              type="button"
              onClick={handleGoogleLogin}
              className="w-full mt-1 py-3 rounded-xl border border-slate-200 dark:border-blue-900/60 hover:bg-slate-50 dark:hover:bg-[#050D24] text-slate-700 dark:text-slate-200 font-bold text-xs flex items-center justify-center gap-2.5 transition-colors shadow-xs cursor-pointer"
            >
              <GoogleIcon className="w-4 h-4" />
              <span>المتابعة باستخدام Google</span>
            </button>
          </div>

          <div className="text-center pt-3 border-t border-slate-100 dark:border-blue-900/40 text-xs text-slate-500 dark:text-slate-400 font-medium">
            <span>لديك حساب بالفعل؟ </span>
            <Link href={`/login?redirect=${encodeURIComponent(redirectPath)}`} className="text-[#0091FF] dark:text-[#22A5FC] font-black hover:underline">
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
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans transition-colors duration-300">
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
