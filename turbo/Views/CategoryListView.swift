//
//  CategoryListView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct CategoryListView: View {

    @StateObject private var viewModel = CategoryListViewModel()

    // gradient from old DeckView
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end   = UnitPoint(x: 4, y: 0)
    private let colors = [
        Color.white,
        Color.white,
        Color(red: 55/255, green: 213/255, blue: 209/255)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: start,
                endPoint: end
            )
            .ignoresSafeArea()

            ScrollView {
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
