import { supabase } from './supabaseClient.js';
import { setState } from './state.js';
import { ensureProfile, ensureSettings, getSettings } from './api/settings.js';
import { listBoundaries } from './api/boundaries.js';
import { startRouter, mount } from './router.js';
import { SUPABASE_URL, AI_SERVER_BASE_URL } from './config.js';

async function hydrateForSession(session) {
    if (!session) {
        setState({ session: null, user: null, settings: null, boundaries: [] });
        return;
    }
    const user = session.user;
    setState({ session, user });
    try {
        await ensureProfile(user.id, user.email);
        const settings = await ensureSettings(user.id);
        const boundaries = await listBoundaries(user.id);
        setState({ settings, boundaries });
    } catch (err) {
        console.error('Hydration failed', err);
    }
}

async function boot() {
    if (!SUPABASE_URL || SUPABASE_URL.includes('YOUR_PROJECT_REF')) {
        document.getElementById('root').innerHTML = `
            <div class="page" style="max-width:560px">
                <h1>Configuration needed</h1>
                <p class="lede">Open <code>app/config.js</code> and set <code>SUPABASE_URL</code>, <code>SUPABASE_ANON_KEY</code>, and <code>AI_SERVER_BASE_URL</code>.</p>
                <p class="lede" style="color:var(--text-faint)">Schema lives in <code>SupabaseStarter/supabase-schema-rcd.sql</code>; run it in the Supabase SQL editor.</p>
            </div>
        `;
        return;
    }

    const { data } = await supabase.auth.getSession();
    await hydrateForSession(data?.session || null);

    supabase.auth.onAuthStateChange(async (_event, session) => {
        await hydrateForSession(session);
        if (!session && location.hash !== '#/auth') location.hash = '#/auth';
        else mount();
    });

    if (!AI_SERVER_BASE_URL) {
        console.warn('AI_SERVER_BASE_URL is empty. Analysis calls will fail until set in config.js or overridden in Settings.');
    }

    startRouter();
}

boot();
