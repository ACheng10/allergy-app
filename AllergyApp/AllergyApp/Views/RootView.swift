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
        Group {
            if let profile = profiles.first {
                if profile.setupComplete {
                    MainTabView(profile: profile)
                } else {
                    NavigationStack {
                        ProfileEditorView(profile: profile, isOnboarding: true)
                    }
                }
            } else {
                // First launch: create the one profile row. Save straight away so
                // @Query sees it now instead of whenever SwiftData next autosaves
                // (that delay looked like a blank white screen).
                ProgressView("Setting up…")
                    .task {
                        let profile = AllergyProfile()
                        if DebugFlags.demo { DebugFlags.applyDemo(to: profile) }
                        context.insert(profile)
                        try? context.save()
                    }
            }
        }
        .task {
            if DebugFlags.demo, let profile = profiles.first {
                DebugFlags.applyDemo(to: profile)
                try? context.save()
            }
        }
    }
}

struct MainTabView: View {
    let profile: AllergyProfile
    @State private var tab = DebugFlags.startTab

    var body: some View {
        TabView(selection: $tab) {
            MyCardView(profile: profile)
                .tabItem { Label("My Card", systemImage: "person.text.rectangle") }
                .tag(0)
            NavigationStack { ConversationView(localeCode: profile.localeCode) }
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right") }
                .tag(1)
            EmergencyView(profile: profile)
                .tabItem { Label("Emergency", systemImage: "cross.case.fill") }
                .tag(2)
            NavigationStack { ProfileEditorView(profile: profile, isOnboarding: false) }
                .tabItem { Label("Profile", systemImage: "gearshape") }
                .tag(3)
        }
    }
}
