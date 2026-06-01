import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Edge Function: admin-send-push
 * Triggered by: SQL Trigger on notification_campaigns table or pg_cron
 * Description: Enterprise batch processing for notification campaigns.
 */

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;

serve(async (req) => {
  try {
    const payloadBody = await req.json();
    const record = payloadBody?.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record provided" }), { status: 400 });
    }

    const { id, title, body, target_type, target_filter, deep_link, payload, image_url, priority } = record;
    
    console.log(`🚀 [Campaign] Starting campaign ${id} for target: ${target_type}`);
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Obtain OAuth2 Token once per campaign
    const accessToken = await getFcmAccessToken();
    if (!accessToken) {
      await markCampaignFailed(supabase, id, "Authentication failed. Missing FCM credentials.");
      return new Response(JSON.stringify({ error: "Auth failed" }), { status: 500 });
    }

    let successCount = 0;
    let failureCount = 0;

    // Build the base payload
    const fcmData: Record<string, string> = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      campaign_id: id,
    };
    
    if (deep_link) fcmData.deep_link = deep_link;
    if (typeof payload === 'object' && payload !== null) {
      Object.entries(payload).forEach(([key, value]) => {
        fcmData[key] = typeof value === 'object' ? JSON.stringify(value) : String(value);
      });
    }

    // 1. Topic Handling (No token fetching needed)
    if (target_type === 'topic') {
      const topicName = target_filter?.topic;
      if (!topicName) {
        await markCampaignFailed(supabase, id, "Topic target_type specified but no topic found in filter");
        return new Response(JSON.stringify({ error: "Invalid topic filter" }), { status: 400 });
      }

      console.log(`📡 [Campaign] Sending to topic: /topics/${topicName}`);
      
      const fcmMessage = buildFcmMessage(title, body, fcmData, image_url, priority, { topic: `/topics/${topicName}` });
      const success = await sendFcmRequest(fcmMessage, accessToken);
      
      success ? successCount++ : failureCount++;
      
    // 2. Token Handling (Customers, Technicians, All, Custom)
    } else {
      console.log(`🔍 [Campaign] Fetching tokens for ${target_type}`);
      
      // Use the Postgres RPC we built to efficiently gather tokens
      const { data: tokens, error: tokenError } = await supabase.rpc('get_campaign_fcm_tokens', {
        p_target_type: target_type,
        p_target_filter: target_filter || {}
      });

      if (tokenError) {
        console.error("❌ RPC Error:", tokenError);
        await markCampaignFailed(supabase, id, "Failed to query target tokens");
        return new Response(JSON.stringify({ error: "Token query failed" }), { status: 500 });
      }

      if (!tokens || tokens.length === 0) {
        console.log(`ℹ️ [Campaign] No tokens matched targeting criteria.`);
        await completeCampaign(supabase, id, 0, 0); // Sent, but to 0 people
        return new Response(JSON.stringify({ success: true, message: "No audience matched" }));
      }

      console.log(`✉️ [Campaign] Batching to ${tokens.length} devices...`);

      // Batch send in chunks to avoid memory/rate limits
      // Real enterprise solutions might push these to a queue, but Promise.all with chunks works well up to a few thousand.
      const CHUNK_SIZE = 100;
      for (let i = 0; i < tokens.length; i += CHUNK_SIZE) {
        const chunk = tokens.slice(i, i + CHUNK_SIZE);
        
        await Promise.all(
          chunk.map(async (t: any) => {
            try {
              const fcmMessage = buildFcmMessage(title, body, fcmData, image_url, priority, { token: t.fcm_token });
              const success = await sendFcmRequest(fcmMessage, accessToken);
              
              if (success) {
                successCount++;
              } else {
                failureCount++;
                // Handle stale tokens cleanup based on response in sendFcmRequest
                // Note: full implementation would check specific 404/410 errors and call standard deletion.
              }
            } catch (err) {
              failureCount++;
            }
          })
        );
      }
    }

    console.log(`✅ [Campaign] Completed. Success: ${successCount}, Failed: ${failureCount}`);
    await completeCampaign(supabase, id, successCount, failureCount);

    return new Response(JSON.stringify({ success: true, successCount, failureCount }));

  } catch (err) {
    console.error("🚨 [Campaign Global Error]:", err);
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), { status: 500 });
  }
});

// ======================== Helpers ========================

function buildFcmMessage(title: string, body: string, data: any, imageUrl: string | undefined, priority: string, targetStr: any) {
  const message: any = {
    notification: { title, body },
    data,
    android: {
      priority: priority === 'high' ? 'high' : 'normal',
      notification: { 
        sound: "default", 
        icon: "notification_icon",
        ...(imageUrl ? { image: imageUrl } : {})
      },
    },
    apns: {
      payload: {
        aps: { 
          sound: "default", 
          badge: 1,
          "mutable-content": imageUrl ? 1 : 0 
        },
      },
      ...(imageUrl ? { fcm_options: { image: imageUrl } } : {})
    },
    ...targetStr // {token: "..."} or {topic: "..."}
  };
  
  return { message };
}

async function sendFcmRequest(fcmMessage: any, accessToken: string): Promise<boolean> {
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
    const errObj = await response.json();
    console.error(`⚠️ [FCM Send Error]`, errObj);
    return false;
  }
  return true;
}

async function getFcmAccessToken(): Promise<string | null> {
  const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!serviceAccountStr) return null;

  try {
    const serviceAccount = JSON.parse(serviceAccountStr);
    const { client_email, private_key } = serviceAccount;
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
    return null;
  }
}

async function markCampaignFailed(supabase: any, id: string, reason: string) {
  await supabase.from('notification_campaigns').update({
    status: 'failed',
    payload: { failure_reason: reason } // store reason in payload safely
  }).eq('id', id);
}

async function completeCampaign(supabase: any, id: string, sCount: number, fCount: number) {
  await supabase.from('notification_campaigns').update({
    status: 'sent',
    sent_at: new Date().toISOString(),
    success_count: sCount,
    failure_count: fCount
  }).eq('id', id);
}
