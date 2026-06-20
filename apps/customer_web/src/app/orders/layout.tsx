import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "فريش هوم | تتبع حالة طلبك الفورية",
  description: "تتبع حالة زيارة فني فريش هوم وتحديثات الوصول والموقع الجغرافي.",
  robots: {
    index: false,
    follow: false
  }
};

export default function OrdersLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
