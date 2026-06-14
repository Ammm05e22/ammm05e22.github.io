// Fill these in for your environment.
// The Supabase anon key is public by design — RLS protects data.
// AI_SERVER_BASE_URL points at your own server that proxies to OpenAI.

export const SUPABASE_URL = 'https://YOUR_PROJECT_REF.supabase.co';
export const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

// e.g. 'https://your-ai-proxy.example.com'
// The server must expose POST /analyze-entry and POST /weekly-summary.
// It receives the Supabase JWT as a Bearer token and forwards to OpenAI.
export const AI_SERVER_BASE_URL = '';
