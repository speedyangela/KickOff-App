//
//  MatchDetailView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct MatchDetailView: View {
    let matchId: Int
    var allowRating: Bool = false

    @State private var detail: APIMatchDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var myScore: Double = 7.0
    @State private var myReview: String = ""
    @State private var posted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading { ProgressView("Chargement…") }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            if let d = detail {
                Text(d.competition ?? d.sport.capitalized).font(.caption).foregroundStyle(.secondary)
                Text("\(d.home ?? "?") vs \(d.away ?? "?")").font(.title2).bold()
                if let s = d.score { Text("\(s.home ?? 0) - \(s.away ?? 0)").font(.title2) }
                Text(isLive(d) ? "En direct • \(d.status)"
                               : d.start_time.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)

                if let r = d.ratings {
                    HStack(spacing: 8) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        Text(String(format: "%.1f", r.avg)).bold()
                        Text("• \(r.count) notes").foregroundStyle(.secondary)
                    }
                }

                if allowRating {
                    Divider().padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ta note (0–10)").bold()
                        Slider(value: $myScore, in: 0...10, step: 0.5)
                            .tint(Color(hue: myScore / 10 * 0.33, saturation: 0.9, brightness: 0.9))
                        Text(String(format: "Note: %.1f", myScore))

                        TextField("Ton avis (optionnel)", text: $myReview, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task { await rate() }
                        } label: {
                            Label(posted ? "Noté ✔︎" : "Envoyer la note",
                                  systemImage: posted ? "checkmark.circle" : "paperplane")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(posted)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Détail du match")
        .task { await load() }
    }

    private func isLive(_ d: APIMatchDetail) -> Bool {
        ["LIVE","1H","2H","Q1","Q2","Q3","Q4","OT","ET","In Progress"].contains(d.status)
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await APIClient.shared.fetchMatchDetail(id: matchId)
        } catch {
            errorMessage = "Impossible de charger le match."
        }
    }

    @MainActor
    private func rate() async {
        do {
            try await APIClient.shared.postRating(
                matchId: matchId,
                score: myScore,
                review: myReview.isEmpty ? nil : myReview
            )
            posted = true
            await load()
        } catch {
            errorMessage = "Envoi de la note impossible."
        }
    }
}
