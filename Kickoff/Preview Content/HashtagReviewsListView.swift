//
//  HashtagReviewsListView.swift
//  Kickoff
//
//  Liste des avis contenant un hashtag donné.
//

import SwiftUI

struct HashtagReviewsListView: View {
    let tag: String
    var isPresentedInSheet: Bool = false

    @EnvironmentObject var reviews: ReviewsStore
    @Environment(\.dismiss) private var dismiss

    private var filtered: [LocalReview] {
        reviews.reviews(matchingHashtag: tag)
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView {
                    Label(LocalizedStringKey("hashtag.empty.title"), systemImage: "number")
                } description: {
                    Text(String(format: String(localized: .init("hashtag.empty.message")), tag))
                }
            } else {
                List {
                    ForEach(filtered) { r in
                        NavigationLink {
                            MatchDetailView(matchId: r.matchId, allowRating: true)
                        } label: {
                            ReviewRowView(r: r, enableHashtagLinks: false)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("#\(tag)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPresentedInSheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("addlog.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
