export const AXES = [
    'emotionalSafety',
    'consistency',
    'reciprocity',
    'growthAlignment',
    'integrity',
    'attraction',
];

export const AXIS_LABEL = {
    emotionalSafety: 'Emotional Safety',
    consistency: 'Consistency',
    reciprocity: 'Reciprocity',
    growthAlignment: 'Growth Alignment',
    integrity: 'Integrity',
    attraction: 'Attraction',
};

export const COMPOSITE_WEIGHTS = {
    emotionalSafety: 0.25,
    consistency: 0.20,
    integrity: 0.20,
    reciprocity: 0.15,
    growthAlignment: 0.10,
    attraction: 0.10,
};

export const DELTA_DAMPING = 0.6;
export const NEUTRAL_START = 50;

const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));

export function defaultAxes() {
    const out = {};
    for (const a of AXES) out[a] = NEUTRAL_START;
    return out;
}

export function applyDeltas(current, deltas) {
    const next = { ...current };
    for (const a of AXES) {
        const d = Number(deltas?.[a] ?? 0);
        const safe = Number.isFinite(d) ? d : 0;
        next[a] = clamp((Number(current[a]) || NEUTRAL_START) + safe * DELTA_DAMPING, 0, 100);
    }
    return next;
}

export function composite(axes) {
    let sum = 0;
    let weightSum = 0;
    for (const a of AXES) {
        const v = Number(axes?.[a]);
        if (!Number.isFinite(v)) continue;
        const w = COMPOSITE_WEIGHTS[a];
        sum += v * w;
        weightSum += w;
    }
    if (weightSum === 0) return NEUTRAL_START;
    return Math.round((sum / weightSum) * 10) / 10;
}

// Trend over the last `windowDays` days, in composite points.
export function trend(history, windowDays = 14) {
    if (!history || history.length === 0) return 0;
    const cutoff = Date.now() - windowDays * 86400000;
    const recent = history.filter(h => new Date(h.created_at).getTime() >= cutoff);
    if (recent.length === 0) return 0;
    const first = Number(recent[0].composite);
    const last = Number(recent[recent.length - 1].composite);
    return Math.round((last - first) * 10) / 10;
}

export const STATUS = {
    EXIT: 'Exit',
    REDUCE: 'Reduce',
    FREEZE: 'Freeze',
    WATCHLIST: 'Watchlist',
    BUY: 'Buy',
    HOLD: 'Hold',
};

export function statusFor({ composite, trend14d = 0, entryCount = 0, daysSinceLast = 0 }) {
    const c = Number(composite);
    if (c < 30 || (c < 45 && trend14d <= -10)) return STATUS.EXIT;
    if (c >= 30 && c < 50 && trend14d <= -3) return STATUS.REDUCE;
    if (Math.abs(trend14d) < 1 && daysSinceLast >= 21) return STATUS.FREEZE;
    if (entryCount < 3) return STATUS.WATCHLIST;
    if (c >= 80 || (c >= 70 && trend14d >= 3)) return STATUS.BUY;
    return STATUS.HOLD;
}

export function statusClass(status) {
    return String(status || '').toLowerCase();
}

// Convert DB row (snake_case axes) into the camelCase axes shape we use everywhere.
export function rowToAxes(row) {
    if (!row) return defaultAxes();
    return {
        emotionalSafety: Number(row.emotional_safety ?? NEUTRAL_START),
        consistency: Number(row.consistency ?? NEUTRAL_START),
        reciprocity: Number(row.reciprocity ?? NEUTRAL_START),
        growthAlignment: Number(row.growth_alignment ?? NEUTRAL_START),
        integrity: Number(row.integrity ?? NEUTRAL_START),
        attraction: Number(row.attraction ?? NEUTRAL_START),
    };
}

// Convert camelCase axes back to DB columns.
export function axesToRow(axes) {
    return {
        emotional_safety: axes.emotionalSafety,
        consistency: axes.consistency,
        reciprocity: axes.reciprocity,
        growth_alignment: axes.growthAlignment,
        integrity: axes.integrity,
        attraction: axes.attraction,
    };
}
