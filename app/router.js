import { renderAuth } from './views/auth.js';
import { renderDashboard } from './views/dashboard.js';
import { renderPerson } from './views/person.js';
import { renderLog } from './views/log.js';
import { renderSettings } from './views/settings.js';
import { renderDiscipline } from './views/discipline.js';
import { getState } from './state.js';

const routes = [
    { match: /^#\/auth$/,            view: renderAuth, anonymous: true },
    { match: /^#\/$|^$/,             view: renderDashboard },
    { match: /^#\/p\/([^/]+)$/,      view: renderPerson, params: ['personId'] },
    { match: /^#\/log$/,             view: renderLog },
    { match: /^#\/log\/([^/]+)$/,    view: renderLog, params: ['personId'] },
    { match: /^#\/settings$/,        view: renderSettings },
    { match: /^#\/discipline$/,      view: renderDiscipline },
];

function resolve(hash) {
    for (const r of routes) {
        const m = hash.match(r.match);
        if (m) {
            const params = {};
            (r.params || []).forEach((name, i) => { params[name] = decodeURIComponent(m[i + 1]); });
            return { view: r.view, params, anonymous: !!r.anonymous };
        }
    }
    return { view: renderDashboard, params: {}, anonymous: false };
}

export function navigate(hash) {
    if (location.hash !== hash) location.hash = hash;
    else mount();
}

export async function mount() {
    const root = document.getElementById('root');
    if (!root) return;
    const route = resolve(location.hash);
    const { session } = getState();
    if (!route.anonymous && !session) {
        location.hash = '#/auth';
        return;
    }
    if (route.anonymous && session && location.hash === '#/auth') {
        location.hash = '#/';
        return;
    }
    root.innerHTML = '<div class="page"><p class="lede">Loading…</p></div>';
    try {
        await route.view(root, route.params);
    } catch (err) {
        console.error('Route render failed', err);
        root.innerHTML = `<div class="page"><h1>Something went wrong</h1><p class="lede">${err.message || err}</p></div>`;
    }
}

export function startRouter() {
    window.addEventListener('hashchange', mount);
    mount();
}
