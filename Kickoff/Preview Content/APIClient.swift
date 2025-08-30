//
//  APIClient.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import Foundation

final class APIClient {
    static let shared = APIClient()

    enum APIEnv { case mock, live }
    var env: APIEnv = .mock            // ← mets .live quand ton backend est prêt

    let session = URLSession.shared
    var baseURL = URL(string: "https://api.example.com")!   // ← remplace par ton domaine

    private init() {}
}

// MARK: - Public API

extension APIClient {

    // Feed (live + trending)
    func fetchFeed(limit: Int) async throws -> APIFeedResponse {
        if env == .mock { return try await Mock.fetchFeed(limit: limit) }

        let items = [URLQueryItem(name: "limit", value: String(limit))]
        return try await request("feed", query: items, method: "GET", body: Optional<Data>.none)
    }

    // Recherche simple par texte
    func searchMatches(query: String) async throws -> [APIMatch] {
        if env == .mock { return try await Mock.searchMatches(query: query) }

        let items = [URLQueryItem(name: "q", value: query)]
        return try await request("matches/search", query: items, method: "GET", body: Optional<Data>.none)
    }

    // Recherche avancée (ET logique)
    func searchMatchesAdvanced(
        sport: String?,
        date: Date?,
        home: String?,
        away: String?,
        competition: String?
    ) async throws -> [APIMatch] {
        if env == .mock {
            return try await Mock.searchMatchesAdvanced(sport: sport, date: date, home: home, away: away, competition: competition)
        }

        var items: [URLQueryItem] = []
        if let sport, !sport.isEmpty { items.append(.init(name: "sport", value: sport)) }
        if let date {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            items.append(.init(name: "date", value: df.string(from: date)))
        }
        if let home, !home.isEmpty { items.append(.init(name: "home", value: home)) }
        if let away, !away.isEmpty { items.append(.init(name: "away", value: away)) }
        if let competition, !competition.isEmpty { items.append(.init(name: "competition", value: competition)) }

        return try await request("matches", query: items, method: "GET", body: Optional<Data>.none)
    }

    // Détail d’un match
    func fetchMatchDetail(id: Int) async throws -> APIMatchDetail {
        if env == .mock { return try await Mock.fetchMatchDetail(id: id) }
        return try await request("matches/\(id)", method: "GET", body: Optional<Data>.none)
    }

    // Poster une note/avis
    func postRating(matchId: Int, score: Double, review: String?) async throws {
        if env == .mock { return try await Mock.postRating(matchId: matchId, score: score, review: review) }

        let payload = APIPostRatingRequest(
            user_id: UUID(),          // remplace par ton vrai user_id si tu l’as
            match_id: matchId,
            score_0_10: score,
            review: review
        )
        try await requestVoid("ratings", method: "POST", jsonBody: payload)
    }
}

// MARK: - Low-level HTTP

private extension APIClient {
    func request<T: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        if let body { req.httpBody = body }
        if body != nil { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }

        let (data, resp) = try await session.data(for: req)
        try validate(resp: resp, data: data)
        let decoder = JSONDecoder.iso8601
        return try decoder.decode(T.self, from: data)
    }

    func request<T: Decodable, E: Encodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        method: String,
        jsonBody: E
    ) async throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(jsonBody)
        return try await request(path, query: query, method: method, body: data)
    }

    func requestVoid<E: Encodable>(
        _ path: String,
        method: String,
        jsonBody: E
    ) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(jsonBody)
        _ = try await request(path, method: method, body: data) as APIPostRatingRequest? // decode rien → juste pour réutiliser validate
    }

    func validate(resp: URLResponse, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "APIError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"])
        }
    }
}

// MARK: - Mock (identique à ce que tu avais)

