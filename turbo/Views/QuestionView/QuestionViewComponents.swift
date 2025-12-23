//
//  QuestionViewComponents.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

// MARK: - Navigation Arrow Button
struct NavigationArrowButton: View {
    let direction: Direction
    let isEnabled: Bool
    let action: () -> Void
    
    enum Direction {
        case left, right
        
        var systemName: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction.systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isEnabled ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
                .padding(20)
                .background(Color.white)
                .cornerRadius(80.0)
                .shadow(radius: 10)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Category Selection Row
struct CategorySelectionRow: View {
    let category: CustomCategory
    let isSelected: Bool              // Current selection state (includes toggles)
    let isOriginallySaved: Bool       // Was already saved when sheet opened
    let displayCount: Int?            // Optional override for optimistic counts
    let action: () -> Void
    
    private var questionCount: Int {
        displayCount ?? category.questions.count
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        isSelected
                        ? (isOriginallySaved ? .green : Color(red: 55/255, green: 213/255, blue: 209/255))
                        : .gray
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(.black)
                        if isOriginallySaved {
                            Text(isSelected ? "(Tap to unsave)" : "(Will unsave)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Text("\(questionCount) question\(questionCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(
                isSelected
                ? (isOriginallySaved ? Color.green.opacity(0.1) : Color(red: 55/255, green: 213/255, blue: 209/255).opacity(0.1))
                : Color.gray.opacity(0.05)
            )
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Rainbow Spinner
struct RainbowSpinner: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.9, blue: 0.2),   // Yellow
                            Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
                            Color(red: 1.0, green: 0.3, blue: 0.6),   // Pink
                            Color(red: 0.7, green: 0.2, blue: 0.8),   // Purple
                            Color(red: 0.4, green: 0.4, blue: 1.0),   // Blue-purple
                            Color(red: 0.2, green: 0.6, blue: 1.0),   // Bright blue
                            Color(red: 0.1, green: 0.7, blue: 1.0),   // Clear blue
                            Color(red: 1.0, green: 0.9, blue: 0.2)    // Back to yellow
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

