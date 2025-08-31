//
//  ScoreGauge.swift
//  Kickoff
//
//  Created by Angela Lagache on 31/08/2025.
//

import SwiftUI
import UIKit

/// Jauge 0..10 (pas 0.5) : track neutre, progress ROUGE→VERT selon la note.
/// Curseur centré, ticks 0.5, affichage "x.x /10".
struct ScoreGauge: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...10
    var step: Double = 0.5

    @State private var lastQuantized: Double = -999
    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Titre + valeur /10
            HStack {
                Text("Ta note").font(.headline)
                Spacer()
                Text("\(value, specifier: "%.1f") /10")
                    .font(.title3).bold().monospacedDigit()
            }

            GeometryReader { geo in
                let trackH: CGFloat = 12
                let handle: CGFloat = 24
                let W = geo.size.width
                let H = max(trackH, handle)
                let handleX = xFor(value: value, width: W, handleSize: handle)

                ZStack(alignment: .leading) {
                    // Track neutre
                    RoundedRectangle(cornerRadius: trackH/2, style: .continuous)
                        .fill(Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: trackH/2, style: .continuous)
                                .stroke(.black.opacity(0.08), lineWidth: 0.5)
                        )
                        .frame(height: trackH)
                        .frame(height: H, alignment: .center) // centre verticalement

                    // Progress colorée (couleur = fonction de la note, rouge→vert)
                    RoundedRectangle(cornerRadius: trackH/2, style: .continuous)
                        .fill(activeColor(for: value))
                        .frame(width: max(handleX, handle/2), height: trackH)
                        .mask(
                            RoundedRectangle(cornerRadius: trackH/2, style: .continuous)
                                .frame(height: trackH)
                        )
                        .frame(height: H, alignment: .center)

                    // Ticks fins (tous les 0.5), plus longs aux entiers
                    tickLayer(width: W, height: trackH, containerH: H)
                        .allowsHitTesting(false)

                    // Curseur (PARFAITEMENT CENTRÉ)
                    Circle()
                        .fill(.white)
                        .frame(width: handle, height: handle)
                        .overlay(Circle().stroke(.black.opacity(0.10), lineWidth: 0.75))
                        .shadow(color: .black.opacity(isDragging ? 0.22 : 0.14),
                                radius: isDragging ? 7 : 4, x: 0, y: 3)
                        .position(x: handleX, y: H/2) // ⬅️ centré sur la jauge
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    let clamped = clampX(g.location.x, width: W, handleSize: handle)
                                    let raw = valueFor(x: clamped, width: W, handleSize: handle)
                                    let q = quantize(raw, step: step, in: range)
                                    if q != lastQuantized {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        lastQuantized = q
                                    }
                                    value = q
                                    if !isDragging { isDragging = true }
                                }
                                .onEnded { _ in isDragging = false }
                        )
                }
                .frame(height: H)
            }
            .frame(height: 44)
        }
        .animation(.easeOut(duration: 0.15), value: value)
    }

    // Couleur active : rouge (0) → vert (10), intense
    private func activeColor(for v: Double) -> Color {
        let f = max(0, min(1, (v - range.lowerBound) / (range.upperBound - range.lowerBound)))
        // Hue 0.0 (rouge) → 0.33 (vert), saturation/brightness élevées
        return Color(hue: 0.33 * f, saturation: 0.95, brightness: 0.95)
    }

    // MARK: - Ticks

    private func tickLayer(width W: CGFloat, height trackH: CGFloat, containerH H: CGFloat) -> some View {
        let halfStepCount = Int((range.upperBound - range.lowerBound) / 0.5) // 20
        return ZStack(alignment: .leading) {
            ForEach(0...halfStepCount, id: \.self) { i in
                let frac = CGFloat(i) / CGFloat(halfStepCount)
                let isWhole = i % 2 == 0 // 1.0 step
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 1, height: isWhole ? trackH * 0.9 : trackH * 0.55)
                    .position(x: frac * W, y: H/2)
                    .blendMode(.overlay)
            }
        }
    }

    // MARK: - Helpers

    private func xFor(value: Double, width: CGFloat, handleSize: CGFloat) -> CGFloat {
        let f = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let minX = handleSize/2, maxX = width - handleSize/2
        return min(max(minX + f * (maxX - minX), minX), maxX)
    }
    private func valueFor(x: CGFloat, width: CGFloat, handleSize: CGFloat) -> Double {
        let minX = handleSize/2, maxX = width - handleSize/2
        let f = Double((x - minX) / (maxX - minX))
        let v = range.lowerBound + f * (range.upperBound - range.lowerBound)
        return min(max(v, range.lowerBound), range.upperBound)
    }
    private func quantize(_ v: Double, step: Double, in r: ClosedRange<Double>) -> Double {
        let q = (v / step).rounded() * step
        return min(max(q, r.lowerBound), r.upperBound)
    }
    private func clampX(_ x: CGFloat, width: CGFloat, handleSize: CGFloat) -> CGFloat {
        let minX = handleSize/2, maxX = width - handleSize/2
        return min(max(x, minX), maxX)
    }
}
