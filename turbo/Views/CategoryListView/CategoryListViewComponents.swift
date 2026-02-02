//
//  CategoryListViewComponents.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

// MARK: - Regular Category Card
struct CategoryCard: View {
    let category: Category
    @State private var showNewBadge: Bool = false
    
    private var isWouldYouRather: Bool {
        category.id == 6 && category.name == "Would You Rather"
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Image(category.imageName)
                .resizable()
                .cornerRadius(12)
                .aspectRatio(contentMode: .fit)
                .padding(40)
                .background(Color.white)
                .cornerRadius(30)
                .padding(10)
                .shadow(radius: 6)
                .padding(.horizontal)
            
            HStack {
                Spacer()
                Text(category.name)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(20)
                    .font(.system(size: 20))
                    .background(
                        Color(red: 55/255, green: 213/255, blue: 209/255)
                    )
                    .cornerRadius(80.0)
                    .shadow(radius: 10)
                Spacer()
            }
            
            // NEW badge for Would You Rather category
            if showNewBadge && isWouldYouRather {
                VStack {
                    HStack {
                        Spacer()
                        Text("NEW")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
                                        Color(red: 1.0, green: 0.3, blue: 0.6)    // Pink
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .padding(.top, 10)
                            .padding(.trailing, 30)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if isWouldYouRather {
                let hasInteracted = UserDefaults.standard.bool(forKey: "hasInteractedWithWouldYouRather")
                showNewBadge = !hasInteracted
            }
        }
    }
}

