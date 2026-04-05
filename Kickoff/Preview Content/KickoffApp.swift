//
//  KickoffApp.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//
import SwiftUI

@main
struct KickoffApp: App {
    @AppStorage("hasCompletedLanguageOnboarding") private var hasCompletedLanguageOnboarding = false
    @AppStorage("appPreferredLanguage") private var appPreferredLanguage = ""

    @StateObject private var auth = AuthManager.shared
    @StateObject private var reviews = ReviewsStore.shared
    @State private var showSplash = true
    @State private var selectedMainTab: MainTab = .home
    @State private var showAddLogSheet = false

    init() {
        // On reste en mock (aucun serveur requis)
        APIClient.shared.env = .mock
        APIClient.shared.baseURL = URL(string: "https://example.com")! // ignoré en mock
    }

    private var appLocale: Locale {
        guard hasCompletedLanguageOnboarding else { return .current }
        let id = appPreferredLanguage.isEmpty ? Locale.current.identifier : appPreferredLanguage
        return Locale(identifier: id)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedLanguageOnboarding {
                    ZStack {
                        MainTabShell(
                            selectedTab: $selectedMainTab,
                            showAddLogSheet: $showAddLogSheet
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(showSplash ? 0 : 1) // petite fondu d’entrée
                        .sheet(isPresented: $showAddLogSheet) {
                            AddLogView()
                                .environmentObject(auth)
                                .environmentObject(reviews)
                        }

                        if showSplash {
                            KickoffSplashView {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showSplash = false
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                } else {
                    OnboardingView()
                }
            }
            .environment(\.locale, appLocale)
            .environmentObject(auth)
            .environmentObject(reviews)
        }
    }
}

// MARK: - Shell navigation (4 onglets + bouton central)

private enum MainTab: Hashable {
    case home
    case sports
    case live
    case profile
}

private struct MainTabShell: View {
    @Binding var selectedTab: MainTab
    @Binding var showAddLogSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeFeedView()
                case .sports:
                    SportsView()
                case .live:
                    DirectView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MainTabBar(selectedTab: $selectedTab, showAddLogSheet: $showAddLogSheet)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct MainTabBar: View {
    @Binding var selectedTab: MainTab
    @Binding var showAddLogSheet: Bool

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.home, systemImage: "house", titleKey: "tab.home")
            tabItem(.sports, systemImage: "sportscourt", titleKey: "tab.sports")

            Color.clear
                .frame(maxWidth: .infinity)
                .overlay {
                    Button {
                        showAddLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .offset(y: -18)
                    .accessibilityLabel(Text(LocalizedStringKey("tab.add")))
                }

            tabItem(.live, systemImage: "bolt.horizontal.circle", titleKey: "tab.live")
            tabItem(.profile, systemImage: "person", titleKey: "tab.profile")
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 6)
        .background(.bar)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
        .overlay(alignment: .top) {
            Divider()
                .opacity(0.35)
        }
    }

    @ViewBuilder
    private func tabItem(_ tab: MainTab, systemImage: String, titleKey: LocalizedStringKey) -> some View {
        let isSelected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(titleKey)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
