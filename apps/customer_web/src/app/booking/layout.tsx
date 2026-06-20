import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "فريش هوم | احجز خدمتك المنزلية الآن",
  description: "تدفق حجز الخدمات المنزلية المعتمدة لشركة فريش هوم كضيف.",
  robots: {
    index: false,
    follow: false
  }
};

export default function BookingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
