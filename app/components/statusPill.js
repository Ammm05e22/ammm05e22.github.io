import { statusClass } from '../lib/scoring.js';
import { escapeHtml } from '../lib/md.js';

export function renderStatusPill(status) {
    const s = status || 'Watchlist';
    return `<span class="pill ${statusClass(s)}">${escapeHtml(s)}</span>`;
}
