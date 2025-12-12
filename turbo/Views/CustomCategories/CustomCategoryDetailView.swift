//
//  CustomCategoryDetailView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct CustomCategoryDetailView: View {
    let category: CustomCategory
    /// Optional callback to let a parent view (e.g., QuestionView) dismiss itself when the category is deleted.
    let onCategoryDeleted: (() -> Void)?
    @EnvironmentObject var categoryService: CustomCategoryService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    // Get the current category from the service to reflect real-time updates
    private var currentCategory: CustomCategory? {
        categoryService.customCategories.first { $0.id == category.id }
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            if let currentCategory = currentCategory {
                if currentCategory.questions.isEmpty {
                    EmptyStateView(
                        icon: "questionmark.circle",
                        title: "No Questions Yet",
                        message: "Save questions from other categories to this category!"
                    )
                } else {
                    List {
                        ForEach(currentCategory.questions) { question in
                            QuestionCard(question: question.question)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(question: question)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            } else {
                // Fallback if category not found (shouldn't happen, but handle gracefully)
                EmptyStateView(
                    icon: "questionmark.circle",
                    title: "Category Not Found",
                    message: "This category may have been deleted."
                )
            }
        }
        .navigationTitle(currentCategory?.name ?? category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if let currentCategory = currentCategory {
                        categoryService.deleteCategory(currentCategory)
                    } else {
                        categoryService.deleteCategory(category)
                    }
                    // Pop this detail view, then ask parent to pop QuestionView.
                    // Use no-animation dismiss to avoid intermediate flicker.
                    let transaction = Transaction(animation: .none)
                    withTransaction(transaction) {
                        dismiss()
                    }
                    DispatchQueue.main.async {
                        onCategoryDeleted?()
                    }
                }
            }
        } message: {
            let categoryName = currentCategory?.name ?? category.name
            Text("Are you sure you want to delete \"\(categoryName)\"? All questions in this category will be deleted.")
        }
    }

    // MARK: - Helpers
    private func delete(question: SavedQuestion) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let currentCategory = currentCategory {
                categoryService.deleteQuestion(question, from: currentCategory.id)
            } else {
                categoryService.deleteQuestion(question, from: category.id)
            }
        }
    }
}

