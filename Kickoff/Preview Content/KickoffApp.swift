//
//  KickoffApp.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//
import SwiftUI

@main
struct KickoffApp: App {

    init() {
        // On reste en mock (aucun serveur requis)
        APIClient.shared.env = .mock
        APIClient.shared.baseURL = URL(string: "https://example.com")! // ignoré en mock
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeFeedView()
                    .tabItem {
                        Image(systemName: "house")
                        Text(LocalizedStringKey("tab.home"))
                    }

                SportsView()
                    .tabItem {
                        Image(systemName: "sportscourt")
                        Text(LocalizedStringKey("tab.sports"))
                    }

                AddLogView()
                    .tabItem {
                        Image(systemName: "plus.circle")
                        Text(LocalizedStringKey("tab.add"))
                    }

                DirectView()
                    .tabItem {
                        Image(systemName: "bolt.horizontal.circle")
                        Text(LocalizedStringKey("tab.live"))
                    }

                ProfileView()
                    .tabItem {
                        Image(systemName: "person")
                        Text(LocalizedStringKey("tab.profile"))
                    }
            }
            .environmentObject(AuthManager.shared) // ⬅️ injection
        }
    }
}
