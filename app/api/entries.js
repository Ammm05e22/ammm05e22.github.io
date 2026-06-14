import { supabase } from '../supabaseClient.js';

export async function createEntry({ user_id, person_id, raw_text, occurred_at }) {
    const { data, error } = await supabase
        .from('entries')
        .insert({
            user_id,
            person_id,
            raw_text,
            occurred_at: occurred_at || new Date().toISOString(),
        })
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function listEntriesByPerson(personId, limit = 50) {
    const { data, error } = await supabase
        .from('entries')
        .select('*')
        .eq('person_id', personId)
        .order('occurred_at', { ascending: false })
        .limit(limit);
    if (error) throw error;
    return data || [];
}

export async function listRecentEntriesByPerson(personId, limit = 10) {
    return listEntriesByPerson(personId, limit);
}
