import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "فريش هوم | احجز خدمات التنظيف والصيانة المنزلية بسهولة",
  description: "اطلب خدمات التنظيف، مكافحة الحشرات، والصيانة المنزلية من فريش هوم. فنيون محترفون وموثوقون، تسعير ديناميكي فوري، وجودة مضمونة.",
  keywords: ["تنظيف منازل", "مكافحة حشرات", "صيانة تكييفات", "سباكة", "كهرباء", "صنايعي في مصر", "خدمات منزلية"],
  icons: {
    icon: [
      { url: "/images/fresh_home_tab_icon.svg", type: "image/svg+xml" },
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/images/fresh_home_logo.png", sizes: "32x32", type: "image/png" },
    ],
    shortcut: "/images/fresh_home_tab_icon.svg",
    apple: "/images/fresh_home_tab_icon.svg",
  },
  openGraph: {
    title: "فريش هوم | احجز خدمات التنظيف والصيانة المنزلية بسهولة",
    description: "اطلب خدمات التنظيف والصيانة من فريش هوم بأسعار فورية وجودة مضمونة.",
    images: [
      {
        url: "/images/fresh_home_logo.png",
        width: 1200,
        height: 630,
        alt: "Fresh Home Logo",
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
      <head>
        <link rel="icon" href="/images/fresh_home_tab_icon.svg" type="image/svg+xml" />
        <link rel="shortcut icon" href="/images/fresh_home_tab_icon.svg" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/images/fresh_home_tab_icon.svg" />
      </head>
      <body className="min-h-full flex flex-col font-sans bg-background text-foreground">
        {children}
      </body>
    </html>
  );
}
