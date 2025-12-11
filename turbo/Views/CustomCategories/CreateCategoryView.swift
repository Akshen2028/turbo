//
//  CreateCategoryView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct CreateCategoryView: View {
    @ObservedObject var categoryService: CustomCategoryService
    @Binding var isPresented: Bool
    @State private var categoryName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create New Category")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                TextField("Category Name", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if categoryService.createCategory(name: categoryName) {
                        isPresented = false
                        categoryName = ""
                    }
                }) {
                    Text("Create")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(categoryName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color(red: 55/255, green: 213/255, blue: 209/255))
                        .cornerRadius(12)
                }
                .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
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

