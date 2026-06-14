// Bucket score_history into OHLC candles. Returns array of
// { time, open, close, high, low }.
export function buildCandles(history, bucketMs) {
    const points = (history || [])
        .map(h => ({ t: new Date(h.created_at).getTime(), v: Number(h.composite) }))
        .filter(p => Number.isFinite(p.t) && Number.isFinite(p.v))
        .sort((a, b) => a.t - b.t);
    if (points.length === 0) return [];
    const buckets = new Map();
    for (const p of points) {
        const key = Math.floor(p.t / bucketMs) * bucketMs;
        if (!buckets.has(key)) buckets.set(key, []);
        buckets.get(key).push(p.v);
    }
    return [...buckets.entries()]
        .sort((a, b) => a[0] - b[0])
        .map(([t, vs]) => ({
            time: t,
            open: vs[0],
            close: vs[vs.length - 1],
            high: Math.max(...vs),
            low: Math.min(...vs),
        }));
}

export const RANGES = [
    { id: '1D',  ms: 24 * 3600 * 1000,           bucket: 3600 * 1000 },
    { id: '5D',  ms: 5 * 24 * 3600 * 1000,       bucket: 6 * 3600 * 1000 },
    { id: '1M',  ms: 30 * 24 * 3600 * 1000,      bucket: 24 * 3600 * 1000 },
    { id: '6M',  ms: 182 * 24 * 3600 * 1000,     bucket: 24 * 3600 * 1000 },
    { id: '1Y',  ms: 365 * 24 * 3600 * 1000,     bucket: 7 * 24 * 3600 * 1000 },
    { id: 'ALL', ms: Infinity,                   bucket: 7 * 24 * 3600 * 1000 },
];

export function rangeById(id) {
    return RANGES.find(r => r.id === id) || RANGES[2];
}

export function renderCandleChart(history, { rangeId = '1M', width = 360, height = 180 } = {}) {
    const range = rangeById(rangeId);
    const cutoff = Date.now() - range.ms;
    const inRange = (history || []).filter(h => new Date(h.created_at).getTime() >= cutoff);
    const candles = buildCandles(inRange, range.bucket);

    if (candles.length === 0) {
        return `<svg class="candles" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
            <text x="${width/2}" y="${height/2}" fill="#5a5a5a" font-size="11" text-anchor="middle" font-family="Spartan, sans-serif">No data in this range</text>
        </svg>`;
    }

    const padL = 6, padR = 6, padT = 8, padB = 18;
    const innerW = width - padL - padR;
    const innerH = height - padT - padB;

    let yLo = Math.min(...candles.map(c => c.low));
    let yHi = Math.max(...candles.map(c => c.high));
    const pad = Math.max(2, (yHi - yLo) * 0.1);
    yLo = Math.max(0, yLo - pad);
    yHi = Math.min(100, yHi + pad);
    if (yHi - yLo < 5) { yHi = Math.min(100, yLo + 5); }

    const yScale = v => padT + innerH - ((v - yLo) / (yHi - yLo)) * innerH;
    const slotW = innerW / candles.length;
    const bodyW = Math.max(2, Math.min(12, slotW * 0.7));

    const candlesSvg = candles.map((c, i) => {
        const cx = padL + slotW * i + slotW / 2;
        const wickTop = yScale(c.high);
        const wickBot = yScale(c.low);
        const bodyTop = yScale(Math.max(c.open, c.close));
        const bodyBot = yScale(Math.min(c.open, c.close));
        const up = c.close >= c.open;
        const color = up ? '#4ade80' : '#f87171';
        const bodyH = Math.max(1, bodyBot - bodyTop);
        return `
            <line x1="${cx.toFixed(1)}" x2="${cx.toFixed(1)}" y1="${wickTop.toFixed(1)}" y2="${wickBot.toFixed(1)}" stroke="${color}" stroke-width="1"/>
            <rect x="${(cx - bodyW/2).toFixed(1)}" y="${bodyTop.toFixed(1)}" width="${bodyW.toFixed(1)}" height="${bodyH.toFixed(1)}" fill="${color}"/>
        `;
    }).join('');

    const startLbl = new Date(candles[0].time).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    const endLbl = new Date(candles[candles.length-1].time).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    const midLbl = new Date(candles[Math.floor(candles.length/2)].time).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

    return `
        <svg class="candles" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
            <line x1="${padL}" x2="${width - padR}" y1="${padT + innerH}" y2="${padT + innerH}" stroke="#1f1f1f" stroke-width="0.5"/>
            ${candlesSvg}
            <text x="${padL}" y="${height - 4}" fill="#5a5a5a" font-size="9" font-family="Spartan, sans-serif">${startLbl}</text>
            <text x="${width/2}" y="${height - 4}" fill="#5a5a5a" font-size="9" text-anchor="middle" font-family="Spartan, sans-serif">${midLbl}</text>
            <text x="${width - padR}" y="${height - 4}" fill="#5a5a5a" font-size="9" text-anchor="end" font-family="Spartan, sans-serif">${endLbl}</text>
        </svg>
    `;
}

export function renderRangeTabs(activeId = '1M') {
    return `
        <div class="range-tabs" role="tablist">
            ${RANGES.map(r => `
                <button type="button" data-range="${r.id}" class="range-tab ${r.id === activeId ? 'active' : ''}">${r.id}</button>
            `).join('')}
        </div>
    `;
}
