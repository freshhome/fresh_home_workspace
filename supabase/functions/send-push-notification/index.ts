import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Edge Function: send-push-notification
 * Triggered by: SQL Trigger on notifications table
 */

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const record = payload?.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record provided" }), { status: 400, headers: corsHeaders });
    }

    const { user_id, title, body, metadata } = record;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch tokens for the specific user
    const { data: tokens, error: tokenError } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", user_id);

    if (tokenError) throw tokenError;

    if (!tokens || tokens.length === 0) {
      console.log(`ℹ️ [Push] No FCM tokens found for user: ${user_id}`);
      return new Response(JSON.stringify({ success: true, message: "No tokens registered" }), { headers: corsHeaders });
    }

    // 2. Obtain OAuth2 Access Token for FCM v1
    const accessToken = await getFcmAccessToken();
    if (!accessToken) {
      console.error("❌ [Push] Failed to obtain FCM Access Token. Check FCM_SERVICE_ACCOUNT secret.");
      return new Response(JSON.stringify({ error: "Authentication failed" }), { status: 500, headers: corsHeaders });
    }

    // 3. Send to all devices
    const results = await Promise.all(
      tokens.map(async (t) => {
        try {
          const fcmData: Record<string, string> = {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          };

          if (typeof metadata === 'object' && metadata !== null) {
            Object.entries(metadata).forEach(([key, value]) => {
              fcmData[key] = typeof value === 'object' ? JSON.stringify(value) : String(value);
            });
          }

          const fcmMessage = {
            message: {
              token: t.fcm_token,
              notification: { title, body },
              data: fcmData,
              android: {
                priority: "high",
                notification: { sound: "default", icon: "notification_icon" },
              },
              apns: {
                headers: {
                  "apns-priority": "10",
                },
                payload: {
                  aps: { sound: "default", badge: 1 },
                },
              },
            },
          };

          const response = await fetch(
            `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify(fcmMessage),
            }
          );

          if (!response.ok) {
            const error = await response.json();
            console.error(`⚠️ [Push] FCM send error for token ${t.fcm_token.substring(0, 8)}:`, error);
            
            // Clean up invalid tokens
            if (response.status === 404 || response.status === 410) {
              await supabase.from("user_fcm_tokens").delete().eq("fcm_token", t.fcm_token);
            }
          }
          return response.ok;
        } catch (e) {
          console.error("❌ [Push] Unexpected error in send loop:", e);
          return false;
        }
      })
    );

    return new Response(JSON.stringify({ success: true, results }), { headers: corsHeaders });
  } catch (err) {
    console.error("🚨 [Push] Global error:", err);
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), { status: 500, headers: corsHeaders });
  }
});

/**
 * Generates an OAuth2 Access Token for FCM v1 using a Google Service Account.
 */
async function getFcmAccessToken(): Promise<string | null> {
  const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!serviceAccountStr) return null;

  try {
    const serviceAccount = JSON.parse(serviceAccountStr);
    const { client_email, private_key } = serviceAccount;

    // Use JWT from google-auth-library
    const { JWT } = await import("https://esm.sh/google-auth-library@9.6.3");
    
    const jwtClient = new JWT(
      client_email,
      undefined,
      private_key,
      ["https://www.googleapis.com/auth/cloud-platform"]
    );

    const tokens = await jwtClient.authorize();
    return tokens.access_token || null;
  } catch (e) {
    console.error("❌ [Auth] Error generating access token:", e);
    return null;
  }
}
