import Foundation

// TODO: Replace with your AI server base URL.
// Server must expose POST /analyze-entry and POST /weekly-summary,
// accept Authorization: Bearer <supabase access token>, and proxy to OpenAI.
enum AIServerConfig {
    static let baseURL = URL(string: "https://YOUR_AI_SERVER.example.com")!
}
