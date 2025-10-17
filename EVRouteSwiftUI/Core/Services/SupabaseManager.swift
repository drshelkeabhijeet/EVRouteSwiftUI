import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Replace with your Supabase project URL and anon key
        let url = URL(string: "https://byiaqbsphndmbtaeevkt.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5aWFxYnNwaG5kbWJ0YWVldmt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNzUyNDksImV4cCI6MjA2ODc1MTI0OX0.2fS_Zc5GED1WV3FN4nB4H3lrPuMBxXcDF9P3V3wNQdo"
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
