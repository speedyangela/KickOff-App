//
//  SplashView.swift
//  Kickoff
//
//  Created by Angela Lagache on 04/09/2025.
//

import SwiftUI

/// Splash animé KickOff (rideau rouge qui s’ouvre)
struct KickoffSplashView: View {
    var onFinished: () -> Void = {}

    @State private var animate = false
    @State private var showLogo = true

    // Durées
    private let holdDuration: CGFloat = 0.55
    private let slideDuration: CGFloat = 0.75
    private let fadeDuration: CGFloat = 0.25

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Contenu révélé derrière le rideau (léger fond pour evitare flash)
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Logo centré pendant l'ouverture
                Group {
                    if showLogo {
                        VStack(spacing: 8) {
                            // Si tu as une image de mot-symbole, remplace par Image("KickOffWordmark")
                            Text("KickOff")
                                .font(.system(size: 44, weight: .black, design: .serif))
                                .kerning(0.5)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                        }
                        .scaleEffect(animate ? 1.0 : 0.92)
                        .opacity(animate ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.35), value: animate)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)

                // Rideau rouge (deux panneaux)
                SplitCurtain(isOpen: animate, color: Color(red: 252/255, green: 3/255, blue: 169/255))
                    .ignoresSafeArea()
            }
            .background(Color(red: 0.96, green: 0.24, blue: 0.21)) // Rouge KickOff
            .onAppear {
                // timeline : pause courte -> ouvrir rideau -> fade out logo -> fin
                DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                    withAnimation(.easeInOut(duration: slideDuration)) {
                        animate = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration * 0.75) {
                        withAnimation(.easeOut(duration: fadeDuration)) {
                            showLogo = false
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration + 0.20) {
                        onFinished()
                    }
                }
            }
            .accessibilityHidden(true)
        }
    }
}

/// Deux panneaux qui s’ouvrent vers gauche/droite
private struct SplitCurtain: View {
    let isOpen: Bool
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let offset = w/2 + 60 // dépasse un peu l’écran

            ZStack {
                // Left panel
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
                    .overlay(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.7)],
                                            startPoint: .trailing, endPoint: .leading))
                    .frame(width: w/2 + 1, height: h)
                    .offset(x: isOpen ? -offset : 0, y: 0)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 4, y: 0)

                // Right panel
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
                    .overlay(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.7)],
                                            startPoint: .leading, endPoint: .trailing))
                    .frame(width: w/2 + 1, height: h)
                    .offset(x: isOpen ? offset : 0, y: 0)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: -4, y: 0)
            }
            .frame(width: w, height: h, alignment: .center)
        }
    }
}

