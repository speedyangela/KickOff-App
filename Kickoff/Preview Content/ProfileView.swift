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
        if let user = auth.currentUser {
            ProfileTabs(user: user)
        } else {
            AuthView()
        }
    }
}

// MARK: - Tabs (Infos / Badges)

struct ProfileTabs: View {
    @EnvironmentObject var auth: AuthManager
    enum Tab { case infos, badges }
    @State private var tab: Tab = .infos

    var user: APIUser

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Picker("", selection: $tab) {
                    Text("Infos").tag(Tab.infos)
                    Text("Badges").tag(Tab.badges)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if tab == .infos {
                    ProfileDetailForm(user: user)
                } else {
                    ProfileBadgesView()
                }
            }
            .navigationTitle("Profil")
        }
    }
}

// MARK: - Formulaire Infos

struct ProfileDetailForm: View {
    @EnvironmentObject var auth: AuthManager

    @State var username: String
    @State var bio: String

    @State private var pickerItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(user: APIUser) {
        _username = State(initialValue: user.username)
        _bio = State(initialValue: user.bio ?? "")
    }

    var body: some View {
        Form {
            Section("Avatar") {
                HStack(spacing: 16) {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 8) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Changer la photo", systemImage: "photo")
                        }
                        Button(role: .destructive) {
                            Task { try? await auth.updateAvatar(nil) }
                        } label: {
                            Label("Supprimer la photo", systemImage: "trash")
                        }
                    }
                }
            }

            Section("Profil") {
                TextField("Pseudo", text: $username)
                Text(auth.currentUser?.email ?? "")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Bio (optionnel)", text: $bio, axis: .vertical)
            }

            Section("Statistiques") {
                let stats = auth.currentUser?.stats
                HStack { Text("Logs"); Spacer(); Text("\(stats?.logsCount ?? 0)") }
                HStack { Text("Reviews"); Spacer(); Text("\(stats?.reviewsCount ?? 0)") }
            }

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            if isSaving { ProgressView() }

            Section {
                Button("Enregistrer") { Task { await save() } }
                Button("Se déconnecter", role: .destructive) { auth.signOut() }
                Button("Supprimer mon compte", role: .destructive) {
                    Task { try? await auth.deleteAccount() }
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    try? await auth.updateAvatar(data)
                }
            }
        }
    }

    private var avatarImage: Image {
        if let b64 = auth.currentUser?.avatarPNGBase64,
           let data = Data(base64Encoded: b64),
           let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        }
        return Image(systemName: "person.crop.circle.fill")
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

// MARK: - Auth (inchangé)

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
