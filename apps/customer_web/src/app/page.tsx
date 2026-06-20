import Header from "@/components/Header";
import Hero from "@/components/Hero";
import ServicesGrid from "@/components/ServicesGrid";
import PopularServices from "@/components/PopularServices";
import TrustSection from "@/components/TrustSection";
import Footer from "@/components/Footer";

export default function Home() {
  const schemaOrgData = {
    "@context": "https://schema.org",
    "@type": "HomeAndConstructionBusiness",
    "name": "فريش هوم | Fresh Home",
    "image": "https://dsddwqdixsdhaspfafuy.supabase.co/storage/v1/object/public/service_images/service_assets/core/images/app_icon_customer.png",
    "url": "https://freshhome-egypt.com",
    "telephone": "+201012345678",
    "priceRange": "$$",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "المعادي، شارع 9",
      "addressLocality": "القاهرة",
      "addressRegion": "القاهرة",
      "postalCode": "11728",
      "addressCountry": "EG"
    },
    "geo": {
      "@type": "GeoCoordinates",
      "latitude": 29.9602,
      "longitude": 31.2569
    },
    "openingHoursSpecification": {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ],
      "opens": "08:00",
      "closes": "22:00"
    },
    "sameAs": [
      "https://www.facebook.com/freshhome",
      "https://www.instagram.com/freshhome"
    ]
  };

  return (
    <>
      {/* Schema.org Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schemaOrgData) }}
      />

      {/* Header Bar */}
      <Header />
      
      <main className="flex-1">
        {/* Banner with main copy & stats */}
        <Hero />
        
        {/* Main Service Categories */}
        <ServicesGrid />
        
        {/* Popular Sub-services list */}
        <PopularServices />
        
        {/* Core trust guarantees */}
        <TrustSection />
      </main>
      
      {/* Footer info & support details */}
      <Footer />
    </>
  );
}
