//
//  ProfileView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//


import SwiftUI
import PhotosUI

// MARK: - Helpers (flag + sport emoji)

private func flagEmoji(from countryCode: String) -> String {
    let base: UInt32 = 127397 // 🇦 is U+1F1E6 = 'A' + 127397
    var s = ""
    for v in countryCode.uppercased().unicodeScalars {
        if let scalar = UnicodeScalar(base + v.value) { s.unicodeScalars.append(scalar) }
    }
    return s
}

private func sportEmoji(_ s: String) -> String {
    switch s.lowercased() {
    case "football", "soccer": return "⚽️"
    case "basketball": return "🏀"
    case "tennis": return "🎾"
    default: return "🏅"
    }
}

// MARK: - Root

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var reviews: ReviewsStore

    @State private var selectedTab: ProfileTab = .profile
    @State private var showAccountSheet = false

    var body: some View {
        Group {
            if let user = auth.currentUser {
                VStack(spacing: 0) {
                    // Top bar with compact "Infos" button
                    HStack {
                        Spacer()
                        Button {
                            showAccountSheet = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "person.crop.circle.badge.gear")
                                .font(.title3)
                                .padding(8)
                                .background(Color.accentColor.opacity(0.12), in: Circle())
                        }
                        .tint(.accentColor)
                        .accessibilityLabel("Infos du compte")
                    }
                    .padding(.trailing, 6)

                    // Segmented tabs under top bar
                    Picker("Section", selection: $selectedTab) {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .bottom])

                    // Content by tab
                    switch selectedTab {
                    case .profile:
                        ProfileTabView(user: user)
                            .environmentObject(auth)
                            .environmentObject(reviews)
                    case .badges:
                        ProfileBadgesView() // existing view in your project
                    case .reviews:
                        MyReviewsView() // existing view in your project
                    }
                }
                .sheet(isPresented: $showAccountSheet) {
                    AccountQuickSheet()
                        .environmentObject(auth)
                }
            } else {
                AuthView() // existing sign-in / sign-up
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tabs enum

private enum ProfileTab: CaseIterable { case profile, badges, reviews
    var title: String {
        switch self { case .profile: return "Profile"; case .badges: return "Badges"; case .reviews: return "Reviews" }
    }
}

// MARK: - Profile tab content

private struct ProfileTabView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var reviews: ReviewsStore

    let user: APIUser
    @State private var avatarItem: PhotosPickerItem? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // 1) StatsRow (top)
                StatsRow(stats: user.stats)
                    .padding(.horizontal)
                    .padding(.top, 4)

                // 2) Avatar centered + flag badge + edit button
                AvatarBlock(user: user, avatarItem: $avatarItem)

                // 3) Username + Bio
                VStack(spacing: 6) {
                    Text(user.username)
                        .font(.title2.weight(.semibold))
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }

                // 3b) Sports watched (emojis)
                if let sports = user.sportsWatched, !sports.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(sports.prefix(3), id: \.self) { s in
                            Text(sportEmoji(s))
                                .font(.title3)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 4) Favorites card (text pills + edit sheet)
                FavoritesCard()

                // 5) Recent activity
                RecentActivitySection(items: reviews.items)
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Components

private struct StatsRow: View {
    let stats: APIUserStats

    var body: some View {
        HStack(spacing: 12) {
            StatChip(value: stats.logsCount, label: "Logs")
            StatChip(value: stats.reviewsCount, label: "Reviews")
            StatChip(value: stats.badges.count, label: "Badges")
        }
    }
}

private struct StatChip: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(compact(value))
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(stops: [
                .init(color: Color.accentColor.opacity(0.22), location: 0),
                .init(color: Color.accentColor.opacity(0.06), location: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n)/1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n)/1_000) }
        return String(n)
    }
}

private struct AvatarBlock: View {
    @EnvironmentObject var auth: AuthManager
    let user: APIUser
    @Binding var avatarItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                AvatarView(user: user)
                    .frame(width: 96, height: 96)

                // Flag badge (top-right)
                if let cc = user.countryCode, !cc.isEmpty {
                    Text(flagEmoji(from: cc))
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
                        .offset(x: 36, y: -36)
                        .transition(.scale.combined(with: .opacity))
                }

                // Edit button (bottom-right)
                VStack {
                    Spacer()
                    HStack { Spacer()
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .padding(6)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
        }
        .onChange(of: avatarItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    try? await auth.updateAvatar(data)
                }
            }
        }
    }
}

