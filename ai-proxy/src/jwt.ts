import { jwtVerify, createRemoteJWKSet, type JWTPayload } from 'jose'

export interface JWTEnv {
    SUPABASE_PROJECT_REF: string
    SUPABASE_JWT_SECRET?: string
}

// Module-scoped so the JWKS fetch is reused across requests within a Worker instance.
let cachedJWKS: ReturnType<typeof createRemoteJWKSet> | null = null
let cachedProjectRef: string | null = null

export class JWTError extends Error {
    code = 'invalid_jwt'
    status = 401
    constructor(msg: string) { super(msg) }
}

export async function verifySupabaseJWT(token: string, env: JWTEnv): Promise<{ userId: string; payload: JWTPayload }> {
    try {
        let payload: JWTPayload

        if (env.SUPABASE_JWT_SECRET) {
            const secret = new TextEncoder().encode(env.SUPABASE_JWT_SECRET)
            const verified = await jwtVerify(token, secret, {
                algorithms: ['HS256'],
                audience: 'authenticated',
            })
            payload = verified.payload
        } else {
            if (!cachedJWKS || cachedProjectRef !== env.SUPABASE_PROJECT_REF) {
                const url = new URL(`https://${env.SUPABASE_PROJECT_REF}.supabase.co/auth/v1/.well-known/jwks.json`)
                cachedJWKS = createRemoteJWKSet(url)
                cachedProjectRef = env.SUPABASE_PROJECT_REF
            }
            const verified = await jwtVerify(token, cachedJWKS, {
                audience: 'authenticated',
            })
            payload = verified.payload
        }

        const sub = payload.sub
        if (typeof sub !== 'string' || sub.length === 0) {
            throw new JWTError('Token has no subject.')
        }
        return { userId: sub, payload }
    } catch (err) {
        if (err instanceof JWTError) throw err
        const msg = err instanceof Error ? err.message : 'unknown'
        throw new JWTError(`JWT verification failed: ${msg}`)
    }
}
