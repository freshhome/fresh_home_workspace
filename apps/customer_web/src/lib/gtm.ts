"use client";

/**
 * Fresh Home — Google Tag Manager & Data Layer Singleton Helper
 * Strict Zero-PII, SSR-Safe, Non-Blocking Side-Effect Analytics Layer
 */

declare global {
  interface Window {
    dataLayer?: Object[];
  }
}

// -----------------------------------------------------------------------------
// Funnel Step Decoupling Map
// -----------------------------------------------------------------------------
export const CHECKOUT_STEP_MAP = {
  price_calculation: 1,
  schedule_selection: 2,
  address_entry: 3,
  order_review: 4,
} as const;

export type CheckoutStepName = keyof typeof CHECKOUT_STEP_MAP;

// -----------------------------------------------------------------------------
// Core Safe Push Helper
// -----------------------------------------------------------------------------
function pushToDataLayer(payload: Record<string, any>): void {
  try {
    if (typeof window === "undefined") return;
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(payload);
  } catch (err) {
    // Analytics failures must never break the application
    console.warn("[Analytics Warning]: Failed to push to dataLayer", err);
  }
}

// -----------------------------------------------------------------------------
// 1. view_service_list (GA4: view_item_list)
// -----------------------------------------------------------------------------
export interface ViewServiceListParams {
  item_list_id: string;
  item_list_name: string;
  items_count?: number;
}

export function trackViewServiceList(params: ViewServiceListParams): void {
  pushToDataLayer({
    event: "view_service_list",
    event_id: `evt_list_${params.item_list_id}_${Date.now()}`,
    ecommerce: {
      item_list_id: params.item_list_id,
      item_list_name: params.item_list_name,
      items_count: params.items_count ?? 0,
    },
  });
}

// -----------------------------------------------------------------------------
// 2. view_item (GA4: view_item | Meta: ViewContent)
// -----------------------------------------------------------------------------
export interface ViewItemParams {
  service_id: string;
  service_name: string;
  category_id?: string | null;
  category_name?: string | null;
  price: number;
  currency?: string;
  price_type?: string;
}

export function trackViewItem(params: ViewItemParams): void {
  const currency = params.currency || "EGP";
  pushToDataLayer({
    event: "view_item",
    event_id: `evt_view_${params.service_id}_${Date.now()}`,
    ecommerce: {
      currency,
      value: params.price,
      items: [
        {
          item_id: params.service_id,
          item_name: params.service_name,
          item_category: params.category_name || "خدمات فريش هوم",
          item_category_id: params.category_id || undefined,
          price: params.price,
          quantity: 1,
        },
      ],
    },
    service_meta: {
      price_type: params.price_type || "fixed",
    },
  });
}

// -----------------------------------------------------------------------------
// 3. calculate_price (GA4: calculate_price [Custom])
// -----------------------------------------------------------------------------
export interface CalculatePriceInputsSummary {
  area_sqm?: number;
  rooms_count?: number;
  bathrooms_count?: number;
  ac_units_count?: number;
  addons_count?: number;
}

export interface CalculatePriceParams {
  service_id: string;
  service_name: string;
  calculated_total: number;
  base_price: number;
  extra_fees?: number;
  discount?: number;
  currency?: string;
  inputs_summary?: CalculatePriceInputsSummary;
}

export function trackCalculatePrice(params: CalculatePriceParams): void {
  pushToDataLayer({
    event: "calculate_price",
    event_id: `evt_calc_${params.service_id}_${Date.now()}`,
    service_id: params.service_id,
    service_name: params.service_name,
    calculated_total: params.calculated_total,
    base_price: params.base_price,
    extra_fees: params.extra_fees || 0,
    discount: params.discount || 0,
    currency: params.currency || "EGP",
    pricing_inputs_summary: params.inputs_summary || {},
  });
}

// -----------------------------------------------------------------------------
// 4. begin_checkout (GA4: begin_checkout | Meta: InitiateCheckout)
// -----------------------------------------------------------------------------
export interface BeginCheckoutParams {
  service_id: string;
  service_name: string;
  category_id?: string | null;
  value: number;
  currency?: string;
}

export function trackBeginCheckout(params: BeginCheckoutParams): void {
  const currency = params.currency || "EGP";
  pushToDataLayer({
    event: "begin_checkout",
    event_id: `evt_chk_${params.service_id}_${Date.now()}`,
    ecommerce: {
      currency,
      value: params.value,
      items: [
        {
          item_id: params.service_id,
          item_name: params.service_name,
          price: params.value,
          quantity: 1,
        },
      ],
    },
  });
}

// -----------------------------------------------------------------------------
// 5. checkout_progress (GA4: checkout_progress [Custom Funnel])
// -----------------------------------------------------------------------------
export interface CheckoutProgressParams {
  step_name: CheckoutStepName;
  service_id: string;
  step_data?: {
    scheduled_date?: string;
    governorate?: string;
    city?: string;
  };
}

