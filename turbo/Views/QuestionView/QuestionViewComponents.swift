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
    let isSelected: Bool
    let isAlreadySaved: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isAlreadySaved || isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isAlreadySaved ? .green : (isSelected ? Color(red: 55/255, green: 213/255, blue: 209/255) : .gray))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(.black)
                        if isAlreadySaved {
                            Text("(Tap to unsave)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Text("\(category.questions.count) question\(category.questions.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(isAlreadySaved ? Color.green.opacity(0.1) : (isSelected ? Color(red: 55/255, green: 213/255, blue: 209/255).opacity(0.1) : Color.gray.opacity(0.05)))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

