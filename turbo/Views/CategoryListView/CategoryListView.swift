//
//  CategoryListView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
struct CategoryListView: View {

    @StateObject private var viewModel = CategoryListViewModel()

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                // Regular categories
                ForEach(viewModel.categories) { category in
                    NavigationLink {
                        QuestionView(category: category)
                    } label: {
                        CategoryCard(category: category)
                    }
                }
            }
            .padding(.top)
        }
        .navigationBarTitle("Select Category")
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
    }
}

