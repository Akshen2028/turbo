//
//  CustomCategoryComponents.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

// MARK: - Custom Category Row (was shared; now used only in CustomCategories)
struct CustomCategoryRow: View {
    let category: CustomCategory
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.system(size: 30))
                .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("\(category.questions.count) question\(category.questions.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(3)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

// MARK: - Question Card
struct QuestionCard: View {
    let question: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.body)
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

