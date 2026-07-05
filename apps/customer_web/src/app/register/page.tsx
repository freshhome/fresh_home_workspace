"use client";

import { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ShieldCheck, Mail, Lock, User, Phone, ArrowRight, AlertCircle } from "lucide-react";
import { supabase } from "@/lib/supabase";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

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
            app_type: "client", // Triggers role = client in public.user_roles
          }
        }
      });

      if (error) throw error;

      if (data?.user) {
        // 2. Check if a session exists (auto-signin enabled)
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
            // Don't fail the registration if phone insert fails (e.g. RLS transient or duplicate)
          }

          setSuccessMsg("تم إنشاء الحساب بنجاح! جاري تحويلك...");
          setTimeout(() => {
            router.push(redirectPath);
            router.refresh();
          }, 1500);
        } else {
          // Session doesn't exist, email confirmation required
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
    <div className="max-w-md mx-auto my-8 px-4">
      <div className="bg-white/80 backdrop-blur-md rounded-3xl p-8 border border-slate-200/60 shadow-[0_8px_32px_rgba(0,0,0,0.03)] text-right">
        {/* Back link */}
        <Link 
          href="/login" 
          className="inline-flex items-center gap-1 text-[11px] font-bold text-slate-400 hover:text-primary transition-colors mb-6"
        >
          <ArrowRight className="w-3.5 h-3.5" />
          <span>الرجوع لصفحة تسجيل الدخول</span>
        </Link>

        <div className="mb-6">
          <h2 className="text-2xl font-black text-slate-800 font-sans">إنشاء حساب جديد</h2>
          <p className="text-slate-400 text-xs mt-1">
            سجل معنا للاستفادة من حفظ عناوينك وتتبع حجوزاتك بسهولة.
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

        <form onSubmit={handleRegister} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-600">الاسم الأول</label>
              <div className="relative flex items-center">
                <User className="absolute right-3 w-4 h-4 text-slate-400" />
                <input 
                  type="text" 
                  placeholder="محمد"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full p-2.5 pr-9 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                  required
                />
              </div>
            </div>
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-600">الاسم الأخير</label>
              <div className="relative flex items-center">
                <User className="absolute right-3 w-4 h-4 text-slate-400" />
                <input 
                  type="text" 
                  placeholder="علي"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full p-2.5 pr-9 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                  required
                />
              </div>
            </div>
          </div>

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
            <label className="block text-xs font-bold text-slate-600">رقم الهاتف (الواتساب)</label>
            <div className="relative flex items-center">
              <Phone className="absolute right-3.5 w-4 h-4 text-slate-400" />
              <input 
                type="tel" 
                placeholder="01012345678"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full p-3 pr-10 rounded-xl border border-slate-200 text-xs font-bold focus:border-primary focus:outline-none bg-white text-left text-slate-800 focus:ring-2 focus:ring-primary/10 transition-all placeholder-slate-300"
                required
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-slate-600">كلمة المرور</label>
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

          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-slate-600">تأكيد كلمة المرور</label>
            <div className="relative flex items-center">
              <Lock className="absolute right-3.5 w-4 h-4 text-slate-400" />
              <input 
                type="password" 
                placeholder="••••••••"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
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
            {loading ? "جاري إنشاء الحساب..." : "إنشاء حسابي الجديد"}
          </button>
        </form>
      </div>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Header />
      <main className="flex-grow flex items-center justify-center py-8">
        <Suspense fallback={
          <div className="flex justify-center items-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary"></div>
          </div>
        }>
          <RegisterContent />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
