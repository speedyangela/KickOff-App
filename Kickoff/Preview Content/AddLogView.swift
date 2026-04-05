import SwiftUI

struct AddLogView: View {
    private enum SubmitState: Equatable {
        case idle
        case sending
    }

    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var reviews: ReviewsStore
    @Environment(\.dismiss) private var dismiss

    @State private var showSuccessCelebration = false
    @State private var successSymbolBounceTrigger = 0

    @State private var searchQuery = ""
    @State private var searchDebounceGeneration = 0

    @State private var results: [APIMatch] = []
    @State private var selectedMatch: APIMatch?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var score: Double = 7.0
    @State private var review: String = ""
    @State private var submitState: SubmitState = .idle

    private var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSearch: Bool {
        trimmedQuery.count >= 3
    }

    private var submitDisabled: Bool {
        selectedMatch == nil || submitState == .sending
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(LocalizedStringKey("addlog.search.placeholder"), text: $searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if !canSearch {
                        Text(LocalizedStringKey("addlog.search.hint"))
                            .font(.caption)
                    }
                }

                if isLoading && canSearch {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.clear)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if canSearch, !isLoading, errorMessage == nil, results.isEmpty {
                    Section {
                        Text(LocalizedStringKey("addlog.search.empty"))
                            .foregroundStyle(.secondary)
                    }
                }

                if !results.isEmpty {
                    Section(LocalizedStringKey("addlog.search.results")) {
                        ForEach(results) { m in
                            Button {
                                if selectedMatch?.id == m.id {
                                    selectedMatch = nil
                                } else {
                                    selectedMatch = m
                                }
                            } label: {
                                matchRow(m)
                            }
                        }
                    }
                }

                Section {
                    ScoreGauge(value: $score)
                }
                .disabled(selectedMatch == nil)
                .opacity(selectedMatch == nil ? 0.45 : 1)

                Section(LocalizedStringKey("addlog.review.section")) {
                    ReviewCard(
                        text: $review,
                        placeholder: String(localized: .init("addlog.review.placeholder"))
                    )
                }
                .disabled(selectedMatch == nil)
                .opacity(selectedMatch == nil ? 0.45 : 1)

                Section {
                    HStack {
                        Spacer()
                        Button {
                            Task { await submit() }
                        } label: {
                            if submitState == .sending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label(String(localized: .init("addlog.submit")), systemImage: "paperplane.fill")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle(colors: [.green, .teal]))
                        .disabled(submitDisabled)
                        Spacer()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("addlog.title"))
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: searchQuery) { _, _ in
                scheduleDebouncedSearch()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("addlog.close")) {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: .init("addlog.keyboard.done"))) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
            }
            .overlay {
                if showSuccessCelebration {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
        }
    }

    @ViewBuilder
    private func matchRow(_ m: APIMatch) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(m.home ?? "?") vs \(m.away ?? "?")")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    if let comp = m.competition {
                        Text(comp)
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(m.sport.capitalized)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if selectedMatch?.id == m.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green, .white.opacity(0.95))
                    .symbolEffect(.bounce, value: successSymbolBounceTrigger)

                Text(LocalizedStringKey("addlog.success.title"))
                    .font(.title2.weight(.bold))

                Text(LocalizedStringKey("addlog.success.message"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 12)
            )
            .padding(.horizontal, 36)
        }
    }

    private func scheduleDebouncedSearch() {
        searchDebounceGeneration += 1
        let generation = searchDebounceGeneration

        guard canSearch else {
            results = []
            isLoading = false
            errorMessage = nil
            selectedMatch = nil
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                guard generation == searchDebounceGeneration else { return }
                let q = trimmedQuery
                guard q.count >= 3 else {
                    isLoading = false
                    return
                }
                Task { await performSearch(query: q) }
            }
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        defer { isLoading = false }
        do {
            let found = try await APIClient.shared.searchMatches(query: query)
            results = found
            if let sel = selectedMatch, !found.contains(where: { $0.id == sel.id }) {
                selectedMatch = nil
            }
        } catch {
            errorMessage = String(localized: .init("addlog.search.error"))
            results = []
            selectedMatch = nil
        }
    }

    @MainActor
    private func submit() async {
        guard let m = selectedMatch else { return }
        submitState = .sending
        defer { submitState = .idle }
        do {
            try await APIClient.shared.postRating(
                matchId: m.id,
                score: score,
                review: review.isEmpty ? nil : review
            )

            reviews.add(from: m, score: score, review: review)
            await auth.registerLog(didWriteReview: !review.isEmpty)
            await auth.refreshBadges()

            successSymbolBounceTrigger += 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                showSuccessCelebration = true
            }
            try? await Task.sleep(for: .milliseconds(1_100))
            dismiss()

        } catch {
            errorMessage = String(localized: .init("addlog.submit.error"))
        }
    }
}

// MARK: - UI Helpers

private struct CapsuleButtonStyle: ButtonStyle {
    var colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ReviewCard: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .frame(minHeight: 120)

            TextEditor(text: $text)
                .padding(12)
                .frame(minHeight: 120)
                .opacity(0.99)
                .background(Color.clear)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                            .padding(16)
                    }
                }
        }
        .padding(.vertical, 4)
    }
}
