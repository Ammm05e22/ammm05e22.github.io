import { supabase } from '../supabaseClient.js';
import { toast } from '../components/toast.js';

export async function renderAuth(root) {
    root.innerHTML = `
        <div class="auth-wrap">
            <div class="brand"><div class="dot"></div><div class="name">Relationship Portfolio</div></div>
            <p class="lede" style="color:var(--text-dim);margin-bottom:24px;line-height:1.55">
                Track relationships like a portfolio. Separate facts from feelings, detect patterns, make calmer decisions.
            </p>
            <div class="tabs">
                <button data-tab="signin" class="active">Sign in</button>
                <button data-tab="signup">Sign up</button>
            </div>
            <form id="auth-form">
                <div class="field">
                    <label>Email</label>
                    <input type="email" name="email" required autocomplete="email" />
                </div>
                <div class="field">
                    <label>Password</label>
                    <input type="password" name="password" required minlength="6" autocomplete="current-password" />
                </div>
                <div class="btn-row" style="margin-top:18px">
                    <button type="submit" class="btn primary" style="flex:1;justify-content:center">Continue</button>
                </div>
            </form>
            <p class="hint" style="color:var(--text-faint);font-size:12px;margin-top:24px;line-height:1.5">
                Your data stays in your Supabase project. The AI server only sees the entry you submit, not your account.
            </p>
        </div>
    `;

    let mode = 'signin';
    const tabs = root.querySelectorAll('.tabs button');
    tabs.forEach(t => t.addEventListener('click', () => {
        mode = t.dataset.tab;
        tabs.forEach(x => x.classList.toggle('active', x === t));
        const pwd = root.querySelector('input[name=password]');
        pwd.autocomplete = mode === 'signin' ? 'current-password' : 'new-password';
    }));

    root.querySelector('#auth-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const email = fd.get('email').toString().trim();
        const password = fd.get('password').toString();
        const btn = e.target.querySelector('button[type=submit]');
        btn.disabled = true;
        btn.textContent = 'Working…';
        try {
            if (mode === 'signup') {
                const { error } = await supabase.auth.signUp({ email, password });
                if (error) throw error;
                toast('Check your email if confirmation is required, otherwise you are signed in.', 'ok');
            } else {
                const { error } = await supabase.auth.signInWithPassword({ email, password });
                if (error) throw error;
            }
        } catch (err) {
            toast(err.message || 'Auth failed', 'err');
            btn.disabled = false;
            btn.textContent = 'Continue';
        }
    });
}
