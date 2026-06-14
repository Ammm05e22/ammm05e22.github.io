import { supabase } from '../supabaseClient.js';
import { AI_SERVER_BASE_URL } from '../config.js';

async function authHeader() {
    const { data } = await supabase.auth.getSession();
    const token = data?.session?.access_token;
    if (!token) throw new Error('Not signed in');
    return { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };
}

function resolveBase(overrideUrl) {
    const base = (overrideUrl || AI_SERVER_BASE_URL || '').replace(/\/$/, '');
    if (!base) throw new Error('AI server URL is not configured. Set AI_SERVER_BASE_URL in config.js or override in Settings.');
    return base;
}

export async function analyzeEntry({
    entry_id, person, raw_text, occurred_at, recent_entries = [], boundaries = [], overrideUrl,
}) {
    const base = resolveBase(overrideUrl);
    const headers = await authHeader();
    const res = await fetch(`${base}/analyze-entry`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ entry_id, person, raw_text, occurred_at, recent_entries, boundaries }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok || body?.error) {
        const msg = body?.error?.message || `AI server returned ${res.status}`;
        throw new Error(msg);
    }
    return body;
}

export async function weeklySummary({
    person_id, iso_week, person, entries, score_history, overrideUrl,
}) {
    const base = resolveBase(overrideUrl);
    const headers = await authHeader();
    const res = await fetch(`${base}/weekly-summary`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ person_id, iso_week, person, entries, score_history }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok || body?.error) {
        const msg = body?.error?.message || `AI server returned ${res.status}`;
        throw new Error(msg);
    }
    return body;
}
