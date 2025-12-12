//
//  SaveQuestionView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct SaveQuestionView: View {
    let question: String
    @EnvironmentObject var categoryService: CustomCategoryService
    @Binding var isPresented: Bool
    @State private var frozenQuestion: String = "" // Freeze the question to prevent it from changing
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var showingCreateCategory = false
    @State private var saveSuccess = false
    
    // Track initial state to detect changes
    @State private var initialSavedCategoryIds: Set<UUID> = []
    
    private func isQuestionAlreadySaved(in categoryId: UUID) -> Bool {
        let questionToCheck = frozenQuestion.isEmpty ? question : frozenQuestion
        return categoryService.questionExists(questionToCheck, in: categoryId)
    }
    
    // Check if there are any changes to save
    private var hasChanges: Bool {
        selectedCategoryIds != initialSavedCategoryIds
    }
    
    // Initialize selectedCategoryIds with currently saved categories
    private func initializeSelections() {
        let savedIds = Set(categoryService.customCategories.filter { category in
            isQuestionAlreadySaved(in: category.id)
        }.map { $0.id })
        selectedCategoryIds = savedIds
        initialSavedCategoryIds = savedIds
    }
    
    // Freeze the question when view appears
    private func freezeQuestion() {
        if frozenQuestion.isEmpty {
            frozenQuestion = question
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Question preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Save Question")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(frozenQuestion.isEmpty ? question : frozenQuestion)
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
                            let isOriginallySaved = isQuestionAlreadySaved(in: category.id)
                            let isSelected = selectedCategoryIds.contains(category.id)
                            
                            CategorySelectionRow(
                                category: category,
                                isSelected: isSelected,
                                isOriginallySaved: isOriginallySaved
                            ) {
                                // Just toggle selection - don't save/unsave immediately
                                if isSelected {
                                    selectedCategoryIds.remove(category.id)
                                } else {
                                    selectedCategoryIds.insert(category.id)
                                }
                            }
                        }
                    }
                    
                    PrimaryActionButton("Save", isEnabled: hasChanges) {
                        // Use frozen question to ensure we're working with the original question
                        let questionToSave = frozenQuestion.isEmpty ? question : frozenQuestion
                        
                        // Save to newly selected categories
                        let categoriesToSave = selectedCategoryIds.subtracting(initialSavedCategoryIds)
                        var anySaved = false
                        for id in categoriesToSave {
                            if categoryService.saveQuestion(questionToSave, to: id) {
                                anySaved = true
                            }
                        }
                        
                        // Unsave from deselected categories
                        let categoriesToUnsave = initialSavedCategoryIds.subtracting(selectedCategoryIds)
                        var anyUnsaved = false
                        for id in categoriesToUnsave {
                            if categoryService.unsaveQuestion(questionToSave, from: id) {
                                anyUnsaved = true
                            }
                        }
                        
                        if anySaved || anyUnsaved {
                            saveSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isPresented = false
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
                CreateCategoryView(isPresented: $showingCreateCategory)
            }
            .onAppear {
                // Freeze the question and initialize selections when view appears
                freezeQuestion()
                initializeSelections()
            }
        }
    }
}

