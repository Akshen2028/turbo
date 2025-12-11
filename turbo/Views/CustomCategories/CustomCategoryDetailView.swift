//
//  CustomCategoryDetailView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct CustomCategoryDetailView: View {
    let category: CustomCategory
    @ObservedObject var categoryService: CustomCategoryService
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            if category.questions.isEmpty {
                EmptyStateView(
                    icon: "questionmark.circle",
                    title: "No Questions Yet",
                    message: "Save questions from other categories to this category!"
                )
            } else {
                List {
                    ForEach(category.questions) { question in
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
        }
        .navigationTitle(category.name)
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
                categoryService.deleteCategory(category)
            }
        } message: {
            Text("Are you sure you want to delete \"\(category.name)\"? All questions in this category will be deleted.")
        }
    }

    // MARK: - Helpers
    private func delete(question: SavedQuestion) {
        categoryService.deleteQuestion(question, from: category.id)
    }
}

