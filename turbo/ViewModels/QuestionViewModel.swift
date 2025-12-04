//
//  Untitled.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation
import Combine

@MainActor
class QuestionViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var currentIndex: Int = 0

    init(category: Category) {
        self.cards = category.questions.map { Card(text: $0) }
    }

    var currentCard: Card? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    func nextQuestion() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
        } else {
            // Later: handle end-of-category behavior
        }
    }
}
