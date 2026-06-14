export function escapeHtml(s) {
    if (s == null) return '';
    return String(s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

export function escapeLines(s) {
    return escapeHtml(s).replace(/\n/g, '<br>');
}

export function escapeAttr(s) {
    return escapeHtml(s);
}
