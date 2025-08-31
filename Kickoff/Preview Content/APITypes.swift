//
//  APITypes.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import Foundation

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

    // Image d'avatar stockée localement (mock) en Base64 PNG
    var avatarPNGBase64: String? = nil
}
