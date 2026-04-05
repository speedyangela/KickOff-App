//
//  ScoreGauge.swift
//  Kickoff
//
//  Created by Angela Lagache on 31/08/2025.
//

import SwiftUI

/// Jauge 0…10 par pas de 0,5 : bandeau en dégradé permanent (rouge → jaune → vert),
/// curseur teinté selon la position (lecture façon Letterboxd).
struct ScoreGauge: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...10
    var step: Double = 0.5

    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey("scoregauge.title"))
                    .font(.headline)
                Spacer()
                Text("\(value, specifier: "%.1f") /10")
                    .font(.title3).bold().monospacedDigit()
            }

            GeometryReader { geo in
                let trackH: CGFloat = 16
                let handle: CGFloat = 28
                let W = geo.size.width
                let H = max(trackH, handle)
                let handleX = xFor(value: value, width: W, handleSize: handle)
                let tNorm = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: trackH / 2, style: .continuous)
                        .fill(trackGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: trackH / 2, style: .continuous)
                                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        .frame(height: trackH)
                        .frame(height: H, alignment: .center)

                    tickLayer(width: W, height: trackH, containerH: H)
                        .allowsHitTesting(false)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    chroma(at: tNorm).opacity(0.95),
                                    chroma(at: tNorm).opacity(0.75),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: handle / 2
                            )
                        )
                        .frame(width: handle, height: handle)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.95),
                                            .white.opacity(0.35),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: chroma(at: tNorm).opacity(0.55), radius: isDragging ? 10 : 5, x: 0, y: 3)
                        .shadow(color: .black.opacity(isDragging ? 0.22 : 0.12), radius: isDragging ? 6 : 3, x: 0, y: 2)
                        .position(x: handleX, y: H / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    let clamped = clampX(g.location.x, width: W, handleSize: handle)
                                    let raw = valueFor(x: clamped, width: W, handleSize: handle)
                                    value = quantize(raw, step: step, in: range)
                                    if !isDragging { isDragging = true }
                                }
                                .onEnded { _ in isDragging = false }
                        )
                }
                .frame(height: H)
                .sensoryFeedback(.impact(weight: .light, intensity: 0.85), trigger: value)
            }
            .frame(height: 48)
        }
        .animation(.easeOut(duration: 0.14), value: value)
    }

    private var trackGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.95, green: 0.12, blue: 0.14), location: 0),
                .init(color: Color(red: 1, green: 0.45, blue: 0.08), location: 0.22),
                .init(color: Color(red: 1, green: 0.92, blue: 0.15), location: 0.52),
                .init(color: Color(red: 0.45, green: 0.88, blue: 0.35), location: 0.78),
                .init(color: Color(red: 0.12, green: 0.62, blue: 0.32), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Couleur du curseur alignée sur les extrémités du dégradé du track.
    private func chroma(at t: CGFloat) -> Color {
        let t = max(0, min(1, t))
        if t < 0.5 {
            let u = Double(t * 2)
            return Color(red: 1, green: 0.12 + 0.80 * u, blue: 0.14 * (1 - u) + 0.15 * u)
        } else {
            let u = Double((t - 0.5) * 2)
            return Color(red: 1 - 0.88 * u, green: 0.92 - 0.30 * u, blue: 0.15 + 0.17 * u)
        }
    }

    private func tickLayer(width W: CGFloat, height trackH: CGFloat, containerH H: CGFloat) -> some View {
        let span = range.upperBound - range.lowerBound
        let halfStepCount = Int(span / 0.5)
        return ZStack(alignment: .leading) {
            ForEach(0...halfStepCount, id: \.self) { i in
                let frac = CGFloat(i) / CGFloat(halfStepCount)
                let isWhole = i % 2 == 0
                Rectangle()
                    .fill(.black.opacity(0.22))
                    .frame(width: isWhole ? 1.25 : 0.85, height: isWhole ? trackH * 0.92 : trackH * 0.5)
                    .position(x: frac * W, y: H / 2)
                    .blendMode(.multiply)
            }
        }
    }

    private func xFor(value: Double, width: CGFloat, handleSize: CGFloat) -> CGFloat {
        let f = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let minX = handleSize / 2
        let maxX = width - handleSize / 2
        return min(max(minX + f * (maxX - minX), minX), maxX)
    }

    private func valueFor(x: CGFloat, width: CGFloat, handleSize: CGFloat) -> Double {
        let minX = handleSize / 2
        let maxX = width - handleSize / 2
        let f = Double((x - minX) / (maxX - minX))
        let v = range.lowerBound + f * (range.upperBound - range.lowerBound)
        return min(max(v, range.lowerBound), range.upperBound)
    }

    private func quantize(_ v: Double, step: Double, in r: ClosedRange<Double>) -> Double {
        let q = (v / step).rounded() * step
        return min(max(q, r.lowerBound), r.upperBound)
    }

    private func clampX(_ x: CGFloat, width: CGFloat, handleSize: CGFloat) -> CGFloat {
        let minX = handleSize / 2
        let maxX = width - handleSize / 2
        return min(max(x, minX), maxX)
    }
}
