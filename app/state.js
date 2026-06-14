const subscribers = new Set();

const state = {
    session: null,
    user: null,
    settings: null,
    boundaries: [],
};

export function getState() {
    return state;
}

export function setState(patch) {
    Object.assign(state, patch);
    for (const fn of subscribers) {
        try { fn(state); } catch (e) { console.error(e); }
    }
}

export function subscribe(fn) {
    subscribers.add(fn);
    return () => subscribers.delete(fn);
}
