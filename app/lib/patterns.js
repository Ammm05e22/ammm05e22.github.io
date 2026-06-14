import { daysBetween, daysSince } from './dates.js';
import { AXES } from './scoring.js';

// Look at the last N analyses + entries and surface simple observations.
// Returns an array of { id, text, severity: 'info'|'warn'|'alert' }.
export function detectPatterns({ entries = [], analyses = [], history = [] } = {}) {
    const out = [];

    // 1. Repeated red flags in the same axis vocabulary
    const flagCounts = {};
    for (const a of analyses) {
        const flags = a?.payload?.red_flags || [];
        for (const f of flags) {
            const key = String(f).toLowerCase().slice(0, 40);
            flagCounts[key] = (flagCounts[key] || 0) + 1;
        }
    }
    for (const [flag, n] of Object.entries(flagCounts)) {
        if (n >= 3) {
            out.push({
                id: `repeat-flag-${flag}`,
                text: `"${flag}" surfaced ${n} times in recent entries.`,
                severity: 'warn',
            });
        }
    }

    // 2. Axis decay (one axis dropped sharply across the recent window)
    if (history.length >= 4) {
        const first = history[0];
        const last = history[history.length - 1];
        for (const ax of AXES) {
            const a0 = Number(first.axes?.[ax]);
            const a1 = Number(last.axes?.[ax]);
            if (Number.isFinite(a0) && Number.isFinite(a1) && a0 - a1 >= 12) {
                out.push({
                    id: `decay-${ax}`,
                    text: `${ax} has dropped ${Math.round(a0 - a1)} points across recent entries.`,
                    severity: 'alert',
                });
            }
        }
    }

    // 3. Silence streaks
    const sorted = [...entries].sort(
        (a, b) => new Date(a.occurred_at) - new Date(b.occurred_at)
    );
    let longestGap = 0;
    for (let i = 1; i < sorted.length; i++) {
        const gap = daysBetween(sorted[i - 1].occurred_at, sorted[i].occurred_at);
        if (gap > longestGap) longestGap = gap;
    }
    if (longestGap >= 7) {
        out.push({
            id: 'silence-streak',
            text: `Longest gap between logged events: ${longestGap} days.`,
            severity: 'info',
        });
    }

    // 4. Anxiety/relief whiplash — emotions oscillating between anxiety and relief
    const emotionWords = ['anxious', 'anxiety', 'relief', 'relieved'];
    const whiplash = analyses.filter(a => {
        const ems = (a?.payload?.emotions || []).join(' ').toLowerCase();
        return emotionWords.some(w => ems.includes(w));
    }).length;
    if (whiplash >= 3) {
        out.push({
            id: 'whiplash',
            text: `Anxiety/relief cycle detected in ${whiplash} recent entries — possible intermittent reinforcement pattern.`,
            severity: 'warn',
        });
    }

    // 5. Stale — no entries in a while
    if (entries.length > 0) {
        const last = entries[0];
        const since = daysSince(last.occurred_at);
        if (since >= 21) {
            out.push({
                id: 'stale',
                text: `No logged events in ${since} days. Status may have shifted to Freeze.`,
                severity: 'info',
            });
        }
    }

    return out;
}
