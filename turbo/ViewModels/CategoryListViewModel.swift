//
//  CategoryViewModel.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import Combine

@MainActor
class CategoryListViewModel: ObservableObject {

    // Same categories, same ids, same images as old DeckView
    @Published var categories: [Category] = [
        Category(id: 0, name: "Family",        imageName: "family"),
        Category(id: 2, name: "Friends",       imageName: "friends"),
        Category(id: 1, name: "Relationships", imageName: "rose"),
        Category(id: 3, name: "Icebreakers",   imageName: "ice"),
        Category(id: 5, name: "Controversial", imageName: "balance"),
        Category(id: 4, name: "Random",        imageName: "dices")
    ]
}
