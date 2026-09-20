"use client";

/**
 * Fresh Home — Booking Funnel & Drop-off Analytics Helper
 * Strict Zero-PII, SSR-Safe, Non-Blocking, Idempotent Funnel Layer
 *
 * Spec Reference: docs_guest/booking_tracking_implementation_plan.md (DEC-07, DEC-08, DEC-09, DEC-11)
 */

import { supabase } from "@/lib/supabase";

export const FUNNEL_STORAGE_KEY = "fh_funnel_session_id";

export type FunnelStepNumber = 1 | 2 | 3 | 4 | 5;
export type FunnelEventName =
  | "service_selected"
  | "price_calculated"
  | "schedule_selected"
  | "address_confirmed"
  | "booking_created";

export interface RecordFunnelStepParams {
  step: FunnelStepNumber;
  event: FunnelEventName;
  serviceId?: string | null;
  serviceName?: string | null;
  bookingId?: string | null;
  metadata?: Record<string, any>;
}

// In-memory duplicate dispatch guard (prevents redundant RPCs during React re-renders)
const inMemoryDispatchedSteps = new Set<string>();

/**
 * UUID generator with fallback for older environments
 */
function generateUUID(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Retrieves the persistent session_id for the current booking journey from sessionStorage,
 * or initializes a fresh UUID if none exists.
 */
export function getOrCreateFunnelSessionId(): string {
  if (typeof window === "undefined") {
    return generateUUID();
  }

  try {
    let sessionId = sessionStorage.getItem(FUNNEL_STORAGE_KEY);
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (sessionId && uuidRegex.test(sessionId)) {
      return sessionId;
    }

    sessionId = generateUUID();
    sessionStorage.setItem(FUNNEL_STORAGE_KEY, sessionId);
    return sessionId;
  } catch {
    return generateUUID();
  }
}

/**
 * Clears the funnel session_id from sessionStorage upon successful booking completion,
 * ensuring that any subsequent booking journey initiates with a fresh session_id.
 */
export function clearFunnelSession(): void {
  if (typeof window === "undefined") return;
  try {
    sessionStorage.removeItem(FUNNEL_STORAGE_KEY);
    inMemoryDispatchedSteps.clear();
  } catch {
    // Silent fail for restrictive storage contexts
  }
}

/**
 * Sanitizes metadata to strictly exclude any PII (names, phones, emails, street details).
 */
function sanitizeMetadata(rawMetadata?: Record<string, any>): Record<string, any> {
  if (!rawMetadata || typeof rawMetadata !== "object") {
    return {};
  }

  const piiKeyPattern = /(phone|name|email|address_details|street|building|apartment|location_url|lat|lng)/i;
  const safeMetadata: Record<string, any> = {};

  for (const [key, value] of Object.entries(rawMetadata)) {
    if (piiKeyPattern.test(key)) {
      continue;
    }

    if (
      typeof value === "number" ||
      typeof value === "boolean" ||
      (typeof value === "string" && value.length <= 100)
    ) {
      safeMetadata[key] = value;
    }
  }

  return safeMetadata;
}

/**
 * Records a booking funnel progression step asynchronously in a strictly non-blocking manner.
 * Failures or network issues will never interrupt the booking user experience.
 */
export function recordFunnelStep(params: RecordFunnelStepParams): void {
  try {
    if (typeof window === "undefined") return;

    const sessionId = getOrCreateFunnelSessionId();
    const cacheKey = `${sessionId}_${params.step}`;

    // Front-end deduplication guard
    if (inMemoryDispatchedSteps.has(cacheKey)) {
      return;
    }
    inMemoryDispatchedSteps.add(cacheKey);

    const safeMeta = sanitizeMetadata(params.metadata);

    // Non-blocking fire-and-forget dispatch
    void (async () => {
      try {
        await supabase.rpc("record_booking_funnel_step", {
          p_session_id: sessionId,
          p_step_number: params.step,
          p_event_name: params.event,
          p_service_id: params.serviceId || null,
          p_service_name: params.serviceName || null,
          p_booking_id: params.step === 5 ? (params.bookingId || null) : null,
          p_metadata: safeMeta,
          p_tracking_version: "v1",
        });
      } catch (rpcErr) {
        // Analytics errors must never impact the customer journey
        console.warn("[Funnel Analytics Warning]: Failed to record step", params.step, rpcErr);
      }
    })();
  } catch (err) {
    console.warn("[Funnel Analytics Warning]: Unexpected error in recordFunnelStep", err);
  }
}
