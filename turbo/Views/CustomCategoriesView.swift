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
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.white,
                        Color(red: 55/255, green: 213/255, blue: 209/255)
                    ]),
                    startPoint: UnitPoint(x: 0, y: -2),
                    endPoint: UnitPoint(x: 4, y: 0)
                )
                .ignoresSafeArea()
                
                VStack {
                    if categoryService.customCategories.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Custom Categories Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            Text("Create your first category to start saving questions!")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 100)
                    } else {
                        ScrollView {
                            ForEach(categoryService.customCategories) { category in
                                NavigationLink {
                                    CustomCategoryDetailView(category: category, categoryService: categoryService)
                                } label: {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                                            .frame(width: 50)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(category.name)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                            Text("\(category.questions.count) question\(category.questions.count == 1 ? "" : "s")")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingCreateCategory = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Category")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 55/255, green: 213/255, blue: 209/255))
                        .cornerRadius(12)
                        .shadow(radius: 4)
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
}

struct CreateCategoryView: View {
    @ObservedObject var categoryService: CustomCategoryService
    @Binding var isPresented: Bool
    @State private var categoryName = ""
    
    var body: some View {
        NavigationView {
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

struct CustomCategoryDetailView: View {
    let category: CustomCategory
    @ObservedObject var categoryService: CustomCategoryService
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.white,
                    Color(red: 55/255, green: 213/255, blue: 209/255)
                ]),
                startPoint: UnitPoint(x: 0, y: -2),
                endPoint: UnitPoint(x: 4, y: 0)
            )
            .ignoresSafeArea()
            
            if category.questions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Questions Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Text("Save questions from other categories to this category!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    ForEach(category.questions) { question in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question.question)
                                .font(.body)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top)
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
}

#Preview {
    CustomCategoriesView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

