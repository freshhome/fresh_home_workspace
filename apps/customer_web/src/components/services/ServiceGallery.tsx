"use client";

import { useState, useEffect, useCallback } from "react";
import Image from "next/image";
import { motion, AnimatePresence } from "framer-motion";
import { 
  X, ChevronLeft, ChevronRight, Maximize2, 
  Image as ImageIcon 
} from "lucide-react";
import { supabase } from "@/lib/supabase";

export interface GalleryItem {
  url: string;
  id?: string;
  caption?: string;
}

interface ServiceGalleryProps {
  gallery?: (GalleryItem | string)[] | null;
  serviceTitle?: string;
}

function resolveImageUrl(img?: string | GalleryItem | null): string {
  if (!img) return "";
  const rawUrl = typeof img === "string" ? img : img.url;
  if (!rawUrl || typeof rawUrl !== "string") return "";
  const clean = rawUrl.trim();
  if (clean.startsWith("http://") || clean.startsWith("https://") || clean.startsWith("/")) {
    return clean;
  }
  const { data } = supabase.storage.from("service_images").getPublicUrl(clean);
  return data?.publicUrl || clean;
}

export default function ServiceGallery({ gallery, serviceTitle }: ServiceGalleryProps) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);

  // Normalize gallery items
  const items: GalleryItem[] = (gallery || [])
    .map((item, idx) => {
      if (typeof item === "string") {
        return { url: resolveImageUrl(item), id: String(idx) };
      }
      return {
        url: resolveImageUrl(item.url),
        id: item.id || String(idx),
        caption: item.caption,
      };
    })
    .filter((item) => item.url && item.url.trim().length > 0);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (selectedIndex === null) return;
      if (e.key === "Escape") setSelectedIndex(null);
      if (e.key === "ArrowRight") {
        setSelectedIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : items.length - 1));
      }
      if (e.key === "ArrowLeft") {
        setSelectedIndex((prev) => (prev !== null && prev < items.length - 1 ? prev + 1 : 0));
      }
    },
    [selectedIndex, items.length]
  );

  useEffect(() => {
    if (selectedIndex !== null) {
      document.body.style.overflow = "hidden";
      window.addEventListener("keydown", handleKeyDown);
    } else {
      document.body.style.overflow = "unset";
    }
    return () => {
      document.body.style.overflow = "unset";
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex, handleKeyDown]);

  if (!items || items.length === 0) {
    return null;
  }

  const showNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (selectedIndex === null) return;
    setSelectedIndex((prev) => (prev !== null && prev < items.length - 1 ? prev + 1 : 0));
  };

  const showPrev = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (selectedIndex === null) return;
    setSelectedIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : items.length - 1));
  };

  const maxVisible = 4;
  const visibleItems = items.slice(0, maxVisible);
  const remainingCount = items.length - maxVisible;

  return (
    <section className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-xl bg-blue-50 dark:bg-blue-950/50 border border-blue-200/60 dark:border-blue-800/50 flex items-center justify-center text-[#0091FF]">
            <ImageIcon className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm sm:text-base font-black text-slate-900 dark:text-white tracking-tight">
              صور واقعية من تنفيذنا
            </h2>
          </div>
        </div>

        <span className="text-[11px] font-extrabold px-2.5 py-1 rounded-full bg-slate-100 dark:bg-blue-900/30 text-slate-600 dark:text-blue-300 border border-slate-200/80 dark:border-blue-800/40">
          {items.length} {items.length === 1 ? "صورة" : "صور"}
        </span>
      </div>

      {/* Gallery Layout */}
      {items.length === 1 ? (
        /* Single Image Featured Banner with Ambient Blur */
        <div
          onClick={() => setSelectedIndex(0)}
          className="group relative w-full aspect-4/3 sm:aspect-16/9 overflow-hidden bg-slate-900 dark:bg-slate-950 rounded-2xl sm:rounded-3xl border border-slate-200/80 dark:border-blue-900/50 cursor-pointer shadow-sm"
        >
          {/* Background Layer: Ambient Blur */}
          <div className="absolute inset-0 overflow-hidden pointer-events-none select-none">
            <Image
              src={items[0].url}
              alt=""
              aria-hidden="true"
              fill
              sizes="(max-width: 768px) 100vw, 800px"
              priority={true}
              className="object-cover opacity-40 blur-xl scale-125 select-none pointer-events-none transform-gpu"
            />
          </div>

          {/* Foreground Layer: Full Original Image Without Cropping */}
          <Image
            src={items[0].url}
            alt={items[0].caption || serviceTitle || "صورة من أعمال الخدمة"}
            fill
            sizes="(max-width: 768px) 100vw, 800px"
            priority={true}
            className="object-contain z-10 drop-shadow-2xl transition-transform duration-500 group-hover:scale-105"
          />

          {/* Interactive Hover Overlay (z-20) */}
          <div className="absolute inset-0 z-20 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-4 pointer-events-none">
            <span className="text-white text-xs font-bold flex items-center gap-1.5 bg-black/50 backdrop-blur-md px-3 py-1.5 rounded-xl">
              <Maximize2 className="w-3.5 h-3.5" />
              عرض بالحجم الكامل
            </span>
          </div>

          {/* Caption (z-20) */}
          {items[0].caption && (
            <div className="absolute bottom-3 right-3 z-20 max-w-[80%] bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-xl text-white text-xs font-medium">
              {items[0].caption}
            </div>
          )}
        </div>
      ) : (
        /* Multi-Image Explicit Responsive Grid with Strict Relative Cells */
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
          {visibleItems.map((item, idx) => {
            const isFirst = idx === 0;
            const isLastVisible = idx === maxVisible - 1 && remainingCount > 0;

            return (
              <div
                key={item.id || idx}
                onClick={() => setSelectedIndex(idx)}
                className="group relative w-full aspect-square overflow-hidden bg-slate-900 dark:bg-slate-950 rounded-xl sm:rounded-2xl border border-slate-200/80 dark:border-blue-900/50 cursor-pointer shadow-xs"
              >
                {/* Background Layer: Ambient Blur */}
                <div className="absolute inset-0 overflow-hidden pointer-events-none select-none">
                  <Image
                    src={item.url}
                    alt=""
                    aria-hidden="true"
                    fill
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                    priority={isFirst}
                    className="object-cover opacity-40 blur-xl scale-125 select-none pointer-events-none transform-gpu"
                  />
                </div>

                {/* Foreground Layer: Full Original Image Without Cropping */}
                <Image
                  src={item.url}
                  alt={item.caption || serviceTitle || `صورة المعرض ${idx + 1}`}
                  fill
                  sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                  priority={isFirst}
                  className="object-contain z-10 drop-shadow-2xl transition-transform duration-500 group-hover:scale-105"
                />

                {/* Interactive Hover Overlay (z-20) */}
                {!isLastVisible && (
                  <div className="absolute inset-0 z-20 bg-gradient-to-t from-black/50 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end justify-between p-3 pointer-events-none">
                    <span className="text-white text-[11px] font-bold flex items-center gap-1 bg-black/50 backdrop-blur-md px-2.5 py-1 rounded-lg">
                      <Maximize2 className="w-3 h-3" />
                      تكبير
                    </span>
                  </div>
                )}

                {/* Remaining Photos Counter Badge (Strictly Constrained to this Card Cell) */}
                {isLastVisible && (
                  <div className="absolute inset-0 z-30 bg-slate-950/80 backdrop-blur-xs flex flex-col items-center justify-center text-white p-2 select-none">
                    <span className="text-xl sm:text-2xl font-black">+{remainingCount}</span>
                    <span className="text-[10px] sm:text-xs font-bold text-slate-200 mt-1">
                      {remainingCount === 1 ? "صورة إضافية" : "صور إضافية"}
                    </span>
                  </div>
                )}

                {/* Caption (z-20) */}
                {item.caption && !isLastVisible && (
                  <div className="absolute bottom-2 right-2 z-20 max-w-[85%] truncate bg-black/60 backdrop-blur-md px-2 py-0.5 rounded-md text-white text-[10px] font-medium">
                    {item.caption}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Lightbox Modal */}
      <AnimatePresence>
        {selectedIndex !== null && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={() => setSelectedIndex(null)}
            className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex flex-col items-center justify-center p-4 sm:p-8"
          >
            {/* Top Bar */}
            <div 
              onClick={(e) => e.stopPropagation()} 
              className="w-full max-w-5xl flex items-center justify-between text-white mb-3 px-2"
            >
              <div className="flex items-center gap-2">
                <span className="text-xs sm:text-sm font-bold bg-white/10 px-3 py-1 rounded-full backdrop-blur-md">
                  {selectedIndex + 1} من {items.length}
                </span>
                {serviceTitle && (
                  <span className="text-xs text-slate-300 font-medium hidden sm:inline">
                    {serviceTitle}
                  </span>
                )}
              </div>

              <button
                onClick={() => setSelectedIndex(null)}
                aria-label="إغلاق المعرض"
                className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Main Lightbox Content */}
            <div 
              onClick={(e) => e.stopPropagation()}
              className="relative w-full max-w-5xl h-[65vh] sm:h-[75vh] flex items-center justify-center"
            >
              <AnimatePresence mode="wait">
                <motion.div
                  key={selectedIndex}
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ duration: 0.2 }}
                  className="relative w-full h-full rounded-2xl overflow-hidden"
                >
                  {/* Lightbox Ambient Blur */}
                  <div className="absolute inset-0 overflow-hidden pointer-events-none select-none">
                    <Image
                      src={items[selectedIndex].url}
                      alt=""
                      aria-hidden="true"
                      fill
                      sizes="100vw"
                      className="object-cover opacity-30 blur-2xl scale-125 select-none pointer-events-none transform-gpu"
                    />
                  </div>

                  {/* Foreground Full Image */}
                  <Image
                    src={items[selectedIndex].url}
                    alt={items[selectedIndex].caption || serviceTitle || "صورة المعرض"}
                    fill
                    sizes="(max-width: 1200px) 100vw, 1200px"
                    className="object-contain z-10 drop-shadow-2xl"
                    priority
                  />
                </motion.div>
              </AnimatePresence>

              {/* Navigation Arrows */}
              {items.length > 1 && (
                <>
                  <button
                    onClick={showPrev}
                    aria-label="الصورة السابقة"
                    className="absolute right-2 sm:right-4 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-black/50 hover:bg-black/80 border border-white/10 text-white flex items-center justify-center transition-transform hover:scale-110 cursor-pointer z-20"
                  >
                    <ChevronRight className="w-6 h-6" />
                  </button>

                  <button
                    onClick={showNext}
                    aria-label="الصورة التالية"
                    className="absolute left-2 sm:left-4 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-black/50 hover:bg-black/80 border border-white/10 text-white flex items-center justify-center transition-transform hover:scale-110 cursor-pointer z-20"
                  >
                    <ChevronLeft className="w-6 h-6" />
                  </button>
                </>
              )}
            </div>

            {/* Caption & Thumbnails strip */}
            <div 
              onClick={(e) => e.stopPropagation()} 
              className="w-full max-w-5xl mt-3 flex flex-col items-center gap-2"
            >
              {items[selectedIndex].caption && (
                <p className="text-white text-xs sm:text-sm font-medium text-center bg-black/50 backdrop-blur-md px-4 py-1.5 rounded-xl max-w-xl">
                  {items[selectedIndex].caption}
                </p>
              )}

              {/* Thumbnails strip with blur backdrop */}
              {items.length > 1 && (
                <div className="flex items-center gap-2 overflow-x-auto max-w-full py-1 px-2 no-scrollbar">
                  {items.map((thumb, idx) => (
                    <button
                      key={thumb.id || idx}
                      onClick={() => setSelectedIndex(idx)}
                      className={`relative w-12 h-12 rounded-xl overflow-hidden shrink-0 border-2 transition-all bg-slate-900 ${
                        selectedIndex === idx
                          ? "border-[#0091FF] scale-105"
                          : "border-transparent opacity-60 hover:opacity-100"
                      }`}
                    >
                      <Image
                        src={thumb.url}
                        alt=""
                        aria-hidden="true"
                        fill
                        sizes="48px"
                        className="object-cover"
                      />
                    </button>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
}
