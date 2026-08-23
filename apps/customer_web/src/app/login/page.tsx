"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, ArrowRight, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Logo from "@/components/Logo";

const GoogleIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg viewBox="0 0 24 24" fill="currentColor" {...props}>
    <path d="M12.24 10.285V14.4h6.887c-.648 2.41-2.519 4.114-5.136 4.114-3.34 0-6.05-2.71-6.05-6.05s2.71-6.05 6.05-6.05c1.493 0 2.859.544 3.918 1.442l3.23-3.23C19.16 2.766 15.932 1.5 12.24 1.5 6.44 1.5 1.74 6.2 1.74 12s4.7 10.5 10.5 10.5c5.73 0 10.53-4.114 10.53-10.5 0-.713-.075-1.4-.21-2.073L12.24 10.285z" />
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