export function trackCheckoutProgress(params: CheckoutProgressParams): void {
  const checkoutStep = CHECKOUT_STEP_MAP[params.step_name];
  pushToDataLayer({
    event: "checkout_progress",
    event_id: `evt_step_${checkoutStep}_${Date.now()}`,
    checkout_step: checkoutStep,
    step_name: params.step_name,
    service_id: params.service_id,
    step_data: params.step_data || {},
  });
}

// -----------------------------------------------------------------------------
// 6. purchase (Primary Booking Conversion | GA4: purchase | Meta: Purchase)
// -----------------------------------------------------------------------------
export interface PurchaseParams {
  booking_id: string;          // UUID -> Meta event_id & Deduplication Key
  readable_id: string;         // e.g. "FH-100293" -> GA4 transaction_id
  value: number;               // Authoritative total price from backend
  currency?: string;           // Default: "EGP"
  service_id: string;
  service_name: string;
  category_id?: string | null;
  category_name?: string | null;
  user_type: "registered" | "guest";
  is_whatsapp_confirmed: boolean;
  scheduled_date?: string;
  scheduled_slot?: string;
  governorate?: string;
  city?: string;
  district?: string;
  payment_type?: string;       // Default: "cash"
}

export function trackPurchase(params: PurchaseParams): boolean {
  if (typeof window === "undefined") return false;

  const storageKey = `fh_purchase_tracked_${params.booking_id}`;
  try {
    if (sessionStorage.getItem(storageKey)) {
      // Prevent duplicate purchase dispatch within the same browser session
      return false;
    }
    sessionStorage.setItem(storageKey, "true");
  } catch {
    // sessionStorage quota or security error fallback
  }

  const currency = params.currency || "EGP";
  pushToDataLayer({
    event: "purchase",
    event_id: params.booking_id, // Authoritative Meta event_id for CAPI matching
    user_type: params.user_type,
    is_whatsapp_confirmed: params.is_whatsapp_confirmed,
    ecommerce: {
      transaction_id: params.readable_id || params.booking_id, // GA4 transaction_id
      value: params.value,
      currency,
      tax: 0,
      shipping: 0,
      items: [
        {
          item_id: params.service_id,
          item_name: params.service_name,
          item_category: params.category_name || "خدمات فريش هوم",
          item_category_id: params.category_id || undefined,
          price: params.value,
          quantity: 1,
        },
      ],
    },
    booking_details: {
      service_id: params.service_id,
      service_name: params.service_name,
      category_id: params.category_id || undefined,
      category_name: params.category_name || undefined,
      scheduled_date: params.scheduled_date || undefined,
      scheduled_slot: params.scheduled_slot || undefined,
      governorate: params.governorate || undefined,
      city: params.city || undefined,
      district: params.district || undefined,
      payment_type: params.payment_type || "cash",
    },
  });

  return true;
}

// -----------------------------------------------------------------------------
// 7. contact_whatsapp (GA4: generate_lead | Meta: Lead)
// -----------------------------------------------------------------------------
export type WhatsAppPlacement =
  | "hero"
  | "bottom_banner"
  | "service_details_inquiry"
  | "service_details_paused"
  | "footer"
  | "orders_pending_verification"
  | "general";

export interface ContactWhatsAppParams {
  placement: WhatsAppPlacement;
  service_context?: string;
  page_location?: string;
}

export function trackContactWhatsApp(params: ContactWhatsAppParams): void {
  const pageLocation =
    params.page_location || (typeof window !== "undefined" ? window.location.pathname : "");
  pushToDataLayer({
    event: "contact_whatsapp",
    event_id: `evt_wa_${Date.now()}`,
    lead_data: {
      placement: params.placement,
      service_context: params.service_context || undefined,
      page_location: pageLocation,
    },
  });
}

// -----------------------------------------------------------------------------
// 8. whatsapp_confirmed (GA4: whatsapp_confirmed [Custom Quality Gate])
// -----------------------------------------------------------------------------
export interface WhatsAppConfirmedParams {
  booking_id: string;
  status?: string;
}

export function trackWhatsAppConfirmed(params: WhatsAppConfirmedParams): void {
  pushToDataLayer({
    event: "whatsapp_confirmed",
    event_id: `evt_waconf_${params.booking_id}`,
    booking_id: params.booking_id,
    confirmation_status: params.status || "confirmed",
  });
}

// -----------------------------------------------------------------------------
// 9. sign_up (GA4: sign_up | Meta: CompleteRegistration)
// -----------------------------------------------------------------------------
export interface SignUpParams {
  method: "email_password" | "google_oauth";
}

export function trackSignUp(params: SignUpParams): void {
  pushToDataLayer({
    event: "sign_up",
    event_id: `evt_signup_${Date.now()}`,
    method: params.method,
  });
}

// -----------------------------------------------------------------------------
// 10. login (GA4: login)
// -----------------------------------------------------------------------------
export interface LoginParams {
  method: "password" | "google";
}

export function trackLogin(params: LoginParams): void {
  pushToDataLayer({
    event: "login",
    event_id: `evt_login_${Date.now()}`,
    method: params.method,
  });
}
