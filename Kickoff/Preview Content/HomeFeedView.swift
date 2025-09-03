//
//  HomeFeedView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct HomeFeedView: View {
    @State private var live: [APIMatch] = []
    @State private var trending: [APITrendingMatch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            List {
                if !live.isEmpty {
                    Section("En direct") {
                        ForEach(live) { m in
                            // En direct
                            NavigationLink { MatchDetailView(matchId: m.id, allowRating: true) } label: {
                                MatchRow(match: m)
                            }
                        }
                    }
                }
                if !trending.isEmpty {
                    Section("Tendance (dernières 72h)") {
                        ForEach(trending) { tm in
                            NavigationLink { MatchDetailView(matchId: tm.id, allowRating: true) } label: {
                                TrendingRow(match: tm)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accueil")
            .overlay { if isLoading { ProgressView("Chargement…") } }
            .task { await load() }
            .refreshable { await load() }
            .alert("Oups", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Une erreur inconnue est survenue.")
            }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            let feed = try await APIClient.shared.fetchFeed(limit: 20)
            withAnimation {
                live = feed.live
                trending = feed.trending
            }
            errorMessage = nil
            showError = false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
    }
}

