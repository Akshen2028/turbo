//
//  CustomCategoriesView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI
import CoreData
import Combine

struct CustomCategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var categoryService: CustomCategoryService
    @State private var showingCreateCategory = false
    @State private var newCategoryName = ""
    @State private var pendingDeleteCategory: CustomCategory?
    
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
                    List {
                        ForEach(categoryService.customCategories) { category in
                            ZStack(alignment: .leading) {
                                // Invisible NavigationLink – still handles the navigation
                                NavigationLink {
                                    QuestionView(
                                        category: Category(
                                            id: -1,
                                            name: category.name,
                                            imageName: "folder.fill",
                                            isCustom: true,
                                            customCategoryId: category.id
                                        )
                                    )
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0)                 // hide it visually, but keep hit-testing

                                // What you actually see in the row
                                CustomCategoryRow(category: category)
                            }
                            .contentShape(Rectangle())      // tap anywhere in the row
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    pendingDeleteCategory = category
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
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
            CreateCategoryView(isPresented: $showingCreateCategory)
        }
        .alert("Delete Category", isPresented: Binding(get: {
            pendingDeleteCategory != nil
        }, set: { newValue in
            if !newValue { pendingDeleteCategory = nil }
        })) {
            Button("Delete", role: .destructive) {
                if let cat = pendingDeleteCategory {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        categoryService.deleteCategory(cat)
                    }
                }
                pendingDeleteCategory = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteCategory = nil
            }
        } message: {
            if let cat = pendingDeleteCategory {
                Text("Are you sure you want to delete \"\(cat.name)\"? All questions in this category will be deleted.")
            } else {
                Text("")
            }
        }
    }
}

#Preview {
    CustomCategoriesView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(CustomCategoryService(context: PersistenceController.shared.container.viewContext))
}

