import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    const { token, title, body } = await req.json();
    console.log("🔍 [test-send-push] Received request:", { title, body, tokenSnippet: token?.substring(0, 10) });

    if (!token || !title) {
      console.error("❌ [test-send-push] Missing token or title");
      return new Response(JSON.stringify({ error: "Missing token or title" }), { 
        status: 400, headers: corsHeaders() 
      });
    }

    const accessToken = await getFcmAccessToken();
    if (!accessToken) {
      console.error("❌ [test-send-push] Auth failed. Missing FCM Credentials.");
      return new Response(JSON.stringify({ error: "Authentication failed. Missing FCM credentials." }), { 
        status: 500, headers: corsHeaders() 
      });
    }
    console.log("✅ [test-send-push] Successfully retrieved FCM Access Token");

    const fcmMessage = {
      message: {
        notification: { title, body: body || "" },
        token: token,
      }
    };

    console.log(`🚀 [test-send-push] Sending to FCM Project: ${FCM_PROJECT_ID}...`);
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

    const result = await response.json();
    console.log(`📠 [test-send-push] FCM Response Status: ${response.status}`);
    console.log(`📠 [test-send-push] FCM Response Body:`, result);

    return new Response(JSON.stringify(result), { headers: corsHeaders() });
  } catch (err) {
    console.error("🔥 [test-send-push] Catch Error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { 
      status: 500, headers: corsHeaders() 
    });
  }
});

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json'
  };
}

async function getFcmAccessToken(): Promise<string | null> {
  const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!serviceAccountStr) return null;

  try {
    const serviceAccount = JSON.parse(serviceAccountStr);
    const { JWT } = await import("https://esm.sh/google-auth-library@9.6.3");
    
    const jwtClient = new JWT(
      serviceAccount.client_email,
      undefined,
      serviceAccount.private_key,
      ["https://www.googleapis.com/auth/cloud-platform"]
    );

    const tokens = await jwtClient.authorize();
    return tokens.access_token || null;
  } catch (e) {
    return null;
  }
}
