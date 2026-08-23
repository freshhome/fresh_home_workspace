"use client";

import { useState, useEffect } from "react";
import { supabase } from "./supabase";

/**
 * Normalizes any raw phone number string into clean WhatsApp international format.
 * (e.g. "+20 101 234 5678" -> "201012345678", "01012345678" -> "201012345678")
 */
export function formatWhatsAppNumber(rawNumber?: string | null): string {
  if (!rawNumber) return "201000000000";
  
  // Remove all non-digits
  let digits = rawNumber.replace(/\D/g, "");
  
  if (!digits) return "201000000000";
  
  // If Egyptian local format starting with 01... (11 digits), prepend 2
  if (digits.startsWith("01") && digits.length === 11) {
    digits = "2" + digits;
  }
  
  // If starts with 002, strip 00
  if (digits.startsWith("002")) {
    digits = digits.substring(2);
  }

  return digits;
}

/**
 * Builds a direct WhatsApp chat URL with an optional prefilled message.
 */
export function buildWhatsAppUrl(rawNumber: string, message?: string): string {
  const clean = formatWhatsAppNumber(rawNumber);
  if (!message) {
    return `https://wa.me/${clean}`;
  }
  return `https://wa.me/${clean}?text=${encodeURIComponent(message)}`;
}

/**
 * React Hook to load live WhatsApp configuration from public.system_settings (Configured by Admin App)
 */
export function useWhatsAppSettings() {
  const [businessNumber, setBusinessNumber] = useState<string>("+201000000000");
  const [expiryMinutes, setExpiryMinutes] = useState<number>(60);
  const [enabledForGuests, setEnabledForGuests] = useState<boolean>(true);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    async function fetchSettings() {
      try {
        const { data, error } = await supabase
          .from("system_settings")
          .select("value")
          .eq("key", "whatsapp_settings")
          .maybeSingle();

        if (!error && data?.value) {
          const val = data.value;
          if (val.business_number) {
            setBusinessNumber(val.business_number);
          }
          if (val.expiry_minutes !== undefined) {
            setExpiryMinutes(Number(val.expiry_minutes) || 60);
          }
          if (val.enabled_for_guests !== undefined) {
            setEnabledForGuests(val.enabled_for_guests !== false);
          }
        }
      } catch (err) {
        console.warn("Could not load WhatsApp settings from system_settings:", err);
      } finally {
        setLoading(false);
      }
    }

    fetchSettings();
  }, []);

  const cleanNumber = formatWhatsAppNumber(businessNumber);

  const getUrl = (message?: string) => buildWhatsAppUrl(businessNumber, message);

  return {
    businessNumber,
    cleanNumber,
    expiryMinutes,
    enabledForGuests,
    loading,
    getUrl,
  };
}
