//
//  CategoryListView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import CoreData

struct CategoryListView: View {

    @StateObject private var viewModel = CategoryListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var categoryService = CustomCategoryService(context: PersistenceController.shared.container.viewContext)

    // gradient from old DeckView
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end   = UnitPoint(x: 4, y: 0)
    private let colors = [
        Color.white,
        Color.white,
        Color(red: 55/255, green: 213/255, blue: 209/255)
    ]
    
    private var allCategories: [Category] {
        let customCategories = categoryService.customCategories.map { custom in
            Category(
                id: -1,
                name: custom.name,
                imageName: "folder.fill",
                isCustom: true,
                customCategoryId: custom.id
            )
        }
        return viewModel.categories + customCategories
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: start,
                endPoint: end
            )
            .ignoresSafeArea()

            ScrollView {
                // Regular categories
                ForEach(viewModel.categories) { category in
                    NavigationLink {
                        QuestionView(category: category)
                    } label: {
                        ZStack(alignment: .leading) {
                            Image(category.imageName)
                                .resizable()
                                .cornerRadius(12)
                                .aspectRatio(contentMode: .fit)
                                .padding(40)
                                .background(Color.white)
                                .cornerRadius(30)
                                .padding(10)
                                .shadow(radius: 6)
                                .padding(.horizontal)

                            HStack {
                                Spacer()
                                Text(category.name)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .font(.system(size: 20))
                                    .background(
                                        Color(red: 55/255, green: 213/255, blue: 209/255)
                                    )
                                    .cornerRadius(80.0)
                                    .shadow(radius: 10)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Custom categories section
                if !categoryService.customCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        ForEach(categoryService.customCategories) { customCategory in
                            NavigationLink {
                                QuestionView(category: Category(
                                    id: -1,
                                    name: customCategory.name,
                                    imageName: "folder.fill",
                                    isCustom: true,
                                    customCategoryId: customCategory.id
                                ))
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                                        .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(customCategory.name)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text("\(customCategory.questions.count) question\(customCategory.questions.count == 1 ? "" : "s")")
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
                }
                
                // Manage categories button
                NavigationLink {
                    CustomCategoriesView()
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.gear")
                        Text("Manage My Categories")
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
            .padding(.top)
        }
        .navigationBarTitle("Select Category")
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    NavigationView {
        CategoryListView()
    }
}
