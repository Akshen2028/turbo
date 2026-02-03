//
//  EditCategoryNameView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct EditCategoryNameView: View {
    let category: CustomCategory
    @State private var currentName: String
    @Binding var isPresented: Bool
    @EnvironmentObject var categoryService: CustomCategoryService
    @FocusState private var isTextFieldFocused: Bool
    
    init(category: CustomCategory, currentName: String, isPresented: Binding<Bool>) {
        self.category = category
        // Initialize with the provided name, or fall back to category name
        let nameToUse = currentName.isEmpty ? category.name : currentName
        self._currentName = State(initialValue: nameToUse)
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Category Name")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                TextField("Category Name", text: $currentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isTextFieldFocused)
                    .onAppear {
                        // Ensure the name is always set to the current category name
                        currentName = category.name
                        // Focus the text field when view appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                
                Button(action: {
                    let trimmedName = currentName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty && trimmedName != category.name {
                        if categoryService.updateCategoryName(category, newName: trimmedName) {
                            isPresented = false
                        }
                    } else if trimmedName == category.name {
                        // No change, just dismiss
                        isPresented = false
                    }
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            currentName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.gray
                            : Color(red: 55/255, green: 213/255, blue: 209/255)
                        )
                        .cornerRadius(12)
                }
                .disabled(currentName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

