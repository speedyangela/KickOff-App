//
//  Badges.swift
//  Kickoff
//
//  Created by Angela Lagache on 31/08/2025.
//

import SwiftUI

// MARK: - Modèle & catalogue

enum BadgeKind: String, Codable { case logs, reviews }

struct Badge: Identifiable, Hashable {
    var id: String { "\(kind.rawValue)-\(threshold)" }
    let kind: BadgeKind
    let threshold: Int
    let title: String
    let icon: String       // SF Symbol
    let color: Color
    let note: String       // petit sous-titre

    static func logs(_ t: Int, _ title: String, _ icon: String, _ color: Color, note: String) -> Badge {
        .init(kind: .logs, threshold: t, title: title, icon: icon, color: color, note: note)
    }
    static func reviews(_ t: Int, _ title: String, _ icon: String, _ color: Color, note: String) -> Badge {
        .init(kind: .reviews, threshold: t, title: title, icon: icon, color: color, note: note)
    }
}

enum BadgeCatalog {
    // Seuils LOGS
    static let logs: [Badge] = [
        .logs(5,   "Rookie",        "figure.run.circle.fill", .blue,   note: "5 logs"),
        .logs(10,  "Titulaire",     "sportscourt",            .teal,   note: "10 logs"),
        .logs(20,  "Capitaine",     "person.3.fill",          .indigo, note: "20 logs"),
        .logs(50,  "Ultra",         "flag.checkered.2.crossed", .orange, note: "50 logs"),
        .logs(100, "All-Star",      "star.fill",              .yellow, note: "100 logs"),
        .logs(200, "Légende",       "trophy.fill",            .pink,   note: "200 logs"),
        .logs(500, "Hall of Fame",  "crown.fill",             .purple, note: "500 logs")
    ]
    // Seuils REVIEWS (avis écrits)
    static let reviews: [Badge] = [
        .reviews(5,   "Chroniqueur",  "text.bubble.fill", .mint,    note: "5 reviews"),
        .reviews(10,  "Commentateur", "mic.fill",         .cyan,    note: "10 reviews"),
        .reviews(20,  "Analyste",     "brain.head.profile", .blue,  note: "20 reviews"),
        .reviews(50,  "Tacticien",    "square.grid.3x3.fill", .indigo, note: "50 reviews"),
        .reviews(100, "Stratège",     "target",           .orange,  note: "100 reviews"),
        .reviews(200, "Professeur",   "book.fill",        .pink,    note: "200 reviews")
    ]

    static let all: [Badge] = logs + reviews
}

enum BadgeEngine {
    /// IDs des badges débloqués pour des stats données
    static func unlockedBadgeIDs(for stats: APIUserStats) -> Set<String> {
        var ids = Set<String>()
        for b in BadgeCatalog.logs where stats.logsCount >= b.threshold { ids.insert(b.id) }
        for b in BadgeCatalog.reviews where stats.reviewsCount >= b.threshold { ids.insert(b.id) }
        return ids
    }
}

// MARK: - Vue Grille

struct ProfileBadgesView: View {
    @EnvironmentObject var auth: AuthManager

    private let cols = [GridItem(.adaptive(minimum: 110), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(BadgeCatalog.all) { badge in
                    BadgeCard(badge: badge, unlocked: isUnlocked(badge))
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
        .onAppear { Task { await auth.refreshBadges() } }
    }

    private func isUnlocked(_ b: Badge) -> Bool {
        guard let user = auth.currentUser else { return false }
        return user.stats.badges.contains(b.id)
    }
}

struct BadgeCard: View {
    let badge: Badge
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badge.color.gradient)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: badge.color.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: badge.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            .saturation(unlocked ? 1 : 0)  // grisé si verrouillé
            .opacity(unlocked ? 1 : 0.45)

            Text(badge.title)
                .font(.subheadline).bold()
                .multilineTextAlignment(.center)
            Text(badge.note)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !unlocked {
                Label("Verrouillé", systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Label("Obtenu", systemImage: "checkmark.seal.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
}
