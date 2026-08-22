import Header from "@/components/Header";
import Hero from "@/components/Hero";
import ServicesSection from "@/components/ServicesSection";
import PostConstructionBanner from "@/components/PostConstructionBanner";
import HowItWorksSection from "@/components/HowItWorksSection";
import PricingTeaser from "@/components/PricingTeaser";
import QualityAdvantage from "@/components/QualityAdvantage";
import LocationsSection from "@/components/LocationsSection";
import FaqSection from "@/components/FaqSection";
import BottomCtaBanner from "@/components/BottomCtaBanner";
import Footer from "@/components/Footer";

export default function Home() {
  const schemaOrgData = {
    "@context": "https://schema.org",
    "@type": "HomeAndConstructionBusiness",
    "name": "فريش هوم | Fresh Home",
    "image": "/images/hero_transformation.jpg",
    "url": "https://freshhome-egypt.com",
    "telephone": "+201000000000",
    "priceRange": "$$",
    "address": {
      "@type": "PostalAddress",
      "addressLocality": "القاهرة والجيزة",
      "addressRegion": "القاهرة",
      "addressCountry": "EG"
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
    }
  };

  return (
    <>
      {/* Schema.org Structured Data */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schemaOrgData) }}
      />

      {/* Navigation Header */}
      <Header />

      <main className="flex-1 overflow-hidden">
        {/* 1. Hero Section + Floating Trust Bar */}
        <Hero />

        {/* 2. All Services Showcase Grid */}
        <ServicesSection />

        {/* 3. Featured Post-Construction Banner with Before & After */}
        <PostConstructionBanner />

        {/* 4. How It Works (4 Steps Stepper) */}
        <HowItWorksSection />

        {/* 5. Pricing Teaser & Calculator */}
        <PricingTeaser />

        {/* 6. Quality & Advantage Section */}
        <QualityAdvantage />

        {/* 7. Coverage & Locations (Cairo & Giza) */}
        <LocationsSection />

        {/* 8. FAQ Accordion with 3D Glowing Lamp/Chair */}
        <div id="faq">
          <FaqSection />
        </div>

        {/* 9. Bottom High-Impact CTA Banner */}
        <BottomCtaBanner />
      </main>

      {/* 10. Official Footer */}
      <Footer />
    </>
  );
}
