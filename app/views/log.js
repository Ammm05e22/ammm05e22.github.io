import { renderHeader } from '../components/header.js';
import { toast } from '../components/toast.js';
import { listPeople, getPerson } from '../api/people.js';
import { createEntry, listRecentEntriesByPerson } from '../api/entries.js';
import { saveAnalysis } from '../api/analysis.js';
import { getScore, updateScore, appendScoreHistory, listScoreHistory, rowToAxes } from '../api/scores.js';
import { listBoundaries } from '../api/boundaries.js';
import { analyzeEntry } from '../api/aiServer.js';
import { applyDeltas, composite, statusFor, trend, defaultAxes } from '../lib/scoring.js';
import { daysSince } from '../lib/dates.js';
import { getState } from '../state.js';
import { escapeHtml, escapeAttr } from '../lib/md.js';

export async function renderLog(root, params = {}) {
    const { user, settings } = getState();
    const preselectedId = params.personId || '';

    let people = [];
    try { people = await listPeople(); } catch (err) { /* surface below */ }

    root.innerHTML = `
        ${renderHeader('#/log')}
        <div class="page" style="max-width:720px">
            <h1>Log entry</h1>
            <p class="lede">Write what happened in plain language. The AI splits it into facts, feelings, and patterns — it doesn't decide for you.</p>
            <form id="log-form" class="card">
                <div class="field">
                    <label>Person</label>
                    <select name="person_id" required>
                        ${people.length === 0
                            ? `<option value="">No people yet — add one from the Portfolio</option>`
                            : `<option value="">— Select person —</option>${people.map(p => `<option value="${escapeAttr(p.id)}" ${p.id === preselectedId ? 'selected' : ''}>${escapeHtml(p.display_name)}</option>`).join('')}`
                        }
                    </select>
                </div>
                <div class="field">
                    <label>What happened</label>
                    <textarea name="raw_text" required placeholder="He didn't reply for 8 hours, then sent a sweet message at midnight..."></textarea>
                    <span class="hint">Write it like you'd say it out loud. Don't pre-edit.</span>
                </div>
                <div class="field">
                    <label>When (optional)</label>
                    <input type="datetime-local" name="occurred_at" />
                </div>
                <div class="btn-row" style="justify-content:flex-end">
                    <a href="#/" class="btn ghost">Cancel</a>
                    <button type="submit" class="btn primary">Analyze & save</button>
                </div>
            </form>
            <p class="hint" id="status-line" style="color:var(--text-dim);margin-top:14px;min-height:18px"></p>
        </div>
    `;

    const form = root.querySelector('#log-form');
    const statusLine = root.querySelector('#status-line');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(form);
        const personId = fd.get('person_id').toString();
        const rawText = fd.get('raw_text').toString().trim();
        const occurredAtRaw = fd.get('occurred_at').toString();
        if (!personId || !rawText) return;
        const occurredAt = occurredAtRaw ? new Date(occurredAtRaw).toISOString() : new Date().toISOString();

        const submitBtn = form.querySelector('button[type=submit]');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Saving entry…';
        statusLine.textContent = 'Saving entry…';

        try {
            const entry = await createEntry({
                user_id: user.id,
                person_id: personId,
                raw_text: rawText,
                occurred_at: occurredAt,
            });

            submitBtn.textContent = 'Analyzing…';
            statusLine.textContent = 'Calling AI server…';

            const [person, scoreRow, recent, boundaries] = await Promise.all([
                getPerson(personId),
                getScore(personId),
                listRecentEntriesByPerson(personId, 10),
                listBoundaries(user.id),
            ]);
            const currentAxes = scoreRow ? rowToAxes(scoreRow) : defaultAxes();

            let result;
            try {
                result = await analyzeEntry({
                    entry_id: entry.id,
                    person: {
                        id: person.id,
                        display_name: person.display_name,
                        relationship_type: person.relationship_type,
                        current_scores: currentAxes,
                    },
                    raw_text: rawText,
                    occurred_at: occurredAt,
                    recent_entries: recent
                        .filter(r => r.id !== entry.id)
                        .map(r => ({ occurred_at: r.occurred_at, raw_text: r.raw_text })),
                    boundaries: boundaries.map(b => b.text),
                    overrideUrl: settings?.ai_server_url,
                });
            } catch (err) {
                toast(`Entry saved but analysis failed: ${err.message}`, 'err');
                statusLine.textContent = 'Entry saved without analysis. You can retry from the person screen.';
                submitBtn.disabled = false;
                submitBtn.textContent = 'Analyze & save';
                location.hash = `#/p/${personId}`;
                return;
            }

            await saveAnalysis({
                entry_id: entry.id,
                user_id: user.id,
                model: result.model,
                payload: result.analysis,
            });

            const newAxes = applyDeltas(currentAxes, result.analysis.deltas);
            const newComp = composite(newAxes);
            const history = await listScoreHistory(personId, 200);
            const projectedHistory = [...history, { created_at: new Date().toISOString(), composite: newComp, axes: newAxes }];
            const trend14 = trend(projectedHistory, 14);
            const allEntriesCount = recent.length + 1;
            const daysSinceLast = recent[0] ? daysSince(recent[0].occurred_at) : 0;
            const status = statusFor({
                composite: newComp,
                trend14d: trend14,
                entryCount: allEntriesCount,
                daysSinceLast,
            });

            await Promise.all([
                updateScore({ person_id: personId, axes: newAxes, composite: newComp, status }),
                appendScoreHistory({ person_id: personId, user_id: user.id, composite: newComp, axes: newAxes, entry_id: entry.id }),
            ]);

            toast('Logged.', 'ok');
            location.hash = `#/p/${personId}`;
        } catch (err) {
            console.error(err);
            statusLine.textContent = '';
            toast(err.message || 'Failed to save entry', 'err');
            submitBtn.disabled = false;
            submitBtn.textContent = 'Analyze & save';
        }
    });
}
