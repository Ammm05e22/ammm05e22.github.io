import { supabase } from '../supabaseClient.js';

export async function getLatestWeeklySummary(personId) {
    const { data, error } = await supabase
        .from('weekly_summaries')
        .select('*')
        .eq('person_id', personId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
    if (error) throw error;
    return data;
}

export async function upsertWeeklySummary({ user_id, person_id, iso_week, payload }) {
    const { data, error } = await supabase
        .from('weekly_summaries')
        .upsert({ user_id, person_id, iso_week, payload }, { onConflict: 'person_id,iso_week' })
        .select()
        .single();
    if (error) throw error;
    return data;
}
