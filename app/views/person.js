import { renderHeader } from '../components/header.js';
import { renderCandleChart, renderRangeTabs, rangeById } from '../components/candleChart.js';
import { renderKpiRow } from '../components/kpiRow.js';
import { openModal } from '../components/modal.js';
import { toast } from '../components/toast.js';
import { getPerson, updatePerson } from '../api/people.js';
import { getScore, listScoreHistory, rowToAxes } from '../api/scores.js';
import { listAnalysesByPerson } from '../api/analysis.js';
import { getLatestWeeklySummary, upsertWeeklySummary } from '../api/weeklySummaries.js';
import { weeklySummary } from '../api/aiServer.js';
import { detectPatterns } from '../lib/patterns.js';
import { isoWeek, relativeTime } from '../lib/dates.js';
import { getState } from '../state.js';
import { escapeHtml, escapeLines, escapeAttr } from '../lib/md.js';

const STANCES = ['Hold', 'Buy', 'Sell'];

function formatScore(n) {
    const v = Number(n) || 0;
    return v.toFixed(2).replace('.', ',');
}

function deltaSince(history, windowMs) {
    if (!history || history.length === 0) return { delta: 0, pct: 0, baseline: 0 };
    const cutoff = Date.now() - windowMs;
    const inRange = history.filter(h => new Date(h.created_at).getTime() >= cutoff);
    if (inRange.length === 0) return { delta: 0, pct: 0, baseline: Number(history[history.length-1].composite) };
    const first = Number(inRange[0].composite);
    const last = Number(inRange[inRange.length - 1].composite);
    const delta = last - first;
    const pct = first > 0 ? (delta / first) * 100 : 0;
    return { delta, pct, baseline: first };
}

function pickHeadline(item) {
    const p = item.analysis?.payload;
    if (p?.headline) return p.headline;
    const raw = item.entry?.raw_text || '';
    return raw.length > 70 ? raw.slice(0, 67) + '…' : raw;
}

function feedBulletKind(item) {
    const p = item.analysis?.payload;
    if (!p?.deltas) return '';
    const sum = Object.values(p.deltas).reduce((a, b) => a + Number(b || 0), 0);
    if (sum > 0) return 'green';
    if (sum < 0) return 'red';
    return '';
}

