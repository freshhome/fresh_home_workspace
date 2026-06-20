import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "فريش هوم | خدمات صيانة وتنظيف منزلية احترافية في مصر",
  description: "اطلب خدمات التنظيف، مكافحة الحشرات، والصيانة المنزلية من فريش هوم. فنيون محترفون وموثوقون، تسعير ديناميكي فوري، وجودة مضمونة.",
  keywords: ["تنظيف منازل", "مكافحة حشرات", "صيانة تكييفات", "سباكة", "كهرباء", "صنايعي في مصر", "خدمات منزلية"],
  openGraph: {
    title: "فريش هوم | خدمات صيانة وتنظيف منزلية احترافية",
    description: "اطلب خدمات التنظيف والصيانة من فريش هوم بأسعار فورية وجودة مضمونة.",
    images: [
      {
        url: "/images/og_share.png",
        width: 1200,
        height: 630,
        alt: "Fresh Home",
      },
    ],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" className="h-full antialiased">
      <body className="min-h-full flex flex-col font-sans bg-background text-foreground">
        {children}
      </body>
    </html>
  );
}
