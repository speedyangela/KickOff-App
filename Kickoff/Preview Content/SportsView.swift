//
//  SportsView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct SportsView: View {
    private let sports: [(code: String, label: String, icon: String, colors: [Color])] = [
        ("football","Football","soccerball",[.green,.mint]),
        ("basketball","Basketball","basketball",[.orange,.red]),
        ("tennis","Tennis","tennis.racket",[.yellow,.green])
    ]
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sports, id: \.code) { s in
                        NavigationLink {
                            SportMatchesListView(sport: s.code)
                        } label: {
                            SportCard(title: s.label, icon: s.icon, colors: s.colors)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Sports")
        }
    }
}

private struct SportCard: View {
    let title: String
    let icon: String
    let colors: [Color]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)

            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)

                Text(title)
                    .font(.headline).bold()
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 140)
    }
}

// Liste par sport (inchangée sauf titre)
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
                NavigationLink { MatchDetailView(matchId: m.id, allowRating: true) } label: {
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
                competition: nil
            )
        } catch {
            errorMessage = "Recherche impossible."
        }
    }
}
