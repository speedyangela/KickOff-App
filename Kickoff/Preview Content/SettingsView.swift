//
//  SettingsView.swift
//  Kickoff
//
//  Created by Angela Lagache on 30/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var env: APIClient.APIEnv = APIClient.shared.env
    @State private var baseURL: String = APIClient.shared.baseURL.absoluteString
    @State private var token: String = ""   // si tu n'en as pas, laisse vide

    @State private var applied = false

    var body: some View {
        NavigationView {
            Form {
                Section("Environnement API") {
                    Picker("Mode", selection: $env) {
                        Text("Mock (offline)").tag(APIClient.APIEnv.mock)
                        Text("Live (serveur)").tag(APIClient.APIEnv.live)
                    }
                    .pickerStyle(.segmented)

                    TextField("Base URL (live)", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    SecureField("Token (optionnel)", text: $token)
                }

                Section {
                    Button {
                        apply()
                    } label: {
                        Label("Appliquer", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    if applied {
                        Text("Réglages appliqués ✔︎").foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func apply() {
        APIClient.shared.env = env
        if let url = URL(string: baseURL), env == .live {
            APIClient.shared.baseURL = url
        }
        // Si tu as ajouté authToken dans APIClient, décommente :
        // APIClient.shared.authToken = token.isEmpty ? nil : token
        applied = true
    }
}

