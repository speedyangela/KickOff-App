//
//  KickoffApp.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//
import SwiftUI

@main
struct KickoffApp: App {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var reviews = ReviewsStore.shared
    @State private var showSplash = true

    init() {
        // On reste en mock (aucun serveur requis)
        APIClient.shared.env = .mock
        APIClient.shared.baseURL = URL(string: "https://example.com")! // ignoré en mock
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // --- Ton app "comme avant" ---
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
                            Image(systemName: "plus.circle")   // <- parenthèse corrigée
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
                .environmentObject(auth)
                .environmentObject(reviews)
                .opacity(showSplash ? 0 : 1) // petite fondu d’entrée

                // --- Splash animé par-dessus au lancement ---
                if showSplash {
                    KickoffSplashView {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}
