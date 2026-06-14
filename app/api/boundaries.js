import { supabase } from '../supabaseClient.js';

export async function listBoundaries(user_id) {
    const { data, error } = await supabase
        .from('boundaries')
        .select('*')
        .eq('user_id', user_id)
        .order('sort_order', { ascending: true });
    if (error) throw error;
    return data || [];
}

export async function createBoundary({ user_id, text, sort_order }) {
    const { data, error } = await supabase
        .from('boundaries')
        .insert({ user_id, text, sort_order: sort_order ?? 0 })
        .select()
        .single();
    if (error) throw error;
    return data;
}

export async function deleteBoundary(id) {
    const { error } = await supabase.from('boundaries').delete().eq('id', id);
    if (error) throw error;
}
