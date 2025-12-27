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
        if !hasSeeded {
            seedQuestions()
            UserDefaults.standard.set(true, forKey: seededKey)
        } else {
            // Check if Would You Rather category (id: 6) needs to be seeded for existing users
            seedWouldYouRatherIfNeeded()
        }
    }
    
    private func seedWouldYouRatherIfNeeded() {
        let wouldYouRatherSeededKey = "wouldYouRatherSeeded"
        let hasSeeded = UserDefaults.standard.bool(forKey: wouldYouRatherSeededKey)
        guard !hasSeeded else { return }
        
        // Check if category 6 already has questions
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d", Int32(6))
        request.fetchLimit = 1
        
        do {
            let existingQuestions = try context.fetch(request)
            if existingQuestions.isEmpty {
                // Seed Would You Rather questions
                for question in QuestionData.wouldYouRatherQuestions {
                    let entity = DefaultCategoryQuestionEntity(context: context)
                    entity.id = UUID()
                    entity.categoryId = Int32(6)
                    entity.question = question
                    entity.createdAt = Date()
                    entity.isGenerated = false
                }
                try context.save()
                print("Successfully seeded Would You Rather category questions")
            }
            UserDefaults.standard.set(true, forKey: wouldYouRatherSeededKey)
        } catch {
            print("Failed to seed Would You Rather questions: \(error)")
        }
    }
    
    private func seedQuestions() {
        let categories: [(Int, [String])] = [
            (0, QuestionData.familyQuestions),
            (1, QuestionData.relationshipQuestions),
            (2, QuestionData.friendQuestions),
            (3, QuestionData.icebreakerQuestions),
            (4, QuestionData.randomQuestions),
            (5, QuestionData.controversialQuestions),
            (6, QuestionData.wouldYouRatherQuestions)
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
    
    // MARK: - Get Most Recent Generated Liked Question
    
    /// Returns the most recent generated question that was liked (not rejected) for the category
    func getMostRecentGeneratedLikedQuestion(for categoryId: Int) -> String? {
        let questions = getRecentLikedQuestions(for: categoryId, limit: 1)
        return questions.first
    }
    
    /// Returns up to the specified number of most recent generated questions that were liked (not rejected) for the category
    func getRecentLikedQuestions(for categoryId: Int, limit: Int = 10) -> [String] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        // Get generated questions that are not rejected, sorted by creation date descending
        request.predicate = NSPredicate(format: "categoryId == %d AND isGenerated == YES AND (isRejected == NO OR isRejected == nil)", Int32(categoryId))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.question }
        } catch {
            print("Failed to get recent liked questions: \(error)")
            return []
        }
    }
    
    /// Returns up to the specified number of most recent generated questions that were rejected for the category
    func getRecentDislikedQuestions(for categoryId: Int, limit: Int = 10) -> [String] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        // Get generated questions that were rejected, sorted by rejection date descending
        request.predicate = NSPredicate(format: "categoryId == %d AND isGenerated == YES AND isRejected == YES", Int32(categoryId))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.rejectedAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.question }
        } catch {
            print("Failed to get recent disliked questions: \(error)")
            return []
        }
    }
    
    /// Returns up to the specified number of most recent generated questions that were rejected with their reasons for the category
    func getRecentDislikedQuestionsWithReasons(for categoryId: Int, limit: Int = 10) -> [(question: String, reason: String?)] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        // Get generated questions that were rejected, sorted by rejection date descending
        request.predicate = NSPredicate(format: "categoryId == %d AND isGenerated == YES AND isRejected == YES", Int32(categoryId))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DefaultCategoryQuestionEntity.rejectedAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let question = entity.question else { return nil }
                return (question: question, reason: entity.rejectionReason)
            }
        } catch {
            print("Failed to get recent disliked questions with reasons: \(error)")
            return []
        }
    }
    
    /// Returns ALL generated questions that were rejected with their reasons for the category (for random selection)
    func getAllDislikedQuestionsWithReasons(for categoryId: Int) -> [(question: String, reason: String?)] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d AND isGenerated == YES AND isRejected == YES", Int32(categoryId))
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let question = entity.question else { return nil }
                return (question: question, reason: entity.rejectionReason)
            }
        } catch {
            print("Failed to get all disliked questions with reasons: \(error)")
            return []
        }
    }
    
    /// Returns ALL generated questions that were liked for the category (for random selection)
    func getAllLikedQuestions(for categoryId: Int) -> [String] {
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d AND isGenerated == YES AND (isRejected == NO OR isRejected == nil)", Int32(categoryId))
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.question }
        } catch {
            print("Failed to get all liked questions: \(error)")
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
    
    /// Marks a question as rejected (keeps all rejected questions)
    func rejectQuestion(_ question: String, in categoryId: Int, reason: String? = nil) {
        // First, try to find existing question and mark it as rejected
        let request: NSFetchRequest<DefaultCategoryQuestionEntity> = DefaultCategoryQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %d AND question == %@", Int32(categoryId), question)
        
        do {
            let entities = try context.fetch(request)
            if let existingEntity = entities.first {
                // Mark existing question as rejected
                existingEntity.isRejected = true
                existingEntity.rejectedAt = Date()
                existingEntity.rejectionReason = reason
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
                entity.rejectionReason = reason
            }
            
            try context.save()
            print("Successfully rejected question in category \(categoryId)")
        } catch {
            print("Failed to reject question: \(error)")
        }
    }
}

