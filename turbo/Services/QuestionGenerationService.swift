//
//  QuestionGenerationService.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation
import Combine

@MainActor
class QuestionGenerationService: ObservableObject {
    
    // MARK: - Generate Question (Placeholder API)
    
    /// Generates a question for the given category
    /// - Parameter categoryName: The name of the category
    /// - Returns: A generated question string
    func generateQuestion(for categoryName: String) async -> String {
        // TODO: Implement actual AI API call
        // For now, return placeholder with random number for testing
        let randomNumber = Int.random(in: 1...1000)
        return "This is a temp question #\(randomNumber)?"
    }
}

