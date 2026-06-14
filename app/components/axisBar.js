import { AXES, AXIS_LABEL } from '../lib/scoring.js';
import { escapeHtml } from '../lib/md.js';

export function renderAxisBars(axes) {
    return `
        <div class="axes">
            ${AXES.map(a => {
                const v = Math.max(0, Math.min(100, Math.round(Number(axes?.[a]) || 0)));
                return `
                    <div class="axis">
                        <div class="name">${escapeHtml(AXIS_LABEL[a])}</div>
                        <div class="track"><div class="fill" style="width:${v}%"></div></div>
                        <div class="val">${v}</div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}
