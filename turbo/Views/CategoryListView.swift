//
//  CategoryListView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct CategoryListView: View {
    @StateObject private var viewModel = CategoryViewModel()

    var body: some View {
        List(viewModel.categories) { category in
            NavigationLink(destination: QuestionView(category: category)) {
                HStack {
                    Image(category.imageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(category.title)
                        .font(.headline)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Select Category")
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
    }
}
