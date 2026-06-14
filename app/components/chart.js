// Hand-rolled SVG line chart for /person view.
// points: [{ x: timestamp (ms or ISO), y: number }]
export function renderChart(points, { width = 720, height = 220, label = 'Composite' } = {}) {
    const norm = (points || []).map(p => ({ x: new Date(p.x).getTime(), y: Number(p.y) }))
        .filter(p => Number.isFinite(p.x) && Number.isFinite(p.y))
        .sort((a, b) => a.x - b.x);

    if (norm.length === 0) {
        return `<div class="card"><div class="label">${label}</div><p style="color:var(--text-dim);margin:8px 0 0">No data yet. Log an entry to start the chart.</p></div>`;
    }

    const padL = 36, padR = 12, padT = 16, padB = 24;
    const innerW = width - padL - padR;
    const innerH = height - padT - padB;

    const xMin = norm[0].x;
    const xMax = norm[norm.length - 1].x;
    const xSpan = (xMax - xMin) || 1;
    const yMin = 0;
    const yMax = 100;
    const yScale = v => padT + innerH - ((v - yMin) / (yMax - yMin)) * innerH;
    const xScale = v => padL + ((v - xMin) / xSpan) * innerW;

    const path = norm.map((p, i) => `${i === 0 ? 'M' : 'L'} ${xScale(p.x).toFixed(1)} ${yScale(p.y).toFixed(1)}`).join(' ');
    const last = norm[norm.length - 1];
    const first = norm[0];
    const trendUp = last.y >= first.y;
    const color = trendUp ? '#4ade80' : '#f87171';

    const yTicks = [0, 25, 50, 75, 100];
    const gridLines = yTicks.map(v => {
        const y = yScale(v).toFixed(1);
        return `<line x1="${padL}" x2="${width - padR}" y1="${y}" y2="${y}" stroke="#1f1f1f"/>
                <text x="${padL - 6}" y="${y}" fill="#5a5a5a" font-size="10" text-anchor="end" dominant-baseline="middle">${v}</text>`;
    }).join('');

    const startLabel = new Date(xMin).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    const endLabel = new Date(xMax).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

    return `
        <div class="card">
            <div class="label">${label}</div>
            <svg class="chart" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
                ${gridLines}
                <path d="${path}" fill="none" stroke="${color}" stroke-width="2"/>
                <circle cx="${xScale(last.x).toFixed(1)}" cy="${yScale(last.y).toFixed(1)}" r="3" fill="${color}"/>
                <text x="${padL}" y="${height - 6}" fill="#5a5a5a" font-size="10">${startLabel}</text>
                <text x="${width - padR}" y="${height - 6}" fill="#5a5a5a" font-size="10" text-anchor="end">${endLabel}</text>
            </svg>
        </div>
    `;
}
