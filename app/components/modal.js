export function openModal(html, { onMount } = {}) {
    const root = document.getElementById('modal-root');
    if (!root) return () => {};
    root.innerHTML = `
        <div class="modal-backdrop" data-close>
            <div class="modal" role="dialog">${html}</div>
        </div>
    `;
    const close = () => { root.innerHTML = ''; };
    root.querySelector('[data-close]').addEventListener('click', (e) => {
        if (e.target.hasAttribute('data-close')) close();
    });
    const modal = root.querySelector('.modal');
    if (onMount) onMount(modal, close);
    return close;
}
