import { renderHeader } from '../components/header.js';
import { renderStatusPill } from '../components/statusPill.js';
import { renderSparkline } from '../components/sparkline.js';
import { openModal } from '../components/modal.js';
import { toast } from '../components/toast.js';
import { listPeople, createPerson } from '../api/people.js';
import { listScoresForPeople } from '../api/scores.js';
import { listScoreHistory } from '../api/scores.js';
import { getState } from '../state.js';
import { escapeHtml, escapeAttr } from '../lib/md.js';

export async function renderDashboard(root) {
    const { user } = getState();
    root.innerHTML = `
        ${renderHeader('#/')}
        <div class="page">
            <div style="display:flex;justify-content:space-between;align-items:flex-end;flex-wrap:wrap;gap:12px;margin-bottom:24px">
                <div>
                    <h1>Portfolio</h1>
                    <p class="lede">Each person is an asset. Score, status, and trend update with every entry.</p>
                </div>
                <div class="btn-row">
                    <button class="btn primary" id="add-person">+ Add person</button>
                    <a href="#/log" class="btn">Log entry</a>
                </div>
            </div>
            <div id="people-list"><p style="color:var(--text-dim)">Loading…</p></div>
        </div>
    `;

    root.querySelector('#add-person').addEventListener('click', () => {
        openModal(`
            <h2>New person</h2>
            <form id="new-person-form">
                <div class="field">
                    <label>Nickname (you can keep it anonymous)</label>
                    <input name="display_name" required maxlength="80" />
                </div>
                <div class="field">
                    <label>Relationship type</label>
                    <select name="relationship_type">
                        <option value="romantic">Romantic</option>
                        <option value="situationship">Situationship</option>
                        <option value="friend">Friend</option>
                        <option value="family">Family</option>
                        <option value="work">Work</option>
                        <option value="other">Other</option>
                    </select>
                </div>
                <div class="field">
                    <label>Private notes</label>
                    <textarea name="notes" placeholder="Context only you see"></textarea>
                </div>
                <div class="btn-row" style="margin-top:8px;justify-content:flex-end">
                    <button type="button" class="btn ghost" data-cancel>Cancel</button>
                    <button type="submit" class="btn primary">Add</button>
                </div>
            </form>
        `, {
            onMount: (modal, close) => {
                modal.querySelector('[data-cancel]').addEventListener('click', close);
                modal.querySelector('#new-person-form').addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const fd = new FormData(e.target);
                    try {
                        await createPerson({
                            user_id: user.id,
                            display_name: fd.get('display_name').toString().trim(),
                            relationship_type: fd.get('relationship_type').toString(),
                            notes: fd.get('notes').toString().trim() || null,
                        });
                        close();
                        toast('Added.', 'ok');
                        renderDashboard(root);
                    } catch (err) {
                        toast(err.message || 'Could not add person', 'err');
                    }
                });
            }
        });
    });

    try {
        const people = await listPeople();
        if (people.length === 0) {
            root.querySelector('#people-list').innerHTML = `
                <div class="empty">
                    <h3>No one in the portfolio yet</h3>
                    <p>Add the first person to start tracking patterns.</p>
                    <button class="btn primary" onclick="document.getElementById('add-person').click()">+ Add person</button>
                </div>
            `;
            return;
        }
        const scores = await listScoresForPeople(people.map(p => p.id));
        const scoreById = Object.fromEntries(scores.map(s => [s.person_id, s]));

        const sparklines = await Promise.all(people.map(async p => {
            const history = await listScoreHistory(p.id, 30);
            return { id: p.id, points: history.map(h => Number(h.composite)) };
        }));
        const sparkById = Object.fromEntries(sparklines.map(s => [s.id, s.points]));

        root.querySelector('#people-list').innerHTML = `
            <div class="portfolio-grid">
                ${people.map(p => {
                    const s = scoreById[p.id] || {};
                    const comp = Math.round(Number(s.composite ?? 50));
                    const status = s.status || 'Watchlist';
                    const points = sparkById[p.id] || [];
                    const trendDelta = points.length >= 2 ? Math.round(points[points.length-1] - points[0]) : 0;
                    const trendCls = trendDelta > 0 ? 'up' : trendDelta < 0 ? 'down' : '';
                    return `
                        <a href="#/p/${escapeAttr(p.id)}" class="person-card" style="display:block;color:inherit;text-decoration:none">
                            <div class="top">
                                <div>
                                    <div class="name">${escapeHtml(p.display_name)}</div>
                                    <div class="meta">${escapeHtml(p.relationship_type || '—')}</div>
                                </div>
                                ${renderStatusPill(status)}
                            </div>
                            <div class="composite">
                                <span class="num">${comp}</span>
                                <span class="unit">/ 100</span>
                            </div>
                            <div class="trend ${trendCls}">${trendDelta >= 0 ? '+' : ''}${trendDelta} pts · last 30d</div>
                            <div style="margin-top:10px">${renderSparkline(points, { width: 240, height: 36 })}</div>
                        </a>
                    `;
                }).join('')}
            </div>
        `;
    } catch (err) {
        root.querySelector('#people-list').innerHTML = `<p style="color:var(--bad)">${escapeHtml(err.message || 'Could not load people.')}</p>`;
    }
}