private enum Mock {
    static func fetchFeed(limit: Int) async throws -> APIFeedResponse {
        try await Task.sleep(nanoseconds: 200_000_000)
        let all = MockData.matches
        let live = all.filter { ["LIVE","1H","2H","Q1","Q2","Q3","Q4","OT","ET","In Progress"].contains($0.status) }
        let trending = all.prefix(10).map {
            APITrendingMatch(id: $0.id, sport: $0.sport, competition: $0.competition, start_time: $0.start_time, status: $0.status, home: $0.home, away: $0.away, score: $0.score, ratings: APIRatingsSummary(avg: 7.6, count: 132))
        }
        return APIFeedResponse(live: Array(live.prefix(limit)), trending: Array(trending.prefix(limit)))
    }

    static func searchMatches(query: String) async throws -> [APIMatch] {
        try await Task.sleep(nanoseconds: 150_000_000)
        let q = query.lowercased()
        return MockData.matches.filter {
            ($0.home ?? "").lowercased().contains(q) ||
            ($0.away ?? "").lowercased().contains(q) ||
            ($0.competition ?? "").lowercased().contains(q)
        }
    }

    static func searchMatchesAdvanced(sport: String?, date: Date?, home: String?, away: String?, competition: String?) async throws -> [APIMatch] {
        try await Task.sleep(nanoseconds: 150_000_000)
        var res = MockData.matches
        if let sport, !sport.isEmpty { res = res.filter { $0.sport == sport } }
        if let date {
            let cal = Calendar.current
            res = res.filter { cal.isDate($0.start_time, inSameDayAs: date) }
        }
        if let home, !home.isEmpty { res = res.filter { ($0.home ?? "").localizedCaseInsensitiveContains(home) } }
        if let away, !away.isEmpty { res = res.filter { ($0.away ?? "").localizedCaseInsensitiveContains(away) } }
        if let competition, !competition.isEmpty { res = res.filter { ($0.competition ?? "").localizedCaseInsensitiveContains(competition) } }
        return res
    }

    static func fetchMatchDetail(id: Int) async throws -> APIMatchDetail {
        try await Task.sleep(nanoseconds: 120_000_000)
        let base = MockData.matches.first { $0.id == id }!
        return APIMatchDetail(
            id: base.id,
            sport: base.sport,
            competition: base.competition,
            start_time: base.start_time,
            status: base.status,
            home: base.home,
            away: base.away,
            score: base.score,
            ratings: APIRatingsSummary(avg: 7.8, count: 254)
        )
    }

    static func postRating(matchId: Int, score: Double, review: String?) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
    }
}

// MARK: - Mock data (inchangé)

enum MockData {
    static let matches: [APIMatch] = {
        let now = Date()
        let comps: [(Int,String,String,String?,String?,APIScore?,String)] = [
            (1,"football","Ligue 1","PSG","OM",APIScore(home: 2, away: 1),"FT"),
            (2,"football","Premier League","Arsenal","Chelsea",APIScore(home: 1, away: 1),"FT"),
            (3,"basketball","NBA","Lakers","Warriors",APIScore(home: 88, away: 91),"Q3"),
            (4,"tennis","ATP","Alcaraz","Djokovic",nil,"LIVE"),
            (5,"basketball","EuroLeague","ASVEL","Real Madrid",APIScore(home: 34, away: 39),"Q2"),
            (6,"football","Serie A","Milan","Inter",nil,"Scheduled"),
            (7,"football","LaLiga","Barça","Real Madrid",APIScore(home: 0, away: 0),"1H"),
            (8,"tennis","WTA","Swiatek","Gauff",nil,"Scheduled"),
            (9,"football","Bundesliga","Bayern","Dortmund",APIScore(home: 3, away: 2),"FT"),
            (10,"basketball","NBA","Celtics","Heat",APIScore(home: 45, away: 40),"Q2"),
        ]
        return comps.enumerated().map { idx, t in
            APIMatch(
                id: t.0,
                sport: t.1,
                competition: t.2,
                start_time: Calendar.current.date(byAdding: .hour, value: -idx, to: Date())!,
                status: t.6,
                home: t.3,
                away: t.4,
                score: t.5
            )
        }
    }()
}
