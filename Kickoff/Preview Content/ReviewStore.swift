//
//  ReviewStore.swift
//  Kickoff
//
//  Created by Angela Lagache on 03/09/2025.
//

import Foundation
import SwiftUI

final class ReviewsStore: ObservableObject {
    static let shared = ReviewsStore()

    @Published private(set) var items: [LocalReview] = []

    private let defaults = UserDefaults.standard
    private let key = "kickoff_reviews_v1"

    private init() {
        load()
    }

    // MARK: - Public

    func add(from match: APIMatch, score: Double, review: String?) {
        let item = LocalReview(
            matchId: match.id,
            sport: match.sport,
            competition: match.competition,
            start_time: match.start_time,
            home: match.home,
            away: match.away,
            score: score,
            review: (review?.isEmpty ?? true) ? nil : review
        )
        items.insert(item, at: 0)
        save()
    }

    func add(from detail: APIMatchDetail, score: Double, review: String?) {
        let item = LocalReview(
            matchId: detail.id,
            sport: detail.sport,
            competition: detail.competition,
            start_time: detail.start_time,
            home: detail.home,
            away: detail.away,
            score: score,
            review: (review?.isEmpty ?? true) ? nil : review
        )
        items.insert(item, at: 0)
        save()
    }

    func reviews(matchingHashtag rawTag: String) -> [LocalReview] {
        let tag = rawTag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return [] }
        return items.filter { $0.hashtags.contains(tag) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Préparation débats : ajoute une réponse locale sous une review.
    func addReply(to reviewId: UUID, authorUsername: String?, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let i = items.firstIndex(where: { $0.id == reviewId })
        else { return }
        var r = items[i]
        let reply = ReviewReply(id: UUID(), createdAt: Date(), authorUsername: authorUsername, body: trimmed)
        r.replies.append(reply)
        items[i] = r
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func removeAll() {
        items.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        if let arr = try? JSONDecoder().decode([LocalReview].self, from: data) {
            items = arr
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }
}
