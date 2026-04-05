//
//  OnboardingView.swift
//  Kickoff
//
//  Premier lancement : choix FR / EN (texte bilingue pour ne pas dépendre de la locale).
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedLanguageOnboarding") private var hasCompletedLanguageOnboarding = false
    @AppStorage("appPreferredLanguage") private var appPreferredLanguage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.45, blue: 0.22),
                    Color(red: 0.96, green: 0.28, blue: 0.52),
                    Color(red: 0.75, green: 0.22, blue: 0.65),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("KickOff")
                    .font(.system(size: 42, weight: .black, design: .serif))
                    .kerning(0.5)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

                Text("Choisis ta langue · Choose your language")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    languageButton(
                        title: "Français",
                        symbol: "🇫🇷",
                        code: "fr"
                    )
                    languageButton(
                        title: "English",
                        symbol: "🇬🇧",
                        code: "en"
                    )
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
    }

    private func languageButton(title: String, symbol: String, code: String) -> some View {
        Button {
            selectLanguage(code)
        } label: {
            HStack(spacing: 14) {
                Text(symbol)
                    .font(.system(size: 32))
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.22))
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func selectLanguage(_ code: String) {
        appPreferredLanguage = code
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        hasCompletedLanguageOnboarding = true
    }
}
