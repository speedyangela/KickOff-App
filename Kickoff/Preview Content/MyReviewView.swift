//
//  MyReviewView.swift
//  Kickoff
//
//  Created by Angela Lagache on 03/09/2025.
//

import SwiftUI

enum ReviewNavigationRoute: Hashable {
    case match(Int)
    case hashtag(String)
}

struct MyReviewsView: View {
    @EnvironmentObject var reviews: ReviewsStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if reviews.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey("myreviews.empty.title"))
                            .font(.headline)
                        Text(LocalizedStringKey("myreviews.empty.hint"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(reviews.items) { r in
                            NavigationLink(value: ReviewNavigationRoute.match(r.matchId)) {
                                ReviewRowView(
                                    r: r,
                                    enableHashtagLinks: true,
                                    onHashtagTap: { tag in
                                        path.append(ReviewNavigationRoute.hashtag(tag))
                                    }
                                )
                            }
                        }
                        .onDelete(perform: reviews.delete)
                    }
                    .listStyle(.insetGrouped)
                    .toolbar { EditButton() }
                }
            }
            .navigationDestination(for: ReviewNavigationRoute.self) { route in
                switch route {
                case .match(let id):
                    MatchDetailView(matchId: id, allowRating: true)
                case .hashtag(let t):
                    HashtagReviewsListView(tag: t)
                }
            }
        }
    }
}

struct ReviewRowView: View {
    let r: LocalReview
    var enableHashtagLinks: Bool = false
    var onHashtagTap: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(r.competition ?? r.sport.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ScorePill(score: r.score)
            }

            Text("\(r.home ?? "?") vs \(r.away ?? "?")")
                .font(.headline)

            Text(r.start_time.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let review = r.review, !review.isEmpty {
                Text(
                    HashtagParser.attributedReview(
                        review,
                        linksEnabled: enableHashtagLinks && onHashtagTap != nil
                    )
                )
                .font(.subheadline)
                .padding(.top, 2)
                .environment(\.openURL, OpenURLAction { url in
                    guard let tag = HashtagParser.tag(from: url) else { return .discarded }
                    guard let onHashtagTap else { return .discarded }
                    onHashtagTap(tag)
                    return .handled
                })
            }

            if !r.replies.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text(String(format: String(localized: .init("myreviews.replies.format")), r.replies.count))
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
        return Color(hue: 0.33 * f, saturation: 0.95, brightness: 0.95)
    }
}
