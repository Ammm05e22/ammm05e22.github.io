import { verifySupabaseJWT, JWTError } from './jwt'
import { analyzeEntry, weeklySummary, OpenAIError, BadResponseError } from './openai'

export interface Env {
    OPENAI_API_KEY: string
    OPENAI_MODEL?: string
    SUPABASE_PROJECT_REF: string
    SUPABASE_JWT_SECRET?: string
    ALLOWED_ORIGINS?: string
}

export default {
    async fetch(request: Request, env: Env): Promise<Response> {
        const url = new URL(request.url)

        if (request.method === 'OPTIONS') {
            return new Response(null, { status: 204, headers: corsHeaders(request, env) })
        }

        if (url.pathname === '/' || url.pathname === '/health') {
            return json({ ok: true }, 200, request, env)
        }

        try {
            if (request.method !== 'POST') {
                return errorJson(405, 'method_not_allowed', 'POST only.', request, env)
            }

            const auth = request.headers.get('Authorization') ?? ''
            if (!auth.startsWith('Bearer ')) {
                return errorJson(401, 'invalid_jwt', 'Missing Bearer token.', request, env)
            }
            const token = auth.slice(7).trim()
            const { userId } = await verifySupabaseJWT(token, env)

            const body = await request.json().catch(() => null)
            if (!body || typeof body !== 'object') {
                return errorJson(400, 'bad_request', 'Body must be JSON.', request, env)
            }

            if (url.pathname === '/analyze-entry') {
                const result = await analyzeEntry(body, env)
                return json(result, 200, request, env)
            }

            if (url.pathname === '/weekly-summary') {
                const result = await weeklySummary(body, env)
                return json(result, 200, request, env)
            }

            // Touch userId so it's not flagged unused; useful for future per-user rate-limiting.
            void userId
            return errorJson(404, 'not_found', `Unknown route: ${url.pathname}`, request, env)
        } catch (err) {
            if (err instanceof JWTError) {
                return errorJson(err.status, err.code, err.message, request, env)
            }
            if (err instanceof OpenAIError || err instanceof BadResponseError) {
                return errorJson(err.status, err.code, err.message, request, env)
            }
            const msg = err instanceof Error ? err.message : 'Unexpected error.'
            console.error('unhandled', msg)
            return errorJson(500, 'internal_error', msg, request, env)
        }
    },
} satisfies ExportedHandler<Env>

function corsHeaders(request: Request, env: Env): Record<string, string> {
    const origin = request.headers.get('Origin') ?? ''
    const allowed = (env.ALLOWED_ORIGINS ?? '*').split(',').map(s => s.trim()).filter(Boolean)
    const allowOrigin =
        allowed.includes('*') ? '*' :
        allowed.includes(origin) ? origin :
        ''
    const headers: Record<string, string> = {
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
        'Access-Control-Max-Age': '86400',
        'Vary': 'Origin',
    }
    if (allowOrigin) headers['Access-Control-Allow-Origin'] = allowOrigin
    return headers
}

function json(payload: unknown, status: number, request: Request, env: Env): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { 'Content-Type': 'application/json', ...corsHeaders(request, env) },
    })
}

function errorJson(status: number, code: string, message: string, request: Request, env: Env): Response {
    return json({ error: { code, message } }, status, request, env)
}
