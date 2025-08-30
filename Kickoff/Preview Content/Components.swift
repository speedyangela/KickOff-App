//
//  Components.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct MatchRow: View {
    let match: APIMatch
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.competition ?? match.sport.capitalized)
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(match.home ?? "?") vs \(match.away ?? "?")")
                    .font(.headline)
                Text(isLive ? "En direct • \(match.status)"
                            : match.start_time.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(isLive ? .green : .secondary)
            }
            Spacer()
            if let s = match.score {
                Text("\(s.home ?? 0) - \(s.away ?? 0)").bold()
            }
        }
        .padding(.vertical, 4)
    }
    private var isLive: Bool {
        ["LIVE","1H","2H","Q1","Q2","Q3","Q4","OT","ET","In Progress"].contains(match.status)
    }
}

struct TrendingRow: View {
    let match: APITrendingMatch
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.competition ?? match.sport.capitalized)
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(match.home ?? "?") vs \(match.away ?? "?")")
                    .font(.headline)
                Text(match.status == "FT" ? "Terminé" : match.status)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let s = match.score {
                    Text("\(s.home ?? 0) - \(s.away ?? 0)").bold()
                }
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    Text(String(format: "%.1f", match.ratings.avg))
                    Text("(\(match.ratings.count))").foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

