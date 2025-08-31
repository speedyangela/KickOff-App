//
//  AuthManager.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import Foundation
import Combine

/// Gestion mock de l'authentification (stockée en UserDefaults)
/// ⚠️ MOCK UNIQUEMENT — pas sécurisé, suffisant pour tester l'UI.
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var currentUser: APIUser? = nil

    private let defaults = UserDefaults.standard
    private let userKey = "auth_current_user"
    private let passwordKey = "auth_password" // mock only

    private init() {
        if let data = defaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(APIUser.self, from: data) {
            self.currentUser = user
        }
    }

    // MARK: - Public

    func signUp(username: String, email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        if defaults.data(forKey: userKey) != nil {
            throw NSError(domain:"Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Un compte existe déjà sur cet appareil (mock)."])
        }
        let user = APIUser(
            id: UUID(),
            username: username,
            email: email,
            bio: nil,
            stats: .init(logsCount: 0, reviewsCount: 0, badges: []),
            avatarPNGBase64: nil
        )
        try save(user: user)
        defaults.set(password, forKey: passwordKey) // mock only
        await MainActor.run { self.currentUser = user }

        // ⬇️ Option 6 : calculer les badges dès la création
        await refreshBadges()
    }


    func signIn(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
        guard let data = defaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(APIUser.self, from: data) else {
            throw NSError(domain:"Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Aucun compte trouvé (mock)."])
        }
        guard user.email.lowercased() == email.lowercased(),
              defaults.string(forKey: passwordKey) == password else {
            throw NSError(domain:"Auth", code: 3, userInfo: [NSLocalizedDescriptionKey: "Email ou mot de passe invalide (mock)."])
        }
        await MainActor.run { self.currentUser = user }
    }

    func signOut() {
        Task { @MainActor in self.currentUser = nil }
    }

    func update(username: String, bio: String?) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        guard var user = currentUser else { return }
        user.username = username
        user.bio = (bio?.isEmpty ?? true) ? nil : bio
        try save(user: user)
        await MainActor.run { self.currentUser = user }
    }

    func deleteAccount() async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        defaults.removeObject(forKey: userKey)
        defaults.removeObject(forKey: passwordKey)
        await MainActor.run { self.currentUser = nil }
    }

    // MARK: - Private

    private func save(user: APIUser) throws {
        let data = try JSONEncoder().encode(user)
        defaults.set(data, forKey: userKey)
    }
    func updateAvatar(_ data: Data?) async throws {
        try await Task.sleep(nanoseconds: 80_000_000)
        guard var user = currentUser else { return }
        if let data {
            user.avatarPNGBase64 = data.base64EncodedString()
        } else {
            user.avatarPNGBase64 = nil
        }
        try save(user: user)
        await MainActor.run { self.currentUser = user }
    }
    /// À appeler après un log réussi
    func registerLog(didWriteReview: Bool) async {
        guard var user = currentUser else { return }
        user.stats.logsCount += 1
        if didWriteReview { user.stats.reviewsCount += 1 }
        try? save(user: user)
        await MainActor.run { self.currentUser = user }
    }

    /// Met à jour la liste des badges débloqués (côté mock)
    func refreshBadges() async {
        guard var user = currentUser else { return }
        let unlocked = BadgeEngine.unlockedBadgeIDs(for: user.stats)
        user.stats.badges = Array(unlocked)
        try? save(user: user)
        await MainActor.run { self.currentUser = user }
    }


}
