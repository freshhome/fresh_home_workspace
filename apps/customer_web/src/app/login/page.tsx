"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, ArrowRight, AlertCircle } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

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
      // Get origin dynamically in client
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

    if (!email.trim()) {
      setErrorMsg("يرجى كتابة البريد الإلكتروني أولاً.");
      return;
    }

    setLoading(true);
    try {
      const origin = typeof window !== "undefined" ? window.location.origin : "";
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${origin}/login`,
      });

      if (error) throw error;

      setSuccessMsg("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.");
      setTimeout(() => {
        setResetMode(false);
      }, 5000);
    } catch (err: any) {
      console.error("Reset password error:", err);
      setErrorMsg(err.message || "حدث خطأ أثناء إرسال طلب إعادة التعيين.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto my-12 px-4">
      <div className="bg-white/80 backdrop-blur-md rounded-3xl p-8 border border-slate-200/60 shadow-[0_8px_32px_rgba(0,0,0,0.03)] text-right">
        {/* Back option */}
        <Link 
          href="/" 
          className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-400 hover:text-primary transition-colors mb-6"
        >
          <ArrowRight className="w-3.5 h-3.5" />
          <span>العودة للرئيسية</span>
        </Link>

        <div className="mb-8">
          <h2 className="text-2xl font-black text-slate-800 font-sans">
            {resetMode ? "إعادة تعيين كلمة المرور" : "تسجيل الدخول"}
          </h2>
          <p className="text-slate-400 text-xs mt-1">
            {resetMode 
              ? "أدخل بريدك الإلكتروني وسنرسل لك رابطاً لاستعادة حسابك." 
              : "مرحباً بك مجدداً في فريش هوم! سجل دخولك لمتابعة حجوزاتك."}
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-rose-50 border border-rose-100 text-rose-700 text-xs font-bold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-500" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-700 text-xs font-bold flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 shrink-0 text-emerald-600" />
            <span>{successMsg}</span>
          </div>
        )}

        {resetMode ? (
          /* Password Reset Form */
          <form onSubmit={handlePasswordReset} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-600">البريد الإلكتروني</label>
              <div className="relative flex items-center">
                <Mail className="absolute right-3.5 w-4 h-4 text-slate-400" />
                <input 
                  type="email" 
                  placeholder="name@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full p-3 pr-10 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-left text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md shadow-primary/10 hover:bg-primary/95 transition-all active:scale-[0.99] disabled:opacity-50"
            >
              {loading ? "جاري الإرسال..." : "إرسال رابط الاستعادة"}
            </button>

            <button
              type="button"
              onClick={() => {
                setResetMode(false);
                setErrorMsg("");
              }}
              className="w-full text-center text-xs font-bold text-slate-500 hover:text-slate-700 block mt-2 transition-colors"
            >
              الرجوع لتسجيل الدخول
            </button>
          </form>
        ) : (
          /* Login Form */
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-600">البريد الإلكتروني</label>
              <div className="relative flex items-center">
                <Mail className="absolute right-3.5 w-4 h-4 text-slate-400" />
                <input 
                  type="email" 
                  placeholder="name@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full p-3 pr-10 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-left text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                  required
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between items-center">
                <label className="block text-xs font-bold text-slate-600">كلمة المرور</label>
                <button
                  type="button"
                  onClick={() => {
                    setResetMode(true);
                    setErrorMsg("");
                    setSuccessMsg("");
                  }}
                  className="text-[10px] font-bold text-primary hover:underline"
                >
                  نسيت كلمة المرور؟
                </button>
              </div>
              <div className="relative flex items-center">
                <Lock className="absolute right-3.5 w-4 h-4 text-slate-400" />
                <input 
                  type="password" 
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full p-3 pr-10 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-left text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-primary text-white font-extrabold text-xs shadow-md shadow-primary/10 hover:bg-primary/95 transition-all active:scale-[0.99] disabled:opacity-50"
            >
              {loading ? "جاري تسجيل الدخول..." : "تسجيل الدخول"}
            </button>

            {/* Divider */}
            <div className="relative flex py-2 items-center">
              <div className="flex-grow border-t border-slate-200"></div>
              <span className="flex-shrink mx-4 text-slate-400 text-[10px] font-bold">أو سجل دخولك عبر</span>
              <div className="flex-grow border-t border-slate-200"></div>
            </div>

            {/* Google OAuth Login Button */}
            <button
              type="button"
              onClick={handleGoogleLogin}
              className="w-full py-2.5 rounded-xl border border-slate-200 hover:border-slate-300 bg-white hover:bg-slate-50 text-slate-700 font-bold text-xs flex items-center justify-center gap-2 transition-all active:scale-[0.99]"
            >
              <GoogleIcon className="w-4 h-4 text-red-500 fill-red-500" />
              <span>حساب جوجل (Google)</span>
            </button>

            <div className="text-center pt-4 border-t border-slate-100 text-xs text-slate-500">
              <span>ليس لديك حساب؟ </span>
              <Link href={`/register?redirect=${encodeURIComponent(redirectPath)}`} className="text-primary font-black hover:underline">
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
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Header />
      <main className="flex-grow flex items-center justify-center py-8">
        <Suspense fallback={
          <div className="flex justify-center items-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
          </div>
        }>
          <LoginContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
