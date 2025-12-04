//
//  HomeComponents.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

// MARK: - Primary Rounded Button (Teal)
extension View {
    func homePrimaryButton() -> some View {
        self
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(
                Color(red: 55/255, green: 213/255, blue: 209/255)
            )
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Secondary Button (White w/ Teal Text)
extension View {
    func homeSecondaryButton(tealColor: Color) -> some View {
        self
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(tealColor)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(Color.white)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Info Button (White background, Teal icon)
struct InfoNavButton: View {
    var body: some View {
        NavigationLink(destination: AboutView()) {
            Image(systemName: "info.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .padding(-7)          // EXACT padding from old app
                .background(Color.white)
                .padding(13)          // Outer padding
                .cornerRadius(20)
                .shadow(radius: 12)
                .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
        }
    }
}

// MARK: - Help Button (Teal background, White icon)
struct HelpNavButton: View {
    var body: some View {
        NavigationLink(destination: HelpView()) {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .padding(-7)
                .background(Color(red: 55/255, green: 213/255, blue: 209/255))
                .padding(13)
                .cornerRadius(20)
                .shadow(radius: 12)
                .foregroundColor(.white)
        }
    }
}
