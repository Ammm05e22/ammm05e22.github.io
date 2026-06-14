import { escapeHtml } from '../lib/md.js';

// Maps user-friendly KPI labels to underlying axes from the scoring lib.
// Order matters — this is the order shown on the person screen.
export const KPI_DEFS = [
    { axis: 'consistency',     label: 'Plan Commitment Rate' },
    { axis: 'integrity',       label: 'Word-Action Alignment' },
    { axis: 'emotionalSafety', label: 'Warmth Sentiment Score' },
];

export function renderKpiRow(axes) {
    return `
        <div class="kpi-row">
            ${KPI_DEFS.map(def => {
                const v = Math.max(0, Math.min(100, Math.round(Number(axes?.[def.axis]) || 0)));
                return `
                    <div class="kpi-card">
                        <div class="kpi-num">${v}%</div>
                        <div class="kpi-label">${escapeHtml(def.label)}</div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}
