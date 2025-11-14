//
//  PawnTheme.swift
//  BigProjectUIApp
//
//  Created by Matthew Pearaylall on 11/14/25.
//

import SwiftUI
import UIKit

// MARK: - Brand Theme

enum PawnTheme {
    static let gold = Color(red: 0.84, green: 0.70, blue: 0.28)   // Luxe pawn-shop gold
    static let charcoal = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let slate = Color(red: 0.16, green: 0.16, blue: 0.18)

    static let background = LinearGradient(
        colors: [charcoal, slate],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PawnButtonStyle: ButtonStyle {
    var fill: Color = PawnTheme.gold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.9 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(PawnTheme.gold)
                    .symbolRenderingMode(.palette)

                Text("LEV Pawn Shop")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }

            Text("Pawn • Trade • Sell — with real-world logistics")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.top, 8)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(PawnTheme.gold.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(PawnTheme.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.footnote)
            }
            Spacer()
        }
    }
}

struct FeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What makes it different")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                FeatureRow(icon: "shippingbox.fill", title: "Real-world runners",
                           subtitle: "Pickup & drop-off, end-to-end handling.")
                FeatureRow(icon: "wand.and.stars.inverse", title: "Item validation",
                           subtitle: "Clean, verify condition before transport.")
                FeatureRow(icon: "location.circle.fill", title: "Geofenced logistics",
                           subtitle: "Smart routing & safe hand-offs.")
                FeatureRow(icon: "creditcard.fill", title: "Apple Pay",
                           subtitle: "Fast, secure checkout.")
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }
}
