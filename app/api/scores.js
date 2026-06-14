import { supabase } from '../supabaseClient.js';
import { axesToRow, rowToAxes } from '../lib/scoring.js';

export async function getScore(personId) {
    const { data, error } = await supabase
        .from('scores')
        .select('*')
        .eq('person_id', personId)
        .single();
    if (error && error.code !== 'PGRST116') throw error;
    return data;
}

export async function listScoresForPeople(personIds) {
    if (!personIds.length) return [];
    const { data, error } = await supabase
        .from('scores')
        .select('*')
        .in('person_id', personIds);
    if (error) throw error;
    return data || [];
}

export async function updateScore({ person_id, axes, composite, status }) {
    const { data, error } = await supabase
        .from('scores')
        .update({
            ...axesToRow(axes),
            composite,
            status,
            last_updated: new Date().toISOString(),
        })
        .eq('person_id', person_id)
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function appendScoreHistory({ person_id, user_id, composite, axes, entry_id }) {
    const { error } = await supabase
        .from('score_history')
        .insert({ person_id, user_id, composite, axes, entry_id });
    if (error) throw error;
}

export async function listScoreHistory(personId, limit = 200) {
    const { data, error } = await supabase
        .from('score_history')
        .select('*')
        .eq('person_id', personId)
        .order('created_at', { ascending: true })
        .limit(limit);
    if (error) throw error;
    return data || [];
}

export { rowToAxes };
