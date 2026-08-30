import SwiftUI

/// A lightweight native color fade at the scroll edge. The app no longer adds
/// an AppKit visual-effect surface behind content.
struct ScrollEdgeTreatment: View {
    enum Edge {
        case top
        case bottom
    }

    let color: Color
    let edge: Edge
    let height: CGFloat

    var body: some View {
        ZStack {
            color
                .mask(blurMask)
                // Keep the edge cue functional but visually quiet. The
                // document surface remains the dominant layer.
                .opacity(0.12)

            LinearGradient(
                colors: colorStops,
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .compositingGroup()
    }

    private var colorStops: [Color] {
        switch edge {
        case .top:
            return [
                color.opacity(0.20),
                color.opacity(0.12),
                color.opacity(0.06),
                .clear
            ]
        case .bottom:
            return [
                .clear,
                color.opacity(0.06),
                color.opacity(0.12),
                color.opacity(0.20)
            ]
        }
    }

    private var blurMask: some View {
        switch edge {
        case .top:
            return AnyView(
                LinearGradient(
                    colors: [.white, .white.opacity(0.62), .white.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .bottom:
            return AnyView(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.18), .white.opacity(0.62), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}
