import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Fresh Home: Notification Outbox Relay (v5.0 — Production Hardened)
 * 
 * Changes from v4.0:
 * - Uses split secrets (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)
 * - Proper concurrency via SELECT ... FOR UPDATE SKIP LOCKED (no race conditions)
 * - Full error logging per task with structured output
 * - Atomic status update before FCM delivery (prevents duplicate sends)
 * - Platform-specific FCM payload (Android + iOS)
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // ── Correlation ID: unique per invocation — use this to trace logs ──
  const runId = crypto.randomUUID().slice(0, 8)
  const log = (level: 'INFO'|'WARN'|'ERROR', msg: string, data?: Record<string, unknown>) =>
    console.log(JSON.stringify({ runId, level, msg, ts: new Date().toISOString(), ...data }))

  log('INFO', '=== notify-outbox-relay v5.1 starting ===')

  try {
    // Use service role for full DB access
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ─────────────────────────────────────────────────────────────────
    // STEP 1: Load FCM credentials from split secrets
    // ─────────────────────────────────────────────────────────────────
    const projectId   = Deno.env.get('FCM_PROJECT_ID')
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
    const privateKey  = Deno.env.get('FCM_PRIVATE_KEY')

    if (!projectId || !clientEmail || !privateKey) {
      const missing = [
        !projectId   ? 'FCM_PROJECT_ID'   : null,
        !clientEmail ? 'FCM_CLIENT_EMAIL' : null,
        !privateKey  ? 'FCM_PRIVATE_KEY'  : null,
      ].filter(Boolean)
      log('ERROR', 'Missing FCM secrets', { missing })
      return new Response(
        JSON.stringify({ runId, error: `Missing secrets: ${missing.join(', ')}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    const serviceAccount = {
      project_id:   projectId,
      client_email: clientEmail,
      // Normalize escaped newlines that may come from environment variable storage
      private_key:  privateKey.replace(/\\n/g, '\n'),
    }

    log('INFO', 'FCM credentials loaded', { projectId })

    // ─────────────────────────────────────────────────────────────────
    // STEP 2: Fetch pending tasks with SKIP LOCKED (Race Condition Fix)
    // We use a raw SQL query to get proper locking semantics.
    // SKIP LOCKED ensures concurrent invocations don't process same rows.
    // ─────────────────────────────────────────────────────────────────
    const { data: tasks, error: fetchError } = await supabase.rpc(
      'fetch_and_lock_pending_notifications',
      { p_limit: 20 }
    )

    if (fetchError) {
      log('ERROR', 'fetch_and_lock_pending_notifications failed', { error: fetchError.message })
      throw fetchError
    }

    const taskCount = tasks?.length ?? 0
    log('INFO', 'Tasks locked', { taskCount })

    if (taskCount === 0) {
      return new Response(
        JSON.stringify({ runId, message: 'No pending tasks', processed: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 3: Get FCM access token once (reuse for all tasks in batch)
    // ─────────────────────────────────────────────────────────────────
    let fcmToken: string
    try {
      fcmToken = await getAccessToken(serviceAccount)
      log('INFO', 'FCM OAuth2 token obtained')
    } catch (tokenErr) {
      log('ERROR', 'Failed to get FCM OAuth2 token', { error: tokenErr.message })
      const ids = tasks.map((t: any) => t.outbox_id)
      await supabase.from('notifications_outbox')
        .update({ status: 'pending' })
        .in('id', ids)
      throw tokenErr
    }

    // ─────────────────────────────────────────────────────────────────
    // STEP 4: Process each task
    // ─────────────────────────────────────────────────────────────────
    const results: any[] = []

    for (const task of tasks) {
      log('INFO', 'Processing task', { outbox_id: task.outbox_id, recipient_id: task.recipient_id, platform: task.platform })

      try {
        const fcmSuccess = await sendFCMMessage(fcmToken, serviceAccount.project_id, task)

        if (fcmSuccess) {
          await supabase.from('notifications_outbox').update({
            status:       'sent',
            sent_at:      new Date().toISOString(),
            processed_at: new Date().toISOString(),
          }).eq('id', task.outbox_id)

          await supabase.from('notifications').insert({
            user_id:  task.recipient_id,
            title:    task.title,
            body:     task.body,
            metadata: { ...(task.data ?? {}), outbox_id: task.outbox_id },
          })

          log('INFO', 'Task delivered', { outbox_id: task.outbox_id })
          results.push({ id: task.outbox_id, status: 'success' })
        } else {
          throw new Error('FCM returned non-OK response')
        }

      } catch (taskErr) {
        const newRetry = (task.retry_count ?? 0) + 1
        const newStatus = newRetry >= 5 ? 'failed' : 'pending'

        log('WARN', 'Task failed', { outbox_id: task.outbox_id, attempt: newRetry, newStatus, error: taskErr.message })

        await supabase.from('notifications_outbox').update({
          status:        newStatus,
          retry_count:   newRetry,
          error_message: taskErr.message,
          processed_at:  new Date().toISOString(),
        }).eq('id', task.outbox_id)

        results.push({ id: task.outbox_id, status: 'error', attempt: newRetry, error: taskErr.message })
      }
    }

    const successCount = results.filter(r => r.status === 'success').length
    const errorCount   = results.filter(r => r.status === 'error').length
    log('INFO', 'Run complete', { processed: taskCount, success: successCount, errors: errorCount })

    return new Response(
      JSON.stringify({ runId, processed: taskCount, success: successCount, errors: errorCount, results }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (globalError) {
    log('ERROR', 'Global error', { error: globalError.message })
    return new Response(
      JSON.stringify({ runId, error: globalError.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

// ─────────────────────────────────────────────────────────────────
// FCM Message Sender (Platform-aware)
// ─────────────────────────────────────────────────────────────────
async function sendFCMMessage(accessToken: string, projectId: string, task: any): Promise<boolean> {
  const isAndroid = task.platform === 'android'
  const isIOS     = task.platform === 'ios'

  // Sanitize data payload: FCM requires all values to be strings
  const dataPayload = task.data
    ? Object.fromEntries(
        Object.entries(task.data).map(([k, v]) => [k, String(v)])
      )
    : {}

  const message: any = {
    token:        task.fcm_token,
    notification: {
      title: task.title,
      body:  task.body,
    },
    data: dataPayload,
  }

  // Android-specific config
  if (isAndroid || !isIOS) {
    message.android = {
      priority: 'high',
      notification: {
        sound:         'default',
        channel_id:    'fresh_home_notifications', // ← FIXED: matches Flutter channel name
        default_sound: true,
      },
    }
  }

  // iOS-specific config
  if (isIOS) {
    message.apns = {
      headers: { 'apns-priority': '10' },
      payload: {
        aps: {
          sound:             'default',
          badge:             1,
          'content-available': 1,
        },
      },
    }
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({ message }),
    }
  )

  if (!response.ok) {
    const body = await response.text()
    console.error(`FCM API [${response.status}]:`, body)
    return false
  }

  return true
}

// ─────────────────────────────────────────────────────────────────
// OAuth2 Token Generator (RS256 JWT for Google APIs)
// ─────────────────────────────────────────────────────────────────
async function getAccessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now     = Math.floor(Date.now() / 1000)
  const header  = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = b64url(JSON.stringify({
    iss:   sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  }))

  const signingInput = `${header}.${payload}`

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToBinary(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput)
  )

  const jwt = `${signingInput}.${b64url(new Uint8Array(signatureBuffer))}`

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method:  'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:    `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenResponse.json()

  if (!tokenData.access_token) {
    console.error('OAuth2 token error:', JSON.stringify(tokenData))
    throw new Error(`OAuth2 failed: ${tokenData.error_description ?? tokenData.error ?? 'unknown'}`)
  }

  return tokenData.access_token
}

function b64url(data: string | Uint8Array): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

function pemToBinary(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '')  // Remove ALL whitespace including \n \r \t
  return Uint8Array.from(atob(b64), c => c.charCodeAt(0))
}
