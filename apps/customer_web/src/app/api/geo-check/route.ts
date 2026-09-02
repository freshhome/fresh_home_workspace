import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  
  // Allow manual testing simulation via query param
  if (searchParams.get("simulateOutside") === "true") {
    return NextResponse.json({
      detected: true,
      isOutsideCoverage: true,
      city: "Alexandria",
      region: "ALX",
      country: "EG",
      simulated: true,
    });
  }

  // Vercel Edge Geolocation Headers
  const city = request.headers.get("x-vercel-ip-city") || "";
  const region = request.headers.get("x-vercel-ip-country-region") || "";
  const country = request.headers.get("x-vercel-ip-country") || "";

  // If running in development or outside Vercel Edge where headers are not injected
  if (!country && !city && !region) {
    return NextResponse.json({
      detected: false,
      isOutsideCoverage: false,
      city: null,
      region: null,
      country: null,
    });
  }

  const isEgypt = country.toUpperCase() === "EG";
  const lowerCity = city.toLowerCase();
  const lowerRegion = region.toLowerCase();

  const isCairoOrGiza =
    lowerCity.includes("cairo") ||
    lowerCity.includes("giza") ||
    lowerCity.includes("gizeh") ||
    lowerCity.includes("october") ||
    lowerCity.includes("zayed") ||
    lowerCity.includes("rehab") ||
    lowerCity.includes("madinaty") ||
    lowerRegion === "c" ||
    lowerRegion === "gz";

  const isOutsideCoverage = !isEgypt || !isCairoOrGiza;

  return NextResponse.json({
    detected: true,
    isOutsideCoverage,
    city: city ? decodeURIComponent(city) : null,
    region: region || null,
    country: country || null,
  });
}
