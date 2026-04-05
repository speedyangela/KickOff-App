//
//  APITypes.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import Foundation
import SwiftUI

// ===== Modèles API =====

struct APIScore: Codable {
    let home: Int?
    let away: Int?
}

struct APIRatingsSummary: Codable {
    let avg: Double
    let count: Int
}

struct APIMatch: Codable, Identifiable {
    let id: Int
    let sport: String
    let competition: String?
    let start_time: Date
    let status: String
    let home: String?
    let away: String?
    let score: APIScore?
}

struct APITrendingMatch: Codable, Identifiable {
    let id: Int
    let sport: String
    let competition: String?
    let start_time: Date
    let status: String
    let home: String?
    let away: String?
    let score: APIScore?
    let ratings: APIRatingsSummary
}

struct APIMatchDetail: Codable, Identifiable {
    let id: Int
    let sport: String
    let competition: String?
    let start_time: Date
    let status: String
    let home: String?
    let away: String?
    let score: APIScore?
    let ratings: APIRatingsSummary?
}

struct APIFeedResponse: Codable {
    let live: [APIMatch]
    let trending: [APITrendingMatch]
}

struct APIPostRatingRequest: Codable {
    let user_id: UUID
    let match_id: Int
    let score_0_10: Double
    let review: String?
}

// ===== Décodeur ISO8601 (Swift 6 safe) =====

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)

            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let dt = f1.date(from: s) { return dt }

            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let dt = f2.date(from: s) { return dt }

            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid ISO8601 date: \(s)")
        }
        return d
    }
}

// ===== Utilisateur =====

struct APIUserStats: Codable {
    var logsCount: Int
    var reviewsCount: Int
    var badges: [String]
}

struct APIUser: Codable, Identifiable {
    let id: UUID
    var username: String
    var email: String
    var bio: String?
    var stats: APIUserStats

    // Nouveaux champs (mock)
    var countryCode: String?        // ex: "FR"
    var sportsWatched: [String]?    // ex: ["football","basketball","tennis"]
    var favorites: [String]?        // ex: ["PSG","Messi","OL"] (max 5)

    // Image d'avatar (mock)
    var avatarPNGBase64: String? = nil
}

// ===== Review locale (mock) =====

/// Réponse sous une review (débats / fils de discussion) — prêt pour usage futur.
struct ReviewReply: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let createdAt: Date
    var authorUsername: String?
    var body: String
}

struct LocalReview: Codable, Identifiable {
    let id: UUID
    let createdAt: Date

    // match
    let matchId: Int
    let sport: String
    let competition: String?
    let start_time: Date
    let home: String?
    let away: String?

    // user rating
    let score: Double
    let review: String?

    /// Tags extraits du texte (sans « # », normalisés en minuscules).
    let hashtags: [String]

    /// Fil de réponses (mock / futur réseau social).
    var replies: [ReviewReply]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        matchId: Int,
        sport: String,
        competition: String?,
        start_time: Date,
        home: String?,
        away: String?,
        score: Double,
        review: String?,
        hashtags: [String]? = nil,
        replies: [ReviewReply] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.matchId = matchId
        self.sport = sport
        self.competition = competition
        self.start_time = start_time
        self.home = home
        self.away = away
        self.score = score
        self.review = review
        self.hashtags = hashtags ?? HashtagParser.hashtags(in: review)
        self.replies = replies
    }

    enum CodingKeys: String, CodingKey {
        case id, createdAt, matchId, sport, competition, start_time, home, away, score, review
        case hashtags, replies
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        matchId = try c.decode(Int.self, forKey: .matchId)
        sport = try c.decode(String.self, forKey: .sport)
        competition = try c.decodeIfPresent(String.self, forKey: .competition)
        start_time = try c.decode(Date.self, forKey: .start_time)
        home = try c.decodeIfPresent(String.self, forKey: .home)
        away = try c.decodeIfPresent(String.self, forKey: .away)
        score = try c.decode(Double.self, forKey: .score)
        let decodedReview = try c.decodeIfPresent(String.self, forKey: .review)
        review = decodedReview
        hashtags = try c.decodeIfPresent([String].self, forKey: .hashtags)
            ?? HashtagParser.hashtags(in: decodedReview)
        replies = try c.decodeIfPresent([ReviewReply].self, forKey: .replies) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(matchId, forKey: .matchId)
        try c.encode(sport, forKey: .sport)
        try c.encodeIfPresent(competition, forKey: .competition)
        try c.encode(start_time, forKey: .start_time)
        try c.encodeIfPresent(home, forKey: .home)
        try c.encodeIfPresent(away, forKey: .away)
        try c.encode(score, forKey: .score)
        try c.encodeIfPresent(review, forKey: .review)
        try c.encode(hashtags, forKey: .hashtags)
        try c.encode(replies, forKey: .replies)
    }
}

// MARK: - Hashtags

enum HashtagParser {
    /// Extraire les hashtags (sans le « # », minuscules, ordre d’apparition, uniques).
    static func hashtags(in text: String?) -> [String] {
        guard let text, !text.isEmpty else { return [] }
        var seen = Set<String>()
        var out: [String] = []
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "#" {
                var j = text.index(after: i)
                while j < text.endIndex, isTagChar(text[j]) {
                    j = text.index(after: j)
                }
                if j > text.index(after: i) {
                    let raw = String(text[text.index(after: i)..<j]).lowercased()
                    if seen.insert(raw).inserted { out.append(raw) }
                    i = j
                    continue
                }
            }
            i = text.index(after: i)
        }
        return out
    }

    private static func isTagChar(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "_"
    }

    /// Texte avec #hashtags en accentColor ; `linksEnabled` ajoute des liens `kickoff://hashtag/…`.
    static func attributedReview(_ text: String, linksEnabled: Bool) -> AttributedString {
        var result = AttributedString()
        var i = text.startIndex
        while i < text.endIndex {
            if text[i] == "#" {
                var j = text.index(after: i)
                while j < text.endIndex, isTagChar(text[j]) {
                    j = text.index(after: j)
                }
                if j > text.index(after: i) {
                    let display = String(text[i..<j])
                    let tagKey = String(text[text.index(after: i)..<j]).lowercased()
                    var seg = AttributedString(display)
                    seg.foregroundColor = .accentColor
                    if linksEnabled, let url = URL(string: "kickoff://hashtag/\(tagKey)") {
                        seg.link = url
                    }
                    result += seg
                    i = j
                    continue
                }
            }
            let next = text.index(after: i)
            result += AttributedString(String(text[i..<next]))
            i = next
        }
        return result
    }

    static func tag(from url: URL) -> String? {
        guard url.scheme == "kickoff", url.host == "hashtag" else { return nil }
        let p = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return p.isEmpty ? nil : p.lowercased()
    }
}
