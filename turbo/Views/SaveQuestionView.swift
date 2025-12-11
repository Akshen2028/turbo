//
//  SaveQuestionView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct SaveQuestionView: View {
    let question: String
    @ObservedObject var categoryService: CustomCategoryService
    @Binding var isPresented: Bool
    @State private var selectedCategoryId: UUID?
    @State private var showingCreateCategory = false
    @State private var saveSuccess = false
    
    private func isQuestionAlreadySaved(in categoryId: UUID) -> Bool {
        categoryService.questionExists(question, in: categoryId)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Question preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Save Question")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(question)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
                
                if categoryService.customCategories.isEmpty {
                    VStack(spacing: 20) {
                        EmptyStateView(
                            icon: "folder.badge.plus",
                            title: "No Categories Yet",
                            message: "Create a category first to save questions"
                        )
                        
                        PrimaryActionButton("Create Category") {
                            showingCreateCategory = true
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        ForEach(categoryService.customCategories) { category in
                            let isAlreadySaved = isQuestionAlreadySaved(in: category.id)
                            let isSelected = selectedCategoryId == category.id
                            
                            CategorySelectionRow(
                                category: category,
                                isSelected: isSelected,
                                isAlreadySaved: isAlreadySaved
                            ) {
                                if isAlreadySaved {
                                    // Unsave the question
                                    if categoryService.unsaveQuestion(question, from: category.id) {
                                        // Question was unsaved, refresh the view
                                        selectedCategoryId = nil
                                    }
                                } else {
                                    // Select to save
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                    }
                    
                    PrimaryActionButton("Save", isEnabled: selectedCategoryId != nil) {
                        if let categoryId = selectedCategoryId {
                            if categoryService.saveQuestion(question, to: categoryId) {
                                saveSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .padding()
                    
                    if saveSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Saved!")
                        }
                        .foregroundColor(.green)
                        .font(.headline)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCategoryView(categoryService: categoryService, isPresented: $showingCreateCategory)
            }
        }
    }
}

