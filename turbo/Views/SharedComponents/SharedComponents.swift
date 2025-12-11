//
//  SharedComponents.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

// MARK: - Gradient Background
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white,
                Color.white,
                Color(red: 55/255, green: 213/255, blue: 209/255)
            ]),
            startPoint: UnitPoint(x: 0, y: -2),
            endPoint: UnitPoint(x: 4, y: 0)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Primary Action Button
struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let isEnabled: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Primary Action Button Style (for use in NavigationLink)
struct PrimaryActionButtonStyle: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

extension View {
    func primaryActionButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryActionButtonStyle(isEnabled: isEnabled))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 100)
    }
}