private struct AvatarView: View {
    let user: APIUser
    var body: some View {
        if let b64 = user.avatarPNGBase64, let data = Data(base64Encoded: b64), let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable().scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.quaternary, lineWidth: 1))
                .shadow(radius: 2, y: 1)
        } else {
            ZStack {
                Circle().fill(.secondary.opacity(0.15))
                Text(user.username.prefix(1).uppercased())
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// FAVORIS v1: text pills + edit sheet (mock via AuthManager)
private struct FavoritesCard: View {
    @EnvironmentObject var auth: AuthManager
    @State private var showEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Favoris", systemImage: "star.fill")
                    .font(.headline)
                Spacer()
                Button {
                    showEdit = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "pencil")
                        .padding(8)
                        .background(Color.accentColor.opacity(0.15), in: Circle())
                }
                .tint(.accentColor)
                .accessibilityLabel("Modifier les favoris")
            }

            let favs = auth.currentUser?.favorites ?? []
            if favs.isEmpty {
                Text("Ajoute jusqu’à 5 favoris (clubs ou joueurs).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favs.prefix(5), id: \.self) { f in
                            Text(f)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.14), in: Capsule())
                                .overlay(Capsule().stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showEdit) {
            FavoritesEditSheet().environmentObject(auth)
        }
    }
}

private struct FavoritesEditSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var fields: [String] = Array(repeating: "", count: 5)
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Tes favoris (clubs ou joueurs)") {
                    ForEach(0..<5, id: \.self) { i in
                        TextField("Favori \(i+1)", text: $fields[i])
                            .textInputAutocapitalization(.words)
                    }
                    Text("Exemples : PSG, OL, Messi, Ronaldo, Djokovic…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Modifier les favoris")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isLoading ? "…" : "Enregistrer") {
                        Task { await save() }
                    }
                    .tint(.accentColor)
                    .disabled(isLoading)
                }
            }
            .onAppear {
                let current = auth.currentUser?.favorites ?? []
                for i in 0..<min(5, current.count) { fields[i] = current[i] }
            }
        }
    }

    private func save() async {
        errorMessage = nil; isLoading = true
        defer { isLoading = false }
        do {
            let cleaned = fields
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            try await auth.updateFavorites(cleaned)
            await MainActor.run { dismiss() }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

private struct RecentActivitySection: View {
    let items: [LocalReview]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activité récente")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            if items.isEmpty {
                Text("Aucune activité pour le moment.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(items.sorted(by: { $0.createdAt > $1.createdAt }).prefix(10)) { r in
                        ReviewRowView(r: r)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        Divider()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Quick account sheet (add country + sports)

private struct AccountQuickSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var username: String = ""
    @State private var bio: String = ""

    @State private var countryCode: String = ""
    @State private var watchesFootball = false
    @State private var watchesBasket = false
    @State private var watchesTennis = false

    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Pseudo", text: $username)
                    TextField("Bio (optionnel)", text: $bio, axis: .vertical)
                    TextField("Code pays (ex: FR)", text: $countryCode)
                        .textInputAutocapitalization(.characters)
                }

                Section("Sports regardés") {
                    Toggle("Football", isOn: $watchesFootball)
                    Toggle("Basket", isOn: $watchesBasket)
                    Toggle("Tennis", isOn: $watchesTennis)
                }

                if let email = auth.currentUser?.email {
                    Section("Compte") { Text(email).foregroundStyle(.secondary) }
                }

                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Infos du compte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isLoading ? "…" : "Enregistrer") {
                        Task { await save() }
                    }
                    .tint(.accentColor)
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if let u = auth.currentUser {
                    username = u.username
                    bio = u.bio ?? ""
                    countryCode = u.countryCode ?? ""
                    let s = Set((u.sportsWatched ?? []).map { $0.lowercased() })
                    watchesFootball = s.contains("football") || s.contains("soccer")
                    watchesBasket = s.contains("basketball")
                    watchesTennis = s.contains("tennis")
                }
            }
        }
    }

    private func save() async {
        errorMessage = nil; isLoading = true
        defer { isLoading = false }
        do {
            try await auth.update(username: username, bio: bio)
            let sports = [
                watchesFootball ? "football" : nil,
                watchesBasket ? "basketball" : nil,
                watchesTennis ? "tennis" : nil
            ].compactMap { $0 }
            try await auth.updateProfileInfo(countryCode: countryCode, sportsWatched: sports)
            await MainActor.run { dismiss() }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Previews

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ReviewsStore.shared)
        }
    }
}

// MARK: - Auth (inchangée)

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager
    enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Picker("Mode", selection: $mode) {
                    Text("Se connecter").tag(Mode.signIn)
                    Text("Créer un compte").tag(Mode.signUp)
                }
                .pickerStyle(.segmented)

                if mode == .signUp {
                    TextField("Pseudo", text: $username)
                }
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                SecureField("Mot de passe", text: $password)

                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                if isLoading { ProgressView() }

                Button {
                    Task { await submit() }
                } label: {
                    Text(mode == .signIn ? "Se connecter" : "Créer mon compte")
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(isDisabled)
            }
            .navigationTitle("Mon compte")
        }
    }

    private var isDisabled: Bool {
        if mode == .signUp { return username.isEmpty || email.isEmpty || password.count < 4 }
        return email.isEmpty || password.isEmpty
    }

    @MainActor
    private func submit() async {
        errorMessage = nil; isLoading = true
        defer { isLoading = false }
        do {
            if mode == .signUp {
                try await auth.signUp(username: username, email: email, password: password)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
