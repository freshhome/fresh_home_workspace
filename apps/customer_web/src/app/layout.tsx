import type { Metadata, Viewport } from "next";
import "./globals.css";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#06112c" },
  ],
};

const SITE_URL = "https://freshhomeeg.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "فريش هوم | احجز خدمات التنظيف والصيانة المنزلية بسهولة",
  description: "اطلب خدمات التنظيف، مكافحة الحشرات، والصيانة المنزلية من فريش هوم. فنيون محترفون وموثوقون، تسعير ديناميكي فوري، وجودة مضمونة.",
  keywords: [
    "فريش هوم",
    "Fresh Home",
    "freshhomeeg",
    "تنظيف منازل",
    "مكافحة حشرات",
    "صيانة تكييفات",
    "سباكة",
    "كهرباء",
    "صنايعي في مصر",
    "خدمات منزلية"
  ],
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    shortcut: "/favicon.ico",
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
  openGraph: {
    title: "فريش هوم | احجز خدمات التنظيف والصيانة المنزلية بسهولة",
    description: "اطلب خدمات التنظيف والصيانة من فريش هوم بأسعار فورية وجودة مضمونة.",
    url: SITE_URL,
    siteName: "Fresh Home",
    locale: "ar_EG",
    type: "website",
    images: [
      {
        url: "/images/fresh_home_logo.png",
        width: 1200,
        height: 630,
        alt: "Fresh Home - فريش هوم",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "فريش هوم | خدمات التنظيف والصيانة المنزلية",
    description: "احجز خدمات منزلك بكل سهولة وأمان مع Fresh Home.",
    images: ["/images/fresh_home_logo.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "@id": `${SITE_URL}/#organization`,
        "name": "Fresh Home | فريش هوم",
        "url": SITE_URL,
        "logo": {
          "@type": "ImageObject",
          "url": `${SITE_URL}/images/fresh_home_logo.png`,
          "caption": "Fresh Home Logo"
        },
        "image": `${SITE_URL}/images/fresh_home_logo.png`,
        "description": "منصة مصرية متخصصة في تقديم خدمات التنظيف والصيانة المنزلية ومكافحة الحشرات بجودة معتمدة.",
        "address": {
          "@type": "PostalAddress",
          "addressCountry": "EG"
        }
      },
      {
        "@type": "WebSite",
        "@id": `${SITE_URL}/#website`,
        "url": SITE_URL,
        "name": "Fresh Home",
        "publisher": {
          "@id": `${SITE_URL}/#organization`
        }
      }
    ]
  };

  return (
    <html lang="ar" dir="rtl" className="h-full antialiased">
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" href="/icon.svg" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" sizes="180x180" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="min-h-full flex flex-col font-sans bg-background text-foreground">
        {children}
      </body>
    </html>
  );
}
