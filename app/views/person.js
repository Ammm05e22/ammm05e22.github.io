import { renderHeader } from '../components/header.js';
import { renderStatusPill } from '../components/statusPill.js';
import { renderAxisBars } from '../components/axisBar.js';
import { renderChart } from '../components/chart.js';
import { renderEntrySplitCard } from '../components/entrySplitCard.js';
import { toast } from '../components/toast.js';
import { getPerson, archivePerson } from '../api/people.js';
import { getScore, listScoreHistory, rowToAxes } from '../api/scores.js';
import { listAnalysesByPerson } from '../api/analysis.js';
import { listRecentEntriesByPerson } from '../api/entries.js';
import { getLatestWeeklySummary, upsertWeeklySummary } from '../api/weeklySummaries.js';
import { weeklySummary } from '../api/aiServer.js';
import { detectPatterns } from '../lib/patterns.js';
import { isoWeek } from '../lib/dates.js';
import { getState } from '../state.js';
import { escapeHtml, escapeLines, escapeAttr } from '../lib/md.js';

export async function renderPerson(root, { personId }) {
    const { user, settings } = getState();
    root.innerHTML = `${renderHeader()}<div class="page"><p class="lede">Loading…</p></div>`;

    let person, scoreRow, history, items, latestSummary;
    try {
        [person, scoreRow, history, items, latestSummary] = await Promise.all([
            getPerson(personId),
            getScore(personId),
            listScoreHistory(personId, 200),
            listAnalysesByPerson(personId, 30),
            getLatestWeeklySummary(personId),
        ]);
    } catch (err) {
        root.innerHTML = `${renderHeader()}<div class="page"><h1>Could not load</h1><p class="lede">${escapeHtml(err.message)}</p></div>`;
        return;
    }

    const axes = scoreRow ? rowToAxes(scoreRow) : null;
    const compositeNum = scoreRow ? Math.round(Number(scoreRow.composite)) : 50;
    const status = scoreRow?.status || 'Watchlist';
    const chartPoints = history.map(h => ({ x: h.created_at, y: Number(h.composite) }));
    const entriesForPatterns = items.map(i => ({ ...i.entry }));
    const analysesForPatterns = items.map(i => i.analysis).filter(Boolean);
    const patterns = detectPatterns({
        entries: entriesForPatterns,
        analyses: analysesForPatterns,
        history,
    });

    root.innerHTML = `
        ${renderHeader()}
        <div class="page">
            <div class="person-header">
                <div>
                    <h1 class="name">${escapeHtml(person.display_name)}</h1>
                    <div class="meta">${escapeHtml(person.relationship_type || '—')} · Current score ${compositeNum} / 100</div>
                </div>
                <div class="btn-row">
                    ${renderStatusPill(status)}
                    <a href="#/log/${escapeAttr(person.id)}" class="btn primary">+ Log entry</a>
                    <button class="btn ghost" id="weekly-btn">Weekly summary</button>
                    <button class="btn danger" id="archive-btn">Archive</button>
                </div>
            </div>

            <div class="person-summary-grid">
                <div>${renderChart(chartPoints, { label: 'Composite over time' })}</div>
                <div class="card">
                    <div class="label">Axis breakdown</div>
                    ${axes ? renderAxisBars(axes) : '<p style="color:var(--text-dim)">No scores yet.</p>'}
                </div>
            </div>

            <div id="patterns-section"></div>
            <div id="weekly-section"></div>

            <h2>Recent entries</h2>
            <div id="entries-list">
                ${items.length === 0
                    ? `<div class="empty"><h3>No entries yet</h3><p>Log the first event to start the trend.</p><a href="#/log/${escapeAttr(person.id)}" class="btn primary">+ Log entry</a></div>`
                    : items.map(renderEntrySplitCard).join('')
                }
            </div>
        </div>
    `;

    // Patterns section
    const patternsEl = root.querySelector('#patterns-section');
    if (patterns.length > 0) {
        const sevStyle = {
            alert: 'background:rgba(248,113,113,0.12);color:var(--bad)',
            warn:  'background:rgba(251,191,36,0.14);color:var(--warn)',
            info:  'background:rgba(107,114,128,0.18);color:var(--text-dim)',
        };
        patternsEl.innerHTML = `
            <h2>Patterns</h2>
            <div class="card">
                ${patterns.map((p, i) => `
                    <div style="display:flex;gap:12px;align-items:flex-start;padding:10px 0;${i > 0 ? 'border-top:1px solid var(--border)' : ''}">
                        <span style="margin-top:2px;flex:0 0 auto;font-size:10px;letter-spacing:0.08em;text-transform:uppercase;padding:3px 8px;border-radius:4px;${sevStyle[p.severity] || sevStyle.info}">${escapeHtml(p.severity)}</span>
                        <span style="line-height:1.55">${escapeHtml(p.text)}</span>
                    </div>
                `).join('')}
            </div>
        `;
    }

    // Weekly summary section
    function renderWeeklyHtml(s) {
        if (!s?.payload) return '';
        return `
            <div class="weekly-summary">
                <h3>Weekly summary · ${escapeHtml(s.iso_week)}</h3>
                <p class="headline">${escapeLines(s.payload.headline || '')}</p>
                ${s.payload.themes?.length ? `<div class="themes">${s.payload.themes.map(t => `<span class="theme">${escapeHtml(t)}</span>`).join('')}</div>` : ''}
                ${s.payload.next_check_in ? `<p style="margin:14px 0 0;color:var(--text-dim);font-size:14px;line-height:1.55"><strong style="color:var(--accent);font-weight:500">Suggested next step:</strong> ${escapeLines(s.payload.next_check_in)}</p>` : ''}
            </div>
        `;
    }
    const weeklyEl = root.querySelector('#weekly-section');
    weeklyEl.innerHTML = renderWeeklyHtml(latestSummary);

    root.querySelector('#weekly-btn').addEventListener('click', async (e) => {
        const btn = e.currentTarget;
        btn.disabled = true;
        btn.textContent = 'Generating…';
        try {
            const result = await weeklySummary({
                person_id: person.id,
                iso_week: isoWeek(),
                person: { display_name: person.display_name, relationship_type: person.relationship_type },
                entries: items.slice(0, 14).map(i => ({
                    occurred_at: i.entry.occurred_at,
                    raw_text: i.entry.raw_text,
                    analysis: i.analysis?.payload || null,
                })),
                score_history: history.slice(-30),
                overrideUrl: settings?.ai_server_url,
            });
            const saved = await upsertWeeklySummary({
                user_id: user.id,
                person_id: person.id,
                iso_week: isoWeek(),
                payload: result.summary,
            });
            weeklyEl.innerHTML = renderWeeklyHtml(saved);
            toast('Weekly summary updated.', 'ok');
        } catch (err) {
            toast(err.message || 'Weekly summary failed', 'err');
        } finally {
            btn.disabled = false;
            btn.textContent = 'Weekly summary';
        }
    });

    root.querySelector('#archive-btn').addEventListener('click', async () => {
        if (!confirm(`Archive ${person.display_name}? Their data stays but they leave the portfolio.`)) return;
        try {
            await archivePerson(person.id);
            toast('Archived.', 'ok');
            location.hash = '#/';
        } catch (err) {
            toast(err.message || 'Could not archive', 'err');
        }
    });
}
