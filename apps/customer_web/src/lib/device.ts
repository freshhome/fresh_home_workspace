/**
 * Fresh Home Platform - Client Signal & Device Helper
 * Generates and persists a unique client browser identifier (browser_id).
 * Used as a correlation signal assisting the backend in correlating guest sessions.
 */

export function getOrCreateBrowserId(): string {
  if (typeof window === "undefined") {
    return "";
  }
  const STORAGE_KEY = "fresh_home_browser_id";
  try {
    let browserId = localStorage.getItem(STORAGE_KEY);
    if (!browserId) {
      if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
        browserId = crypto.randomUUID();
      } else {
        browserId = "bid_" + Math.random().toString(36).substring(2, 15) + Date.now().toString(36);
      }
      localStorage.setItem(STORAGE_KEY, browserId);
    }
    return browserId;
  } catch (err) {
    console.warn("Could not access localStorage for browser_id:", err);
    return "";
  }
}
