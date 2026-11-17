import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type ChatMessage = {
  role?: string
  text?: string
}

const allowedTerms = [
  'blood',
  'donat',
  'donor',
  'transfusion',
  'hemoglobin',
  'haemoglobin',
  'cbc',
  'anemia',
  'anaemia',
  'iron',
  'ferritin',
  'platelet',
  'plasma',
  'hiv',
  'hepatitis',
  'syphilis',
  'rh',
  'abo',
  'مرض',
  'صحة',
  'دم',
  'تبرع',
  'متبرع',
  'نقل الدم',
  'هيموغلوبين',
  'فقر الدم',
  'حديد',
  'صفائح',
  'بلازما',
  'التهاب الكبد',
  'زهري',
]

function isAllowedTopic(message: string): boolean {
  const normalized = message.toLowerCase()
  return allowedTerms.some((term) => normalized.includes(term.toLowerCase()))
}

function refusal(locale: string): string {
  if (locale === 'ar') {
    return 'أستطيع المساعدة فقط في أسئلة الصحة العامة والتبرع بالدم وسلامة الدم. اسألني عن الأهلية، التحاليل، فقر الدم، الحديد، أو الاستعداد للتبرع.'
  }
  return 'I can only help with general health, blood donation, and blood safety questions. Ask me about eligibility, tests, anemia, iron, or preparing to donate.'
}

function buildPrompt(message: string, locale: string, history: ChatMessage[]): string {
  const languageInstruction = locale === 'ar'
    ? 'Answer in Arabic unless the user clearly asks otherwise.'
    : 'Answer in English unless the user clearly asks otherwise.'

  const recentHistory = history
    .slice(-6)
    .map((item) => `${item.role === 'assistant' ? 'Assistant' : 'User'}: ${item.text ?? ''}`)
    .join('\n')

  return `
You are Bloody's blood-health assistant.
${languageInstruction}

Strict scope:
- Answer only general education about blood donation, donor eligibility, blood safety, blood testing, blood types, transfusion basics, anemia, iron, hydration, recovery, and when to seek care.
- Do not diagnose, prescribe, replace a clinician, or provide emergency triage beyond telling the user to seek urgent local medical care.
- If the user asks about unrelated topics, refuse briefly and redirect to blood/health topics.
- Keep answers concise, calm, and practical.
- Include a short medical disclaimer when symptoms, tests, or eligibility are discussed.

Recent conversation:
${recentHistory}

User question:
${message}
`.trim()
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, locale = 'ar', history = [] } = await req.json()
    const text = typeof message === 'string' ? message.trim() : ''

    if (text.length === 0) {
      return new Response(JSON.stringify({
        allowed: false,
        answer: refusal(locale),
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!isAllowedTopic(text)) {
      return new Response(JSON.stringify({
        allowed: false,
        answer: refusal(locale),
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not set')
    }

    const prompt = buildPrompt(text, locale, Array.isArray(history) ? history : [])
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [{ text: prompt }],
            },
          ],
          generationConfig: {
            temperature: 0.35,
            topP: 0.9,
            maxOutputTokens: 700,
          },
        }),
      },
    )

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Gemini request failed: ${error}`)
    }

    const data = await response.json()
    const answer = data?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text ?? '')
      .join('')
      .trim()

    return new Response(JSON.stringify({
      allowed: true,
      answer: answer && isAllowedTopic(`${text} ${answer}`)
        ? answer
        : refusal(locale),
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({
      allowed: false,
      answer: error instanceof Error ? error.message : 'Unexpected error',
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
