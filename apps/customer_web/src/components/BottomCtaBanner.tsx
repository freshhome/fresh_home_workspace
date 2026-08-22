"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";

const WhatsAppIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg viewBox="0 0 24 24" fill="currentColor" {...props}>
    <path d="M12.012 2c-5.506 0-9.989 4.478-9.99 9.984a9.96 9.96 0 001.37 5.054L2 22l5.13-1.346a9.921 9.921 0 004.882 1.28h.005c5.507 0 9.99-4.479 9.99-9.986C22.007 6.478 17.518 2 12.012 2zm6.09 13.982c-.268.76-1.531 1.393-2.13 1.462-.599.07-1.192.327-3.834-.72-2.641-1.047-4.329-3.73-4.462-3.907-.133-.177-1.082-1.442-1.082-2.75 0-1.307.683-1.95.927-2.215.244-.265.532-.332.71-.332.177 0 .354.004.51.011.165.008.387-.06.608.48.221.54.757 1.848.823 1.98.066.133.11.288.022.464-.088.177-.133.288-.266.442-.133.155-.28.346-.4.496-.133.167-.277.348-.12.62.156.27.691 1.139 1.482 1.842.92.818 1.693 1.07 1.936 1.193.244.122.388.106.532-.06.144-.167.62-.72.787-.962.167-.243.332-.2.554-.117.221.083 1.405.663 1.649.785.244.122.409.182.469.288.06.106.06.612-.208 1.372z" />
  </svg>
);

export default function BottomCtaBanner() {
  return (
    <section className="bg-[#050D24] pt-8 pb-14 px-4 sm:px-6 lg:px-8 text-white">
      <div className="max-w-7xl mx-auto">
        <div className="rounded-3xl bg-gradient-to-r from-[#071739] via-[#0D2A68] to-[#071739] border border-blue-900/60 p-8 sm:p-10 lg:p-12 shadow-2xl flex flex-col md:flex-row items-center justify-between gap-8 relative overflow-hidden">
          {/* Subtle decorative geometric overlay */}
          <div className="absolute inset-0 bg-[radial-gradient(#22a5fc_1px,transparent_1px)] [background-size:16px_16px] opacity-10 pointer-events-none" />

          {/* Right Text */}
          <div className="text-center md:text-right space-y-2 relative z-10">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-black text-white">
              جاهز تخلي بيتك <span className="text-[#22A5FC]">Fresh؟</span>
            </h2>
            <p className="text-xs sm:text-sm text-slate-300 font-medium">
              احجز خدمتك الآن واستمتع بتجربة أسهل وأكثر راحة ونظافة.
            </p>
          </div>

          {/* Left Action Buttons */}
          <div className="flex flex-col sm:flex-row items-center gap-3.5 relative z-10 w-full sm:w-auto">
            {/* Blue Book Now Button */}
            <Link
              href="/booking"
              className="w-full sm:w-auto px-8 py-3.5 rounded-xl bg-gradient-to-r from-[#0091FF] to-[#0077E6] text-white text-xs font-black glow-button flex items-center justify-center gap-2 shadow-lg"
            >
              <span>احجز الآن</span>
              <ArrowLeft className="w-4 h-4" />
            </Link>

            {/* Green WhatsApp Button */}
            <a
              href="https://wa.me/201000000000"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-[#25D366] hover:bg-[#20bd5a] text-white text-xs font-black glow-whatsapp flex items-center justify-center gap-2 shadow-lg transition-all"
            >
              <WhatsAppIcon className="w-4 h-4" />
              <span>تواصل عبر WhatsApp</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
