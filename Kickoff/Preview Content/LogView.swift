//
//  LogView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct LogView: View {
    @State private var q: String = ""
    @State private var results: [APIMatch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Rechercher une équipe / compé / joueur", text: $q)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: q) { _, _ in
                            searchTask?.cancel()
                            searchTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
                                await search()
                            }
                        }

                    Button { Task { await search() } } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .padding()

                if isLoading { ProgressView().padding() }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).padding() }

                List(results) { m in
                    NavigationLink { MatchDetailView(matchId: m.id, allowRating: true) } label: {
                        MatchRow(match: m)
                    }
                }
            }
            .navigationTitle("Log")
        }
    }

    @MainActor
    private func search() async {
        let term = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            results = try await APIClient.shared.searchMatches(query: term)
        } catch {
            errorMessage = "Recherche impossible."
        }
    }
}
