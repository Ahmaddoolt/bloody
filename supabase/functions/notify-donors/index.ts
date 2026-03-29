import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

async function getAccessToken(): Promise<string> {
  const b64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_B64')
  if (!b64) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_B64 not set')
  }

  const json = JSON.parse(atob(b64))

  const privateKeyPem = json.private_key as string
  const pemContents = privateKeyPem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const now = getNumericDate(0)
  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: json.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: getNumericDate(3600),
      iat: now,
    },
    cryptoKey,
  )

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })

  if (!tokenRes.ok) {
    const error = await tokenRes.text()
    throw new Error(`Failed to get access token: ${error}`)
  }

  const tokenData = await tokenRes.json()
  return tokenData.access_token as string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function normalizeTokens(rawTokens: unknown): string[] {
  if (!Array.isArray(rawTokens)) {
    return []
  }

  return [...new Set(
    rawTokens
      .filter((token): token is string => typeof token === 'string')
      .map((token) => token.trim())
      .filter((token) => token.length > 0),
  )]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const {
      city,
      title,
      body,
      donorIds,
      tokens: providedTokens,
      notification_user_id,
      notification_title_key,
      notification_body_key,
      notification_type,
    } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // ── Step 1: Insert in-app notification FIRST (service-role bypasses RLS) ──
    if (notification_user_id && notification_title_key && notification_body_key) {
      const { error: notifError } = await supabase.from('notifications').insert({
        user_id: notification_user_id,
        title: notification_title_key,
        body: notification_body_key,
        type: notification_type ?? 'priority',
        is_read: false,
      })
      if (notifError) {
        console.error('[notify-donors] Failed to insert notification:', notifError)
      } else {
        console.log(`[notify-donors] Inserted notification for user ${notification_user_id}`)
      }
    }

    // ── Step 2: Resolve FCM tokens ──
    let tokens: string[] = []
    let lookupMode = 'none'
    let requestedDonorIds = 0

    if (providedTokens && Array.isArray(providedTokens) && providedTokens.length > 0) {
      lookupMode = 'tokens'
      tokens = normalizeTokens(providedTokens)
      console.log(`[notify-donors] Using ${tokens.length} provided tokens`)
    } else if (Array.isArray(donorIds) && donorIds.length > 0) {
      lookupMode = 'donorIds'
      const normalizedDonorIds = [...new Set(
        donorIds
          .filter((id): id is string => typeof id === 'string')
          .map((id) => id.trim())
          .filter((id) => id.length > 0),
      )]
      requestedDonorIds = normalizedDonorIds.length

      const { data: donors, error: dbError } = await supabase
        .from('profiles')
        .select('fcm_token')
        .in('id', normalizedDonorIds)
        .not('fcm_token', 'is', null)

      if (dbError) {
        console.error('[notify-donors] Database error (donorIds):', dbError)
      } else {
        tokens = normalizeTokens((donors ?? []).map((d: any) => d.fcm_token))
        console.log(`[notify-donors] Found ${tokens.length} tokens for ${normalizedDonorIds.length} donor ids`)
      }
    } else if (city) {
      lookupMode = 'city'
      const { data: donors, error: dbError } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('user_type', 'donor')
        .ilike('city', city)
        .eq('is_available', true)
        .not('fcm_token', 'is', null)

      if (dbError) {
        console.error('[notify-donors] Database error (city):', dbError)
      } else {
        tokens = normalizeTokens((donors ?? []).map((d: any) => d.fcm_token))
        console.log(`[notify-donors] Found ${tokens.length} donors in city: ${city}`)
      }
    }

    // ── Step 3: Send FCM push notifications ──
    if (tokens.length === 0) {
      console.log('[notify-donors] No tokens to send to')
      return new Response(JSON.stringify({
        sent: 0,
        message: 'No tokens found',
        lookupMode,
        requestedDonorIds,
        resolvedTokens: 0,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    if (!projectId) {
      console.error('[notify-donors] FIREBASE_PROJECT_ID not set')
      return new Response(JSON.stringify({ error: 'FIREBASE_PROJECT_ID not set', sent: 0 }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const accessToken = await getAccessToken()
    console.log('[notify-donors] Got access token')

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    let successCount = 0
    let failCount = 0

    for (const token of tokens) {
      try {
        const response = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data: { type: 'blood_alert', city: city || '' },
            },
          }),
        })

        if (response.ok) {
          successCount++
          console.log(`[notify-donors] Sent to token ending in ...${token.slice(-8)}`)
        } else {
          const error = await response.text()
          failCount++
          console.error(`[notify-donors] Failed to send to token: ${error}`)
        }
      } catch (e) {
        failCount++
        console.error(`[notify-donors] Error sending to token:`, e)
      }
    }

    console.log(`[notify-donors] Complete: ${successCount} success, ${failCount} failed`)

    return new Response(JSON.stringify({
      sent: successCount,
      failed: failCount,
      total: tokens.length,
      lookupMode,
      requestedDonorIds,
      resolvedTokens: tokens.length,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('[notify-donors] Error:', error)
    return new Response(JSON.stringify({
      error: error.message,
      sent: 0
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
