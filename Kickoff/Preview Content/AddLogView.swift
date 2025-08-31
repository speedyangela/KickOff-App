//
//  AddLogView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct AddLogView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var sport: String = ""
    @State private var date: Date = Date()
    @State private var home: String = ""
    @State private var away: String = ""
    @State private var competition: String = ""

    @State private var results: [APIMatch] = []
    @State private var selectedMatch: APIMatch?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var score: Double = 7.0
    @State private var review: String = ""
    @State private var posted = false

    var body: some View {
        NavigationView {
            Form {
                Section("Infos du match") {
                    Picker("Sport", selection: $sport) {
                        Text("—").tag("")
                        Text("football").tag("football")
                        Text("basketball").tag("basketball")
                        Text("tennis").tag("tennis")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Équipe domicile", text: $home)
                    TextField("Équipe extérieur", text: $away)
                    TextField("Compétition (optionnel)", text: $competition)

                    Button { Task { await search() } } label: {
                        Label("Chercher le match", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if isLoading { ProgressView("Recherche…") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }

                if !results.isEmpty {
                    Section("Résultats") {
                        ForEach(results) { m in
                            Button {
                                selectedMatch = m
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(m.home ?? "?") vs \(m.away ?? "?")").bold()
                                        Text(m.competition ?? m.sport.capitalized).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedMatch?.id == m.id {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Ta note") {
                    ScoreGauge(value: $score)
                    TextField("Ton avis (optionnel)", text: $review, axis: .vertical)
                }


                Section {
                    Button { Task { await submit() } } label: {
                        Label("Valider mon log", systemImage: "paperplane")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedMatch == nil) // 🔒 impossible de log si aucun match existant
                }
            }
            .navigationTitle("Ajouter un match")
        }
    }

    @MainActor
    private func search() async {
        isLoading = true; errorMessage = nil; posted = false
        defer { isLoading = false }
        do {
            results = try await APIClient.shared.searchMatchesAdvanced(
                sport: sport,
                date: date,
                home: home,
                away: away,
                competition: competition
            )
            if results.isEmpty {
                errorMessage = "Aucun match trouvé. Ajuste tes champs."
                selectedMatch = nil
            }
        } catch {
            errorMessage = "Recherche impossible."
        }
    }

    @MainActor
    private func submit() async {
        guard let m = selectedMatch else { return }
        do {
            try await APIClient.shared.postRating(
                matchId: m.id,
                score: score,
                review: review.isEmpty ? nil : review
            )
            posted = true
            await auth.registerLog(didWriteReview: !review.isEmpty)
            await auth.refreshBadges()

        } catch {
            errorMessage = "Envoi impossible."
        }
    }
}

