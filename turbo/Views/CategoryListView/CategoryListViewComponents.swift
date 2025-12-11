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
        }
    }
}

