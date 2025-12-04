//
//  CategoryViewModel.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    var a = 2

    init() {
        loadCategories()
    }

    private func loadCategories() {
        categories = [
            Category(
                title: "Family",
                imageName: "family",
                questions: [
                    "What is one of your favourite childhood memories?",
                    "What’s a lesson you learned from your parents?",
                    "Who in your family do you feel closest to and why?"
                ]
            ),
            Category(
                title: "Friends",
                imageName: "friends",
                questions: [
                    "What moment made us become closer friends?",
                    "What’s something I do that makes you feel supported?",
                    "What’s a memory with friends you’ll never forget?"
                ]
            )
            // You can add more categories here later (Dating, Deep, Fun, Icebreakers, etc.)
        ]
    }
}
