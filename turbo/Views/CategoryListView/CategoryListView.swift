//
//  CategoryListView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import CoreData

struct CategoryListView: View {

    @StateObject private var viewModel = CategoryListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var categoryService = CustomCategoryService(context: PersistenceController.shared.container.viewContext)
    
    private var allCategories: [Category] {
        let customCategories = categoryService.customCategories.map { custom in
            Category(
                id: -1,
                name: custom.name,
                imageName: "folder.fill",
                isCustom: true,
                customCategoryId: custom.id
            )
        }
        return viewModel.categories + customCategories
    }

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
                
                // Custom categories section
                if !categoryService.customCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "My Categories")
                        
                        ForEach(categoryService.customCategories) { customCategory in
                            NavigationLink {
                                QuestionView(category: Category(
                                    id: -1,
                                    name: customCategory.name,
                                    imageName: "folder.fill",
                                    isCustom: true,
                                    customCategoryId: customCategory.id
                                ))
                            } label: {
                                CustomCategoryRow(category: customCategory)
                            }
                        }
                    }
                }
                
                // Manage categories button
                NavigationLink {
                    CustomCategoriesView()
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.gear")
                        Text("Manage My Categories")
                    }
                    .primaryActionButtonStyle()
                }
                .padding()
            }
            .padding(.top)
        }
        .navigationBarTitle("Select Category")
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    NavigationView {
        CategoryListView()
    }
}

