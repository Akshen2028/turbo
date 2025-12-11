//
//  CustomCategoriesView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI
import CoreData

struct CustomCategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var categoryService = CustomCategoryService(context: PersistenceController.shared.container.viewContext)
    @State private var showingCreateCategory = false
    @State private var newCategoryName = ""
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack {
                if categoryService.customCategories.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No Custom Categories Yet",
                        message: "Create your first category to start saving questions!"
                    )
                } else {
                    ScrollView {
                        Spacer()
                        ForEach(categoryService.customCategories) { category in
                            NavigationLink {
                                CustomCategoryDetailView(category: category, categoryService: categoryService)
                            } label: {
                                CustomCategoryRow(category: category)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
                
                PrimaryActionButton("Create New Category", icon: "plus.circle.fill") {
                    showingCreateCategory = true
                }
                .padding()
            }
        }
        .navigationTitle("My Categories")
        .sheet(isPresented: $showingCreateCategory) {
            CreateCategoryView(categoryService: categoryService, isPresented: $showingCreateCategory)
        }
    }
}

#Preview {
    CustomCategoriesView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

