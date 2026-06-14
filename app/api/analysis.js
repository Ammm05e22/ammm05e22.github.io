import { supabase } from '../supabaseClient.js';

export async function saveAnalysis({ entry_id, user_id, model, payload }) {
    const { data, error } = await supabase
        .from('entry_analysis')
        .insert({ entry_id, user_id, model, payload })
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function listAnalysesByPerson(personId, limit = 30) {
    // Pull recent entries then their latest analyses in one round trip.
    const { data, error } = await supabase
        .from('entries')
        .select('id, raw_text, occurred_at, created_at, entry_analysis(id, payload, model, created_at)')
        .eq('person_id', personId)
        .order('occurred_at', { ascending: false })
        .limit(limit);
    if (error) throw error;
    return (data || []).map(e => ({
        entry: { id: e.id, raw_text: e.raw_text, occurred_at: e.occurred_at, created_at: e.created_at },
        analysis: pickLatest(e.entry_analysis),
    }));
}

function pickLatest(rows) {
    if (!rows || rows.length === 0) return null;
    return rows.slice().sort((a, b) => new Date(b.created_at) - new Date(a.created_at))[0];
}
