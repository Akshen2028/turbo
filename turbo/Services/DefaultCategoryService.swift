//
//  DefaultCategoryService.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation
import CoreData
import Combine

@MainActor
class DefaultCategoryService: ObservableObject {
    
    private let context: NSManagedObjectContext
    private let seededKey = "defaultCategoriesSeeded"
    
    init(context: NSManagedObjectContext) {
        self.context = context
        seedInitialQuestionsIfNeeded()
    }
    
    // MARK: - Seed Initial Questions
    
    private func seedInitialQuestionsIfNeeded() {
        let hasSeeded = UserDefaults.standard.bool(forKey: seededKey)
        guard !hasSeeded else { return }
        
        seedQuestions()
        UserDefaults.standard.set(true, forKey: seededKey)
    }
    
    private func seedQuestions() {
        let categories: [(Int, [String])] = [
            (0, QuestionData.familyQuestions),
            (1, QuestionData.relationshipQuestions),
            (2, QuestionData.friendQuestions),
            (3, QuestionData.icebreakerQuestions),
            (4, QuestionData.randomQuestions),
            (5, QuestionData.controversialQuestions)
        ]
        
        for (categoryId, questions) in categories {
            for question in questions {
                let entity = DefaultCategoryQuestionEntity(context: context)
                entity.id = UUID()
                entity.categoryId = Int32(categoryId)
                entity.question = question
                entity.createdAt = Date()
                entity.isGenerated = false
            }
        }
        
        do {
            try context.save()
            print("Successfully seeded default category questions")
        } catch {
            print("Failed to seed default category questions: \(error)")
        }
    }
    
    // MARK: - Load Questions
    
    func loadQuestions(for categoryId: Int) -> [String] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d", Int32(categoryId))
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.isGenerated, ascending: true),
            NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.createdAt, ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.question }
        } catch {
            print("Failed to load default category questions: \(error)")
            return []
        }
    }
    
    // MARK: - Add Generated Question
    
    func addGeneratedQuestion(_ question: String, to categoryId: Int) {
        let entity = DefaultCategoryQuestionEntity(context: context)
        entity.id = UUID()
        entity.categoryId = Int32(categoryId)
        entity.question = question
        entity.createdAt = Date()
        entity.isGenerated = true
        
        do {
            try context.save()
            print("Successfully saved generated question to category \(categoryId)")
        } catch {
            print("Failed to save generated question: \(error)")
        }
    }
}

