import { supabase } from '../supabaseClient.js';
import { defaultAxes, axesToRow } from '../lib/scoring.js';

export async function listPeople() {
    const { data, error } = await supabase
        .from('people')
        .select('*')
        .eq('archived', false)
        .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
}

export async function getPerson(id) {
    const { data, error } = await supabase
        .from('people')
        .select('*')
        .eq('id', id)
        .single();
    if (error) throw error;
    return data;
}

export async function createPerson({ user_id, display_name, relationship_type, notes }) {
    const { data, error } = await supabase
        .from('people')
        .insert({ user_id, display_name, relationship_type, notes })
        .select()
        .single();
    if (error) throw error;
    // Seed scores row at 50.
    const axes = defaultAxes();
    const { error: scoreErr } = await supabase.from('scores').insert({
        person_id: data.id,
        user_id,
        ...axesToRow(axes),
        composite: 50,
        status: 'Watchlist',
    });
    if (scoreErr) throw scoreErr;
    return data;
}

export async function updatePerson(id, patch) {
    const { data, error } = await supabase
        .from('people')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function archivePerson(id) {
    return updatePerson(id, { archived: true });
}
