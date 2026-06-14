import { supabase } from '../supabaseClient.js';

export async function getSettings(user_id) {
    const { data, error } = await supabase
        .from('user_settings')
        .select('*')
        .eq('user_id', user_id)
        .single();
    if (error && error.code !== 'PGRST116') throw error;
    return data;
}

export async function ensureSettings(user_id) {
    const existing = await getSettings(user_id);
    if (existing) return existing;
    const { data, error } = await supabase
        .from('user_settings')
        .insert({ user_id })
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function updateSettings(user_id, patch) {
    const { data, error } = await supabase
        .from('user_settings')
        .update(patch)
        .eq('user_id', user_id)
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function ensureProfile(user_id, email) {
    const { data: existing } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user_id)
        .single();
    if (existing) return existing;
    const fallback = (email || `user-${user_id.slice(0, 8)}`).split('@')[0];
    const { data, error } = await supabase
        .from('profiles')
        .insert({ id: user_id, username: `${fallback}-${user_id.slice(0, 4)}` })
        .select()
        .single();
    if (error) throw error;
    return data;
}
