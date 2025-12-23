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
        // Exclude rejected questions from playable deck
        request.predicate = NSPredicate(format: "categoryId == %d AND (isRejected == NO OR isRejected == nil)", Int32(categoryId))
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
        entity.isRejected = false
        
        do {
            try context.save()
            print("Successfully saved generated question to category \(categoryId)")
        } catch {
            print("Failed to save generated question: \(error)")
        }
    }
    
    // MARK: - Reject Question
    
    /// Marks a question as rejected and keeps only the 20 most recent rejected questions per category
    func rejectQuestion(_ question: String, in categoryId: Int) {
        // First, try to find existing question and mark it as rejected
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d AND question == %@", Int32(categoryId), question)
        
        do {
            let entities = try context.fetch(request)
            if let existingEntity = entities.first {
                // Mark existing question as rejected
                existingEntity.isRejected = true
                existingEntity.rejectedAt = Date()
            } else {
                // Create new rejected question entry
                let entity = DefaultCategoryQuestionEntity(context: context)
                entity.id = UUID()
                entity.categoryId = Int32(categoryId)
                entity.question = question
                entity.createdAt = Date()
                entity.isGenerated = true
                entity.isRejected = true
                entity.rejectedAt = Date()
            }
            
            // Keep only the 20 most recent rejected questions for this category
            let rejectedRequest: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
            rejectedRequest.predicate = NSPredicate(format: "categoryId == %d AND isRejected == YES", Int32(categoryId))
            rejectedRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.rejectedAt, ascending: false)]
            
            let rejectedEntities = try context.fetch(rejectedRequest)
            if rejectedEntities.count > 20 {
                // Delete the oldest rejected questions beyond the 20 most recent
                let entitiesToDelete = Array(rejectedEntities.dropFirst(20))
                for entity in entitiesToDelete {
                    context.delete(entity)
                }
            }
            
            try context.save()
            print("Successfully rejected question in category \(categoryId)")
        } catch {
            print("Failed to reject question: \(error)")
        }
    }
}

