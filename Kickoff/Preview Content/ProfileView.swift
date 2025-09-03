//
//  ProfileView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        if let u = auth.currentUser {
            ProfileShell(user: u)
        } else {
            AuthView()
        }
    }
}

// MARK: - Shell avec header + tabs

struct ProfileShell: View {
    @EnvironmentObject var auth: AuthManager
    @State private var showSettings = false
    @State private var pickerItem: PhotosPickerItem?

    enum Tab { case infos, badges, reviews }
    @State private var tab: Tab = .infos

    let user: APIUser

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // HEADER — avatar + nom + stats
                    ProfileHeader(
                        username: auth.currentUser?.username ?? user.username,
                        email: auth.currentUser?.email ?? user.email,
                        avatarB64: auth.currentUser?.avatarPNGBase64,
                        logs: auth.currentUser?.stats.logsCount ?? 0,
                        reviews: auth.currentUser?.stats.reviewsCount ?? 0,
                        badges: auth.currentUser?.stats.badges.count ?? 0,
                        onChangePhoto: { pickerItem = $0 }
                    )

                    // Tabs
                    Picker("", selection: $tab) {
                        Text("Infos").tag(Tab.infos)
                        Text("Badges").tag(Tab.badges)
                        Text("Reviews").tag(Tab.reviews)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Contenu
                    Group {
                        switch tab {
                        case .infos:
                            ProfileInfoCard()
                        case .badges:
                            ProfileBadgesView()
                        case .reviews:
                            MyReviewsView()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        try? await auth.updateAvatar(data)
                    }
                }
            }
        }
    }
}

private struct ProfileHeader: View {
    @EnvironmentObject var auth: AuthManager

    let username: String
    let email: String
    let avatarB64: String?
    let logs: Int
    let reviews: Int
    let badges: Int
    var onChangePhoto: (PhotosPickerItem?) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.85), .indigo],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)

            HStack(spacing: 16) {
                avatar
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: .init(
                            get: { nil }, set: onChangePhoto
                        ), matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .padding(6)
                                .background(Circle().fill(.ultraThinMaterial))
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                        }
                        .offset(x: 4, y: 4)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(username).font(.title3).bold().foregroundStyle(.white)
                    Text(email).font(.caption).foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 10) {
                        StatChip(title: "Logs", value: logs)
                        StatChip(title: "Reviews", value: reviews)
                        StatChip(title: "Badges", value: badges)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal)
    }

    private var avatar: Image {
        if let b64 = avatarB64, let data = Data(base64Encoded: b64), let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        }
        return Image(systemName: "person.crop.circle.fill")
    }
}

private struct StatChip: View {
    let title: String; let value: Int
    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.subheadline).bold().monospacedDigit()
                .foregroundStyle(.white)
            Text(title)
                .font(.caption).foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(.white.opacity(0.15)))
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Infos (édition pseudo/bio) en carte

private struct ProfileInfoCard: View {
    @EnvironmentObject var auth: AuthManager
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Infos").font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Pseudo", text: $username)
                    .textFieldStyle(.roundedBorder)

                if let email = auth.currentUser?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Bio (optionnel)", text: $bio, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    )
            )

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            if isSaving { ProgressView() }

            HStack {
                Button("Se déconnecter", role: .destructive) {
                    auth.signOut()
                }

                Spacer()

                Button("Enregistrer") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            username = auth.currentUser?.username ?? ""
            bio = auth.currentUser?.bio ?? ""
        }
    }

    @MainActor
    private func save() async {
        isSaving = true; errorMessage = nil
        defer { isSaving = false }
        do {
            try await auth.update(username: username, bio: bio)
        } catch {
            errorMessage = error.localizedDescription
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
