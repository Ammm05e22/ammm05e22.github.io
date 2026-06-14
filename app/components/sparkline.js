export function renderSparkline(points, { width = 100, height = 36 } = {}) {
    if (!points || points.length === 0) {
        return `<svg class="sparkline" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
            <line x1="0" y1="${height/2}" x2="${width}" y2="${height/2}" stroke="#2a2a2a" stroke-dasharray="2,3"/>
        </svg>`;
    }
    const min = Math.min(...points);
    const max = Math.max(...points);
    const span = (max - min) || 1;
    const stepX = points.length > 1 ? width / (points.length - 1) : width;
    const pts = points.map((v, i) => {
        const x = i * stepX;
        const y = height - ((v - min) / span) * (height - 4) - 2;
        return `${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(' ');
    const last = points[points.length - 1];
    const first = points[0];
    const color = last >= first ? '#4ade80' : '#f87171';
    return `<svg class="sparkline" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
        <polyline fill="none" stroke="${color}" stroke-width="1.5" points="${pts}"/>
    </svg>`;
}