export async function renderPerson(root, { personId }) {
    const { user, settings } = getState();
    root.innerHTML = `${renderHeader()}<div class="tracker-page"><p style="color:var(--text-dim)">Loading…</p></div>`;

    let person, scoreRow, history, items, latestSummary;
    try {
        [person, scoreRow, history, items, latestSummary] = await Promise.all([
            getPerson(personId),
            getScore(personId),
            listScoreHistory(personId, 500),
            listAnalysesByPerson(personId, 30),
            getLatestWeeklySummary(personId),
        ]);
    } catch (err) {
        root.innerHTML = `${renderHeader()}<div class="tracker-page"><h1 class="tracker-title">Could not load</h1><p style="color:var(--text-dim)">${escapeHtml(err.message)}</p></div>`;
        return;
    }

    const axes = scoreRow ? rowToAxes(scoreRow) : null;
    const composite = scoreRow ? Number(scoreRow.composite) : 50;
    const rangeIds = ['1D','5D','1M','6M','1Y','ALL'];
    let activeRange = '1M';

    function deltaForRange(rangeId) {
        const ms = rangeById(rangeId).ms;
        return deltaSince(history, isFinite(ms) ? ms : Date.now());
    }

    function deltaHtml(rangeId) {
        const { delta, pct } = deltaForRange(rangeId);
        const up = delta >= 0;
        const sign = up ? '▲' : '▼';
        return `<span class="delta ${up ? 'up' : ''}">${sign} ${Math.abs(delta).toFixed(2).replace('.', ',')} (${Math.abs(pct).toFixed(2).replace('.', ',')}%)</span>`;
    }

    const patterns = detectPatterns({
        entries: items.map(i => i.entry),
        analyses: items.map(i => i.analysis).filter(Boolean),
        history,
    });

    const stance = person.user_stance || null;

    function shell() {
        return `
            ${renderHeader()}
            <div class="tracker-page">
                <a href="#/" class="tracker-back">← Portfolio</a>
                <h1 class="tracker-title">${escapeHtml(person.display_name)}</h1>

                <div class="tracker-metric-label">Relationship Index</div>
                <div class="tracker-metric">
                    <span class="num">${formatScore(composite)}</span>
                    <span id="delta-line">${deltaHtml(activeRange)}</span>
                </div>

                <div id="chart-box">${renderCandleChart(history, { rangeId: activeRange })}</div>
                ${renderRangeTabs(activeRange)}

                ${axes ? renderKpiRow(axes) : ''}

                <div class="news-feed">
                    <h3>News Feed</h3>
                    ${items.length === 0
                        ? `<p style="color:var(--text-dim);font-size:14px;margin:8px 0">No entries yet. <a href="#/log/${escapeAttr(person.id)}">Log the first event.</a></p>`
                        : items.slice(0, 12).map((item, i) => `
                            <div class="feed-item" data-entry-idx="${i}">
                                <span class="bullet ${feedBulletKind(item)}"></span>
                                <span class="text">${escapeHtml(pickHeadline(item))}</span>
                                <span class="when">${escapeHtml(relativeTime(item.entry.occurred_at))}</span>
                            </div>
                        `).join('')
                    }
                </div>

                ${patterns.length > 0 ? `
                    <div class="tracker-section-label">Patterns</div>
                    ${patterns.map(p => `
                        <div class="card" style="padding:14px 16px;margin-top:8px">
                            <div style="font-size:10px;letter-spacing:0.08em;text-transform:uppercase;color:${p.severity === 'alert' ? 'var(--bad)' : p.severity === 'warn' ? 'var(--warn)' : 'var(--text-dim)'};margin-bottom:4px">${escapeHtml(p.severity)}</div>
                            <div style="font-size:14px;line-height:1.5">${escapeHtml(p.text)}</div>
                        </div>
                    `).join('')}
                ` : ''}

                <div class="tracker-section-label">Portfolio View</div>
                <div class="action-bar">
                    ${STANCES.map(s => `
                        <button type="button" data-stance="${s}" class="action-btn ${s.toLowerCase()} ${stance === s ? 'active' : ''}">${s}</button>
                    `).join('')}
                </div>

                <div id="weekly-section" style="margin-top:20px">${renderWeeklyHtml(latestSummary)}</div>
                <div class="btn-row" style="margin-top:14px;justify-content:space-between">
                    <a href="#/log/${escapeAttr(person.id)}" class="btn primary">+ Log entry</a>
                    <button class="btn ghost" id="weekly-btn">Generate weekly summary</button>
                </div>
            </div>
        `;
    }

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

    root.innerHTML = shell();
    wireEvents();

    function wireEvents() {
        root.querySelectorAll('.range-tab').forEach(btn => {
            btn.addEventListener('click', () => {
                activeRange = btn.dataset.range;
                root.querySelectorAll('.range-tab').forEach(b => b.classList.toggle('active', b === btn));
                root.querySelector('#chart-box').innerHTML = renderCandleChart(history, { rangeId: activeRange });
                root.querySelector('#delta-line').innerHTML = deltaHtml(activeRange);
            });
        });

        root.querySelectorAll('.feed-item').forEach(el => {
            el.addEventListener('click', () => {
                const idx = Number(el.dataset.entryIdx);
                const item = items[idx];
                openEntryDetail(item);
            });
        });

        root.querySelectorAll('[data-stance]').forEach(btn => {
            btn.addEventListener('click', async () => {
                const newStance = btn.dataset.stance;
                try {
                    await updatePerson(person.id, {
                        user_stance: newStance,
                        user_stance_updated_at: new Date().toISOString(),
                    });
                    person.user_stance = newStance;
                    root.querySelectorAll('[data-stance]').forEach(b => b.classList.toggle('active', b.dataset.stance === newStance));
                    toast(`Marked ${newStance}.`, 'ok');
                } catch (err) {
                    toast(err.message || 'Could not save', 'err');
                }
            });
        });

        const weeklyBtn = root.querySelector('#weekly-btn');
        if (weeklyBtn) {
            weeklyBtn.addEventListener('click', async () => {
                weeklyBtn.disabled = true;
                weeklyBtn.textContent = 'Generating…';
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
                    root.querySelector('#weekly-section').innerHTML = renderWeeklyHtml(saved);
                    toast('Weekly summary updated.', 'ok');
                } catch (err) {
                    toast(err.message || 'Weekly summary failed', 'err');
                } finally {
                    weeklyBtn.disabled = false;
                    weeklyBtn.textContent = 'Generate weekly summary';
                }
            });
        }
    }

    function openEntryDetail(item) {
        const p = item.analysis?.payload;
        const headline = pickHeadline(item);
        const factsList = (p?.facts || []).map(f => `<li>${escapeHtml(f)}</li>`).join('') || '<li style="color:var(--text-faint)">—</li>';
        const emotionsList = (p?.emotions || []).map(e => `<li>${escapeHtml(e)}</li>`).join('') || '<li style="color:var(--text-faint)">—</li>';
        const assumptionsList = (p?.assumptions || []).map(a => `<li>${escapeHtml(a)}</li>`).join('') || '<li style="color:var(--text-faint)">—</li>';
        openModal(`
            <div class="entry-detail-modal">
                <h2 style="font-weight:500;margin:0 0 4px">${escapeHtml(headline)}</h2>
                <div style="color:var(--text-faint);font-size:11px;letter-spacing:0.08em;text-transform:uppercase;margin-bottom:14px">${escapeHtml(relativeTime(item.entry.occurred_at))}</div>
                <div class="raw">${escapeLines(item.entry.raw_text)}</div>
                <h4>Facts</h4><ul>${factsList}</ul>
                <h4>Emotions</h4><ul>${emotionsList}</ul>
                <h4>Assumptions</h4><ul>${assumptionsList}</ul>
                ${p?.recommendation ? `<div class="reco" style="background:var(--bg-elev-2);border-left:2px solid var(--accent);padding:12px 14px;margin-top:14px;font-size:14px;line-height:1.55">${escapeLines(p.recommendation)}</div>` : ''}
                <div class="btn-row" style="margin-top:18px;justify-content:flex-end">
                    <button class="btn ghost" data-close-modal>Close</button>
                </div>
            </div>
        `, {
            onMount: (modal, close) => {
                modal.querySelector('[data-close-modal]').addEventListener('click', close);
            }
        });
    }
}
