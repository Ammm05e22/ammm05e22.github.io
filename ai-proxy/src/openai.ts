import { SYSTEM_PROMPT_ANALYZE, SYSTEM_PROMPT_WEEKLY } from './prompts'

export interface OpenAIEnv {
    OPENAI_API_KEY: string
    OPENAI_MODEL?: string
}

const DEFAULT_MODEL = 'gpt-4o-mini'
const TEMPERATURE = 0.2

export class OpenAIError extends Error {
    code = 'openai_error'
    status = 502
    constructor(msg: string) { super(msg) }
}

export class BadResponseError extends Error {
    code = 'bad_response'
    status = 502
    constructor(msg: string) { super(msg) }
}

interface ChatMessage { role: 'system' | 'user' | 'assistant'; content: string }

async function callOpenAI(env: OpenAIEnv, systemPrompt: string, userPayload: unknown, retry = false): Promise<{ parsed: any; model: string }> {
    const model = env.OPENAI_MODEL ?? DEFAULT_MODEL
    const messages: ChatMessage[] = [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: JSON.stringify(userPayload) },
    ]
    if (retry) {
        messages.push({ role: 'user', content: 'Your previous reply was not valid JSON. Reply with only the JSON object, no markdown, no prose.' })
    }

    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${env.OPENAI_API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            model,
            messages,
            response_format: { type: 'json_object' },
            temperature: TEMPERATURE,
        }),
    })

    if (!resp.ok) {
        const text = await resp.text()
        throw new OpenAIError(`OpenAI returned ${resp.status}: ${text.slice(0, 300)}`)
    }

    const data: any = await resp.json()
    const content: string = data?.choices?.[0]?.message?.content ?? ''
    const parsed = tryParseJSON(content)

    if (parsed && typeof parsed === 'object') {
        return { parsed, model: data?.model ?? model }
    }

    if (!retry) {
        return callOpenAI(env, systemPrompt, userPayload, true)
    }
    throw new BadResponseError('OpenAI did not return valid JSON after retry.')
}

function tryParseJSON(text: string): any | null {
    if (!text) return null

    try { return JSON.parse(text) } catch {}

    const stripped = text
        .replace(/^\s*```(?:json)?\s*/i, '')
        .replace(/\s*```\s*$/i, '')
        .trim()
    try { return JSON.parse(stripped) } catch {}

    const first = text.indexOf('{')
    const last = text.lastIndexOf('}')
    if (first >= 0 && last > first) {
        try { return JSON.parse(text.slice(first, last + 1)) } catch {}
    }

    return null
}

// ---------- Validation / repair ----------

function clampDelta(v: unknown): number {
    const n = Number(v)
    if (!Number.isFinite(n)) return 0
    return Math.max(-10, Math.min(10, n))
}

function strArray(v: unknown): string[] {
    if (!Array.isArray(v)) return []
    return v.map(x => (x == null ? '' : String(x))).filter(s => s.length > 0)
}

function asStringOrEmpty(v: unknown): string {
    return v == null ? '' : String(v)
}

function asStringOrNull(v: unknown): string | null {
    if (v == null) return null
    const s = String(v).trim()
    return s.length > 0 ? s : null
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function uuidArray(v: unknown): string[] {
    if (!Array.isArray(v)) return []
    return v.map(x => String(x ?? '')).filter(s => UUID_RE.test(s))
}

const ALLOWED_STATUSES = new Set(['Buy', 'Hold', 'Reduce', 'Freeze', 'Exit', 'Watchlist'])

function normalizeStatus(v: unknown): string | null {
    if (v == null) return null
    const s = String(v).trim()
    if (!s) return null
    const cap = s.charAt(0).toUpperCase() + s.slice(1).toLowerCase()
    return ALLOWED_STATUSES.has(cap) ? cap : null
}

function validateAnalysis(raw: any) {
    const deltas = raw?.deltas ?? {}
    return {
        headline: asStringOrNull(raw?.headline),
        facts: strArray(raw?.facts),
        emotions: strArray(raw?.emotions),
        assumptions: strArray(raw?.assumptions),
        red_flags: strArray(raw?.red_flags),
        green_flags: strArray(raw?.green_flags),
        recommendation: asStringOrEmpty(raw?.recommendation),
        patterns_detected: strArray(raw?.patterns_detected),
        deltas: {
            emotionalSafety: clampDelta(deltas?.emotionalSafety),
            consistency: clampDelta(deltas?.consistency),
            reciprocity: clampDelta(deltas?.reciprocity),
            growthAlignment: clampDelta(deltas?.growthAlignment),
            integrity: clampDelta(deltas?.integrity),
            attraction: clampDelta(deltas?.attraction),
        },
        delta_rationale: asStringOrEmpty(raw?.delta_rationale),
    }
}

function validateSummary(raw: any) {
    return {
        headline: asStringOrEmpty(raw?.headline),
        themes: strArray(raw?.themes),
        evidence_entry_ids: uuidArray(raw?.evidence_entry_ids),
        suggested_status: normalizeStatus(raw?.suggested_status),
        next_check_in: asStringOrNull(raw?.next_check_in),
    }
}

// ---------- Public entry points ----------

export async function analyzeEntry(body: unknown, env: OpenAIEnv) {
    const { parsed, model } = await callOpenAI(env, SYSTEM_PROMPT_ANALYZE, body)
    return { model, analysis: validateAnalysis(parsed) }
}

export async function weeklySummary(body: unknown, env: OpenAIEnv) {
    const { parsed, model } = await callOpenAI(env, SYSTEM_PROMPT_WEEKLY, body)
    return { model, summary: validateSummary(parsed) }
}
