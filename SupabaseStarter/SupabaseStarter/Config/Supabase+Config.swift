import Foundation
import Supabase

// TODO: Replace with your Supabase project credentials
// Found in: Supabase Dashboard → Settings → API
enum SupabaseConfig {
    static let url = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY"
    static let redirectURL = URL(string: "supabasestarter://auth-callback")!
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
