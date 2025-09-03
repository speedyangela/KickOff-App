import SwiftUI

struct AddLogView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var reviews: ReviewsStore

    @State private var success = false

    // Form data
    @State private var sport: String = ""
    @State private var date: Date = Date()
    @State private var teamA: String = ""
    @State private var teamB: String = ""

    // Results
    @State private var results: [APIMatch] = []
    @State private var selectedMatch: APIMatch?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Rating + review
    @State private var score: Double = 7.0
    @State private var review: String = ""

    var body: some View {
        NavigationView {
            Form {
                // --- Infos du match ---
                Section("Infos du match") {
                    Picker("Sport", selection: $sport) {
                        Text("—").tag("")
                        Text("football").tag("football")
                        Text("basketball").tag("basketball")
                        Text("tennis").tag("tennis")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    // Équipes : 2 champs avec un "vs" au centre
                    HStack(spacing: 10) {
                        TextField("Équipe 1", text: $teamA)
                            .textFieldStyle(.roundedBorder)
                        Text("vs")
                            .font(.subheadline).bold()
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 24)
                        TextField("Équipe 2", text: $teamB)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)

                    // Bouton "Chercher le match" — centré & attractif
                    HStack {
                        Spacer()
                        Button {
                            Task { await search() }
                        } label: {
                            Label("Chercher le match", systemImage: "magnifyingglass")
                                .font(.headline)
                        }
                        .buttonStyle(CapsuleButtonStyle(colors: [.orange, .pink]))
                        .disabled(sport.isEmpty && teamA.isEmpty && teamB.isEmpty)
                        Spacer()
                    }
                    .padding(.top, 6)
                }

                // --- Résultats (tap = sélection / re-tap = désélection) ---
                if isLoading { ProgressView("Recherche…") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }

                if !results.isEmpty {
                    Section("Résultats") {
                        ForEach(results) { m in
                            Button {
                                // Toggle sélection / désélection
                                if selectedMatch?.id == m.id {
                                    selectedMatch = nil
                                } else {
                                    selectedMatch = m
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(m.home ?? "?") vs \(m.away ?? "?")").bold()
                                        Text(m.competition ?? m.sport.capitalized)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedMatch?.id == m.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Note ---
                Section {
                    ScoreGauge(value: $score) // jauge stylée déjà intégrée
                }

                // --- Review séparée (qui donne envie) ---
                Section("Ta review (optionnel)") {
                    ReviewCard(text: $review, placeholder: "Raconte ton ressenti, les moments clés, l’ambiance…")
                }

                // --- Valider (centré & attractif) ---
                Section {
                    HStack {
                        Spacer()
                        Button {
                            Task { await submit() }
                        } label: {
                            Label("Valider mon log", systemImage: "paperplane.fill")
                                .font(.headline)
                        }
                        .buttonStyle(CapsuleButtonStyle(colors: [.green, .teal]))
                        .disabled(selectedMatch == nil)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Ajouter un match")
            .scrollDismissesKeyboard(.interactively)          // iOS 16+
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Terminé") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
            }

            .alert("Merci !", isPresented: $success) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Ton log a été pris en compte.")
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func search() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            results = try await APIClient.shared.searchMatchesAdvanced(
                sport: sport.isEmpty ? nil : sport,
                date: date,
                home: teamA.isEmpty ? nil : teamA,
                away: teamB.isEmpty ? nil : teamB,
                competition: nil
            )
            if results.isEmpty {
                errorMessage = "Aucun match trouvé. Ajuste tes champs."
                selectedMatch = nil
            }
        } catch {
            errorMessage = "Recherche impossible."
        }
    }

    @MainActor
    private func submit() async {
        guard let m = selectedMatch else { return }
        do {
            try await APIClient.shared.postRating(
                matchId: m.id,
                score: score,
                review: review.isEmpty ? nil : review
            )

            // Enregistre localement + stats/badges
            reviews.add(from: m, score: score, review: review)
            await auth.registerLog(didWriteReview: !review.isEmpty)
            await auth.refreshBadges()

            // Feedback
            success = true

        } catch {
            errorMessage = "Envoi impossible."
        }
    }
}

// MARK: - UI Helpers

private struct CapsuleButtonStyle: ButtonStyle {
    var colors: [Color]   // on passe juste les couleurs

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
                .opacity(0.99) // corrige un bug d’affichage
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


