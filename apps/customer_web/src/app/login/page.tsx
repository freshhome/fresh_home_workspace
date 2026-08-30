"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, ArrowRight, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Logo from "@/components/Logo";
import { trackLogin } from "@/lib/gtm";

const GoogleIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
    <path d="M3.98918 10.8777L3.36263 13.2167L1.07258 13.2652C0.388195 11.9958 0 10.5435 0 9.0001C0 7.50768 0.362953 6.10031 1.00631 4.86108H1.0068L3.04559 5.23486L3.9387 7.26141C3.75177 7.80637 3.64989 8.39137 3.64989 9.0001C3.64996 9.66076 3.76963 10.2937 3.98918 10.8777Z" fill="#FBBB00"/>
    <path d="M17.8427 7.3186C17.9461 7.86303 18 8.42529 18 8.99992C18 9.64426 17.9322 10.2728 17.8032 10.8791C17.3651 12.9421 16.2203 14.7436 14.6344 16.0184L14.6339 16.0179L12.066 15.8869L11.7025 13.6181C12.7548 13.001 13.5772 12.0352 14.0104 10.8791H9.19785V7.3186H17.8427Z" fill="#518EF8"/>
    <path d="M14.6339 16.0181L14.6344 16.0185C13.092 17.2583 11.1328 18 8.99999 18C5.57257 18 2.59269 16.0843 1.07257 13.2651L3.98917 10.8777C4.74921 12.9061 6.70597 14.3501 8.99999 14.3501C9.98602 14.3501 10.9098 14.0835 11.7024 13.6182L14.6339 16.0181Z" fill="#28B446"/>
    <path d="M14.7447 2.07197L11.8291 4.45894C11.0087 3.94615 10.0389 3.64992 9 3.64992C6.65406 3.64992 4.6607 5.16013 3.93874 7.26131L1.00681 4.86098H1.00632C2.50418 1.97307 5.52165 0 9 0C11.1837 0 13.186 0.777867 14.7447 2.07197Z" fill="#F14336"/>
  </svg>
);

function LoginContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectPath = searchParams.get("redirect") || "/";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [successMsg, setSuccessMsg] = useState("");
  const [resetMode, setResetMode] = useState(false);

  // Check if already logged in, redirect if true
  useEffect(() => {
    async function checkUser() {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        router.push(redirectPath);
      }
    }
    checkUser();
  }, [router, redirectPath]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");
    setSuccessMsg("");

    if (!email.trim() || !password.trim()) {
      setErrorMsg("يرجى ملء جميع الحقول المطلوبة.");
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password: password.trim(),
      });

      if (error) throw error;

      trackLogin({ method: "password" });

      router.push(redirectPath);
      router.refresh();
    } catch (err: any) {
      console.error("Login error:", err);
      setErrorMsg(err.message || "فشل تسجيل الدخول. يرجى التحقق من بياناتك.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setErrorMsg("");
    try {
      trackLogin({ method: "google" });

      const origin = typeof window !== "undefined" ? window.location.origin : "";
      const redirectTo = `${origin}${redirectPath}`;

      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: redirectTo,
          queryParams: {
            access_type: 'offline',
            prompt: 'consent',
          }
        }
      });

      if (error) throw error;
    } catch (err: any) {
      console.error("Google login error:", err);
      setErrorMsg(err.message || "حدث خطأ أثناء الاتصال بجوجل.");
    }
  };

  const handlePasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");
    setSuccessMsg("");

    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) {
      setErrorMsg("يرجى إدخال البريد الإلكتروني أولاً.");
      return;
    }

    setLoading(true);
    try {
      const origin = typeof window !== "undefined" ? window.location.origin : "";
      const { error } = await supabase.auth.resetPasswordForEmail(normalizedEmail, {
        redirectTo: `${origin}/login?mode=reset_callback`,
      });

      if (error) throw error;

      setSuccessMsg("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح.");
    } catch (err: any) {
      console.error("Reset password error:", err);
      setErrorMsg(err.message || "حدث خطأ أثناء إرسال طلب إعادة التعيين.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto my-12 px-4 font-sans w-full">
      <div className="bg-white dark:bg-[#071739] rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-blue-900/50 shadow-xl dark:shadow-2xl text-right transition-colors">
        {/* Top Back navigation */}
        <div className="flex items-center justify-between mb-4">
          <Link 
            href="/" 
            className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-400 hover:text-[#0091FF] dark:hover:text-[#22A5FC] transition-colors"
          >
            <ArrowRight className="w-3.5 h-3.5 rotate-180" />
            <span>العودة للرئيسية</span>
          </Link>
        </div>

        {/* Centered Logo Animation Header */}
        <div className="flex flex-col items-center text-center mb-6">
          <Logo size="lg" animated={true} />
          <h2 className="text-xl font-black text-slate-900 dark:text-white font-sans mt-4">
            {resetMode ? "إعادة تعيين كلمة المرور" : "تسجيل الدخول"}
          </h2>
          <p className="text-slate-500 dark:text-slate-400 text-xs mt-1 font-medium max-w-xs">
            {resetMode 
              ? "أدخل بريدك الإلكتروني وسنرسل لك رابطاً لاستعادة حسابك." 
              : "مرحباً بك مجدداً في Fresh Home! سجل دخولك لمتابعة طلباتك."}
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

        {resetMode ? (
          /* Password Reset Form */
          <form onSubmit={handlePasswordReset} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">البريد الإلكتروني</label>
              <div className="relative flex items-center">
                <input 
                  type="email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@example.com"
                  className="w-full p-3 pl-10 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                  required
                />
                <Mail className="w-4 h-4 text-slate-400 absolute left-3" />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 rounded-xl bg-[#0091FF] hover:bg-[#0077E6] text-white font-black text-xs shadow-md shadow-blue-500/20 transition-all flex items-center justify-center gap-2 glow-button cursor-pointer"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              <span>إرسال رابط الاستعادة</span>
            </button>

            <button
              type="button"
              onClick={() => { setResetMode(false); setErrorMsg(""); setSuccessMsg(""); }}
              className="w-full text-center text-xs font-bold text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-white pt-2 cursor-pointer"
            >
              تذكرت كلمة المرور؟ تسجيل الدخول
            </button>
          </form>
        ) : (
          /* Standard Login Form */
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">البريد الإلكتروني</label>
              <div className="relative flex items-center">
                <input 
                  type="email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@example.com"
                  className="w-full p-3 pl-10 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                  required
                />
                <Mail className="w-4 h-4 text-slate-400 absolute left-3" />
              </div>
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between items-center">
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">كلمة المرور</label>
                <button
                  type="button"
                  onClick={() => { setResetMode(true); setErrorMsg(""); setSuccessMsg(""); }}
                  className="text-[11px] font-bold text-[#0091FF] dark:text-[#22A5FC] hover:underline cursor-pointer"
                >
                  نسيت كلمة المرور؟
                </button>
              </div>
              <div className="relative flex items-center">
                <input 
                  type="password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full p-3 pl-10 rounded-xl border border-slate-200 dark:border-blue-900/60 text-xs font-bold focus:border-[#0091FF] focus:outline-none bg-[#F8FAFC] dark:bg-[#050D24] text-slate-900 dark:text-white text-left font-sans"
                  required
                />
                <Lock className="w-4 h-4 text-slate-400 absolute left-3" />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white font-black text-xs shadow-md shadow-blue-500/25 transition-all flex items-center justify-center gap-2 glow-button cursor-pointer"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              <span>تسجيل الدخول</span>
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
                className="w-full mt-2 py-3 rounded-xl border border-slate-200 dark:border-blue-900/60 hover:bg-slate-50 dark:hover:bg-[#050D24] text-slate-700 dark:text-slate-200 font-bold text-xs flex items-center justify-center gap-2.5 transition-colors shadow-xs cursor-pointer"
              >
                <GoogleIcon className="w-4 h-4" />
                <span>المتابعة باستخدام Google</span>
              </button>
            </div>

            <div className="text-center pt-4 border-t border-slate-100 dark:border-blue-900/40 text-xs text-slate-500 dark:text-slate-400 font-medium">
              <span>ليس لديك حساب؟ </span>
              <Link href={`/register?redirect=${encodeURIComponent(redirectPath)}`} className="text-[#0091FF] dark:text-[#22A5FC] font-black hover:underline">
                إنشاء حساب جديد
              </Link>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#040A1C] flex flex-col font-sans transition-colors duration-300">
      <Header />
      <main className="flex-1 flex items-center justify-center pt-24 pb-16">
        <Suspense fallback={
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-[#0091FF]"></div>
        }>
          <LoginContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
