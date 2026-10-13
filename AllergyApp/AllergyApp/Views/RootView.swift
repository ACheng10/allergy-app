import SwiftData
import SwiftUI

/// Decides what to show: first-run setup, or the main tabs.
struct RootView: View {
    @Environment(\.modelContext) private var context

    // SQL analogy: SELECT * FROM AllergyProfile ORDER BY createdAt.
    // @Query re-runs by itself whenever the table changes, and the screen
    // redraws. If iCloud ever syncs two profiles in, the oldest one wins.
    @Query(sort: \AllergyProfile.createdAt) private var profiles: [AllergyProfile]

    var body: some View {
        if let profile = profiles.first {
            if profile.setupComplete {
                MainTabView(profile: profile)
            } else {
                NavigationStack {
                    ProfileEditorView(profile: profile, isOnboarding: true)
                }
            }
        } else {
            ProgressView()
                .onAppear { context.insert(AllergyProfile()) }
        }
    }
}

struct MainTabView: View {
    let profile: AllergyProfile

    var body: some View {
        TabView {
            MyCardView(profile: profile)
                .tabItem { Label("My Card", systemImage: "person.text.rectangle") }
            NavigationStack { ConversationView(localeCode: profile.localeCode) }
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right") }
            EmergencyView(profile: profile)
                .tabItem { Label("Emergency", systemImage: "cross.case.fill") }
            NavigationStack { ProfileEditorView(profile: profile, isOnboarding: false) }
                .tabItem { Label("Profile", systemImage: "gearshape") }
        }
    }
}
