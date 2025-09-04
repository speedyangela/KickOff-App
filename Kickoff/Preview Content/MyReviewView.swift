//
//  MyReviewView.swift
//  Kickoff
//
//  Created by Angela Lagache on 03/09/2025.
//

import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject var reviews: ReviewsStore

    var body: some View {
        Group {
            if reviews.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Aucune review pour l’instant")
                        .font(.headline)
                    Text("Ajoute un log depuis l’onglet “Ajouter un match”.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(reviews.items) { r in
                        NavigationLink {
                            MatchDetailView(matchId: r.matchId, allowRating: true)
                        } label: {
                            ReviewRowView(r: r)
                        }
                    }
                    .onDelete(perform: reviews.delete)
                }
                .listStyle(.insetGrouped)
                .toolbar { EditButton() }
            }
        }
    }
}

struct ReviewRowView: View {
    let r: LocalReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête
            HStack(alignment: .firstTextBaseline) {
                Text(r.competition ?? r.sport.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ScorePill(score: r.score)
            }

            // Match
            Text("\(r.home ?? "?") vs \(r.away ?? "?")")
                .font(.headline)


            // Date
            Text(r.start_time.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            // Review
            if let review = r.review, !review.isEmpty {
                Text(review)
                    .font(.subheadline)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ScorePill: View {
    let score: Double
    var body: some View {
        Text(String(format: "%.1f /10", score))
            .font(.caption).bold().monospacedDigit()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(color(for: score).opacity(0.18))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color(for: score).opacity(0.55), lineWidth: 1)
            )
    }

    private func color(for v: Double) -> Color {
        let f = max(0, min(1, v / 10.0))
        return Color(hue: 0.33 * f, saturation: 0.95, brightness: 0.95) // rouge→vert
    }
}

