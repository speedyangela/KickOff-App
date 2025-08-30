//
//  SportsView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct SportsView: View {
    private let sports = [("football","soccerball"), ("basketball","basketball"), ("tennis","tennis.racket")]

    var body: some View {
        NavigationView {
            List {
                ForEach(sports, id: \.0) { (code, icon) in
                    NavigationLink {
                        SportMatchesListView(sport: code)
                    } label: {
                        Label(code.capitalized, systemImage: icon)
                    }
                }
            }
            .navigationTitle("Sports")
        }
    }
}

struct SportMatchesListView: View {
    let sport: String
    @State private var q: String = ""
    @State private var results: [APIMatch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                TextField("Rechercher une équipe / compé", text: $q)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await search() } }
                Button { Task { await search() } } label: {
                    Label("Rechercher", systemImage: "magnifyingglass")
                }
            }
            if isLoading { ProgressView() }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            ForEach(results) { m in
                NavigationLink { MatchDetailView(matchId: m.id) } label: {
                    MatchRow(match: m)
                }
            }
        }
        .navigationTitle(sport.capitalized)
        .task { await search() }
    }

    @MainActor
    private func search() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            results = try await APIClient.shared.searchMatchesAdvanced(
                sport: sport,
                date: nil,
                home: q.isEmpty ? nil : q,
                away: nil,
                competition: q.isEmpty ? nil : q
            )
        } catch {
            errorMessage = "Recherche impossible."
        }
    }
}

