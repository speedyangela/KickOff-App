//
//  ReviewStore.swift
//  Kickoff
//
//  Created by Angela Lagache on 03/09/2025.
//

import Foundation
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
            id: UUID(),
            createdAt: Date(),
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
            id: UUID(),
            createdAt: Date(),
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
