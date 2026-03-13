import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

async function getAccessToken(): Promise<string> {
  const b64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_B64')!
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
  const tokenData = await tokenRes.json()
  return tokenData.access_token as string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const { city, title, body } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: donors } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('user_type', 'donor')
    .eq('city', city)
    .eq('is_available', true)
    .not('fcm_token', 'is', null)

  const tokens: string[] = (donors ?? [])
    .map((d: any) => d.fcm_token)
    .filter(Boolean)

  if (tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')!
  const accessToken = await getAccessToken()
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

  // V1 API sends one message per token
  const sends = tokens.map((token) =>
    fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: { type: 'blood_alert', city },
        },
      }),
    })
  )

  await Promise.all(sends)

  return new Response(JSON.stringify({ sent: tokens.length }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
