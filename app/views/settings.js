import { renderHeader } from '../components/header.js';
import { toast } from '../components/toast.js';
import { supabase } from '../supabaseClient.js';
import { getSettings, updateSettings } from '../api/settings.js';
import { listBoundaries, createBoundary, deleteBoundary } from '../api/boundaries.js';
import { getState, setState } from '../state.js';
import { escapeHtml, escapeAttr } from '../lib/md.js';

export async function renderSettings(root) {
    const { user } = getState();
    const [settings, boundaries] = await Promise.all([
        getSettings(user.id),
        listBoundaries(user.id),
    ]);

    root.innerHTML = `
        ${renderHeader('#/settings')}
        <div class="page" style="max-width:720px">
            <h1>Settings</h1>

            <h2>AI server</h2>
            <div class="card">
                <p class="hint" style="color:var(--text-dim);margin:0 0 12px;font-size:14px">
                    Calls go through your own server, which holds the OpenAI key. Leave blank to use the default configured in <code>config.js</code>.
                </p>
                <form id="ai-form">
                    <div class="field">
                        <label>Override AI server URL</label>
                        <input type="url" name="ai_server_url" value="${escapeAttr(settings?.ai_server_url || '')}" placeholder="https://your-ai-proxy.example.com" />
                    </div>
                    <div class="btn-row" style="justify-content:flex-end">
                        <button class="btn primary" type="submit">Save</button>
                    </div>
                </form>
            </div>

            <h2>Non-negotiables</h2>
            <p class="lede">These are sent to the AI as context so the analysis stays grounded in your standards, not generic advice.</p>
            <div class="card">
                <ul id="boundaries-list" style="list-style:none;padding:0;margin:0">
                    ${boundaries.length === 0
                        ? `<li style="color:var(--text-dim);font-size:14px">No non-negotiables yet.</li>`
                        : boundaries.map(b => `
                            <li style="display:flex;align-items:center;justify-content:space-between;padding:10px 0;border-top:1px solid var(--border)">
                                <span>${escapeHtml(b.text)}</span>
                                <button class="btn ghost" data-delete="${escapeAttr(b.id)}" style="padding:6px 12px;font-size:12px">Remove</button>
                            </li>
                        `).join('')
                    }
                </ul>
                <form id="boundary-form" style="margin-top:16px;display:flex;gap:8px">
                    <input name="text" placeholder="e.g. Replies within a day" required style="flex:1;background:var(--bg);color:var(--text);border:1px solid var(--border-strong);border-radius:var(--radius);padding:10px 12px;font-size:14px;outline:none" />
                    <button class="btn primary" type="submit">Add</button>
                </form>
            </div>

            <h2>Account</h2>
            <div class="card">
                <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">
                    <div>
                        <div class="label">Signed in as</div>
                        <div>${escapeHtml(user.email || user.id)}</div>
                    </div>
                    <button class="btn danger" id="signout">Sign out</button>
                </div>
            </div>
        </div>
    `;

    root.querySelector('#ai-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const url = fd.get('ai_server_url').toString().trim() || null;
        try {
            const updated = await updateSettings(user.id, { ai_server_url: url });
            setState({ settings: updated });
            toast('Saved.', 'ok');
        } catch (err) {
            toast(err.message || 'Could not save', 'err');
        }
    });

    root.querySelector('#boundary-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const text = fd.get('text').toString().trim();
        if (!text) return;
        try {
            await createBoundary({ user_id: user.id, text, sort_order: boundaries.length });
            renderSettings(root);
        } catch (err) {
            toast(err.message || 'Could not add', 'err');
        }
    });

    root.querySelectorAll('[data-delete]').forEach(btn => {
        btn.addEventListener('click', async () => {
            try {
                await deleteBoundary(btn.dataset.delete);
                renderSettings(root);
            } catch (err) {
                toast(err.message || 'Could not delete', 'err');
            }
        });
    });

    root.querySelector('#signout').addEventListener('click', async () => {
        await supabase.auth.signOut();
        location.hash = '#/auth';
    });
}
