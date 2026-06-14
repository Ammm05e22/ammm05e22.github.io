import { renderHeader } from '../components/header.js';
import { toast } from '../components/toast.js';
import { getSettings, updateSettings } from '../api/settings.js';
import { getState, setState } from '../state.js';
import { escapeHtml, escapeAttr } from '../lib/md.js';

const DEFAULT_TRIGGERS = [
    'I lose sleep because of him.',
    'I stop working.',
    'I check my phone compulsively.',
    'I explain myself repeatedly with no change.',
    'I feel an emotional high right after an emotional low.',
];

export async function renderDiscipline(root) {
    const { user } = getState();
    const settings = await getSettings(user.id);
    const triggers = Array.isArray(settings?.discipline_triggers) && settings.discipline_triggers.length
        ? settings.discipline_triggers
        : DEFAULT_TRIGGERS;
    const isOn = !!settings?.discipline_mode;

    root.innerHTML = `
        ${renderHeader('#/discipline')}
        <div class="page" style="max-width:720px">
            <h1>Discipline Mode</h1>
            <p class="lede">A framing layer, not a lock. When you're emotionally activated, this is the screen that tells you: it is not decision time.</p>

            ${isOn ? `
                <div class="discipline-banner">
                    <h3>Discipline mode is on</h3>
                    <p>You are emotionally activated. This is not decision time. Write facts only. Finish your main task. Reassess later.</p>
                </div>
            ` : ''}

            <div class="card">
                <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
                    <div>
                        <div class="label">Status</div>
                        <div style="font-size:18px">${isOn ? 'On' : 'Off'}</div>
                    </div>
                    <button class="btn ${isOn ? 'danger' : 'primary'}" id="toggle-btn">${isOn ? 'Turn off' : 'Turn on'}</button>
                </div>
            </div>

            <h2>What triggers it for me</h2>
            <p class="lede" style="margin-bottom:16px">These are reminders, not enforcement. Edit to match your patterns.</p>
            <div class="card">
                <ul id="triggers-list" style="list-style:none;padding:0;margin:0">
                    ${triggers.map((t, i) => `
                        <li style="display:flex;align-items:center;justify-content:space-between;padding:10px 0;${i > 0 ? 'border-top:1px solid var(--border)' : ''}">
                            <span>${escapeHtml(t)}</span>
                            <button class="btn ghost" data-remove="${i}" style="padding:6px 12px;font-size:12px">Remove</button>
                        </li>
                    `).join('')}
                </ul>
                <form id="trigger-form" style="margin-top:16px;display:flex;gap:8px">
                    <input name="text" placeholder="Add a personal trigger…" required style="flex:1;background:var(--bg);color:var(--text);border:1px solid var(--border-strong);border-radius:var(--radius);padding:10px 12px;font-size:14px;outline:none" />
                    <button class="btn primary" type="submit">Add</button>
                </form>
            </div>

            <h2>What to do instead</h2>
            <div class="card" style="line-height:1.7;color:var(--text)">
                1. No texting until today's main goal is done.<br>
                2. No emotional decision for 24 hours.<br>
                3. Write the facts only — no interpretation.<br>
                4. Look at the trend, not the candle.<br>
                5. Complete one task before checking messages.
            </div>
        </div>
    `;

    root.querySelector('#toggle-btn').addEventListener('click', async () => {
        try {
            const updated = await updateSettings(user.id, { discipline_mode: !isOn });
            setState({ settings: updated });
            renderDiscipline(root);
        } catch (err) {
            toast(err.message || 'Could not update', 'err');
        }
    });

    root.querySelector('#trigger-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const text = fd.get('text').toString().trim();
        if (!text) return;
        const next = [...triggers, text];
        try {
            const updated = await updateSettings(user.id, { discipline_triggers: next });
            setState({ settings: updated });
            renderDiscipline(root);
        } catch (err) {
            toast(err.message || 'Could not add', 'err');
        }
    });

    root.querySelectorAll('[data-remove]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const idx = Number(btn.dataset.remove);
            const next = triggers.filter((_, i) => i !== idx);
            try {
                const updated = await updateSettings(user.id, { discipline_triggers: next });
                setState({ settings: updated });
                renderDiscipline(root);
            } catch (err) {
                toast(err.message || 'Could not remove', 'err');
            }
        });
    });
}
