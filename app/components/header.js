import { escapeHtml } from '../lib/md.js';

export function renderHeader(activeRoute = '') {
    const tabs = [
        { href: '#/',           label: 'Portfolio' },
        { href: '#/log',        label: 'Log' },
        { href: '#/discipline', label: 'Discipline' },
        { href: '#/settings',   label: 'Settings' },
    ];
    return `
        <header class="app-header">
            <div class="brand"><div class="dot"></div><span>Relationship Portfolio</span></div>
            <nav>
                ${tabs.map(t => `<a href="${escapeHtml(t.href)}" class="${activeRoute === t.href ? 'active' : ''}">${escapeHtml(t.label)}</a>`).join('')}
            </nav>
        </header>
    `;
}
