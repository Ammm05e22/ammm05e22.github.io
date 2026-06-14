import { escapeHtml, escapeLines } from '../lib/md.js';
import { relativeTime } from '../lib/dates.js';

function renderList(items) {
    if (!items || items.length === 0) return `<p style="color:var(--text-faint);font-size:13px;margin:0">—</p>`;
    return `<ul>${items.map(i => `<li>${escapeHtml(i)}</li>`).join('')}</ul>`;
}

function renderFlags(flags, kind) {
    if (!flags || flags.length === 0) return '';
    return `<div class="flags">${flags.map(f => `<span class="flag ${kind}">${escapeHtml(f)}</span>`).join('')}</div>`;
}

export function renderEntrySplitCard({ entry, analysis }) {
    const p = analysis?.payload || null;
    const when = entry?.occurred_at ? relativeTime(entry.occurred_at) : '';
    return `
        <div class="entry-split">
            <div class="when">${escapeHtml(when)}</div>
            <div class="raw">${escapeLines(entry?.raw_text || '')}</div>
            ${p ? `
                <div class="split-grid">
                    <div class="col">
                        <h4>Facts</h4>
                        ${renderList(p.facts)}
                    </div>
                    <div class="col">
                        <h4>Emotions</h4>
                        ${renderList(p.emotions)}
                    </div>
                    <div class="col">
                        <h4>Assumptions</h4>
                        ${renderList(p.assumptions)}
                    </div>
                    <div class="col">
                        <h4>Flags</h4>
                        ${renderFlags(p.red_flags, 'red')}
                        ${renderFlags(p.green_flags, 'green')}
                        ${(!p.red_flags?.length && !p.green_flags?.length) ? `<p style="color:var(--text-faint);font-size:13px;margin:0">—</p>` : ''}
                    </div>
                </div>
                ${p.recommendation ? `
                    <div class="reco">
                        <div class="label">Recommendation</div>
                        ${escapeLines(p.recommendation)}
                    </div>
                ` : ''}
            ` : `<p style="color:var(--text-faint);font-size:13px;margin:0">Analysis pending.</p>`}
        </div>
    `;
}
