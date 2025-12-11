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
    
    var body: some View {
        NavigationView {
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
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Categories Yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Create a category first to save questions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showingCreateCategory = true
                        }) {
                            Text("Create Category")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 55/255, green: 213/255, blue: 209/255))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        ForEach(categoryService.customCategories) { category in
                            Button(action: {
                                selectedCategoryId = category.id
                            }) {
                                HStack {
                                    Image(systemName: selectedCategoryId == category.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedCategoryId == category.id ? Color(red: 55/255, green: 213/255, blue: 209/255) : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.name)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text("\(category.questions.count) question\(category.questions.count == 1 ? "" : "s")")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(selectedCategoryId == category.id ? Color(red: 55/255, green: 213/255, blue: 209/255).opacity(0.1) : Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Button(action: {
                        if let categoryId = selectedCategoryId {
                            if categoryService.saveQuestion(question, to: categoryId) {
                                saveSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isPresented = false
                                }
                            }
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedCategoryId != nil ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedCategoryId == nil)
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

