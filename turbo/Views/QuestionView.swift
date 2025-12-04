//
//  QuestionView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct QuestionView: View {
    @StateObject private var viewModel: QuestionViewModel

    init(category: Category) {
        _viewModel = StateObject(wrappedValue: QuestionViewModel(category: category))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let card = viewModel.currentCard {
                Text(card.text)
                    .font(.title)
                    .padding()
            } else {
                Text("No more questions.")
                    .font(.headline)
            }

            Button("Next Question") {
                viewModel.nextQuestion()
            }
            .padding()
        }
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    NavigationStack {
        QuestionView(category: Category(
            title: "Sample",
            imageName: "sample",
            questions: ["Test question 1", "Test question 2"]
        ))
    }
}
