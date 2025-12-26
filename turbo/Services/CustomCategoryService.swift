//
//  CustomCategoryService.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class CustomCategoryService: ObservableObject {
    @Published var customCategories: [CustomCategory] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadCategories()
    }
    
    // MARK: - Load Categories
    
    func loadCategories() {
        let request: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CustomCategoryEntity.createdAt, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            // Create a completely new array to ensure SwiftUI detects the change
            let newCategories = entities.map { entity in
                CustomCategory(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    createdAt: entity.createdAt ?? Date(),
                    questions: loadQuestions(for: entity)
                )
            }
            // Explicitly assign to trigger @Published
            customCategories = newCategories
        } catch {
            print("Failed to load custom categories: \(error)")
            customCategories = []
        }
    }
    
    private func loadQuestions(for category: CustomCategoryEntity) -> [SavedQuestion] {
        // Try to access the relationship - it might be named "questions" or something else
        // First, try to fetch questions directly using a relationship fetch
        let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let questions = try context.fetch(request)
            return questions.compactMap { entity in
                guard let question = entity.value(forKey: "question") as? String,
                      let id = entity.value(forKey: "id") as? UUID,
                      let createdAt = entity.value(forKey: "createdAt") as? Date else {
                    return nil
                }
                // Skip rejected questions - they shouldn't appear in playable deck
                let isRejected = entity.value(forKey: "isRejected") as? Bool ?? false
                if isRejected {
                    return nil
                }
                return SavedQuestion(
                    id: id,
                    question: question,
                    createdAt: createdAt
                )
            }
        } catch {
            print("Failed to load questions: \(error)")
            return []
        }
    }
    
    // MARK: - Create Category
    
    func createCategory(name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        let entity = CustomCategoryEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.createdAt = Date()
        
        do {
            try context.save()
            loadCategories()
            return true
        } catch {
            print("Failed to create category: \(error)")
            return false
        }
    }
    
    // MARK: - Delete Category
    
    func deleteCategory(_ category: CustomCategory) {
        let request: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
                loadCategories()
            }
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
    
    // MARK: - Check if Question Exists
    
    func questionExists(_ question: String, in categoryId: UUID) -> Bool {
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return false
            }
            
            let checkRequest: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            checkRequest.predicate = NSPredicate(format: "category == %@", categoryEntity)
            
            let existingQuestions = try context.fetch(checkRequest)
            return existingQuestions.contains(where: { ($0.value(forKey: "question") as? String) == question })
        } catch {
            print("Failed to check if question exists: \(error)")
            return false
        }
    }
    
    // MARK: - Get Most Recent Generated Liked Question
    
    /// Returns the most recent generated question that was liked (not rejected) for the category
    func getMostRecentGeneratedLikedQuestion(for categoryId: UUID) -> String? {
        let questions = getRecentLikedQuestions(for: categoryId, limit: 1)
        return questions.first
    }
    
    /// Returns up to the specified number of most recent questions that were liked (not rejected) for the category
    func getRecentLikedQuestions(for categoryId: UUID, limit: Int = 10) -> [String] {
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return []
            }
            
            let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            // Get questions that are not rejected, sorted by creation date descending
            request.predicate = NSPredicate(format: "category == %@ AND (isRejected == NO OR isRejected == nil)", categoryEntity)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = limit
            
            let questions = try context.fetch(request)
            return questions.compactMap { entity in
                entity.value(forKey: "question") as? String
            }
        } catch {
            print("Failed to get recent liked questions: \(error)")
            return []
        }
    }
    
    /// Returns up to the specified number of most recent rejected questions for the category
    func getRecentDislikedQuestions(for categoryId: UUID, limit: Int = 10) -> [String] {
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return []
            }
            
            let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            // Get rejected questions, sorted by rejection date descending
            request.predicate = NSPredicate(format: "category == %@ AND isRejected == YES", categoryEntity)
            request.sortDescriptors = [NSSortDescriptor(key: "rejectedAt", ascending: false)]
            request.fetchLimit = limit
            
            let questions = try context.fetch(request)
            return questions.compactMap { entity in
                entity.value(forKey: "question") as? String
            }
        } catch {
            print("Failed to get recent disliked questions: \(error)")
            return []
        }
    }
    
    /// Returns up to the specified number of most recent rejected questions with their reasons for the category
    func getRecentDislikedQuestionsWithReasons(for categoryId: UUID, limit: Int = 10) -> [(question: String, reason: String?)] {
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return []
            }
            
            let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            // Get rejected questions, sorted by rejection date descending
            request.predicate = NSPredicate(format: "category == %@ AND isRejected == YES", categoryEntity)
            request.sortDescriptors = [NSSortDescriptor(key: "rejectedAt", ascending: false)]
            request.fetchLimit = limit
            
            let questions = try context.fetch(request)
            return questions.compactMap { entity in
                guard let question = entity.value(forKey: "question") as? String else {
                    return nil
                }
                let reason = entity.value(forKey: "rejectionReason") as? String
                return (question: question, reason: reason)
            }
        } catch {
            print("Failed to get recent disliked questions with reasons: \(error)")
            return []
        }
    }
    
    // MARK: - Save Question
    
    func saveQuestion(_ question: String, to categoryId: UUID) -> Bool {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        // Find the category
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return false
            }
            
            // Check if question already exists in this category by fetching all questions
            // and checking in memory (since we can't rely on attribute names in predicate)
            let checkRequest: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            checkRequest.predicate = NSPredicate(format: "category == %@", categoryEntity)
            
            let existingQuestions = try context.fetch(checkRequest)
            if existingQuestions.contains(where: { ($0.value(forKey: "question") as? String) == question }) {
                return false // Question already exists
            }
            
            // Create new question using KVC
            let questionEntity = SavedQuestionEntity(context: context)
            questionEntity.setValue(UUID(), forKey: "id")
            questionEntity.setValue(question, forKey: "question")
            questionEntity.setValue(Date(), forKey: "createdAt")
            questionEntity.setValue(false, forKey: "isRejected")  // New questions are not rejected
            questionEntity.setValue(categoryEntity, forKey: "category")
            
            try context.save()
            loadCategories()
            return true
        } catch {
            print("Failed to save question: \(error)")
            return false
        }
    }
    
    // MARK: - Reject Question
    
    /// Marks a question as rejected and keeps only the 20 most recent rejected questions per category
    func rejectQuestion(_ question: String, in categoryId: UUID, reason: String? = nil) {
        // Find the category
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return
            }
            
            // Try to find existing question and mark it as rejected
            let questionRequest: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            questionRequest.predicate = NSPredicate(format: "category == %@", categoryEntity)
            
            let questions = try context.fetch(questionRequest)
            if let existingQuestion = questions.first(where: { ($0.value(forKey: "question") as? String) == question }) {
                // Mark existing question as rejected
                existingQuestion.setValue(true, forKey: "isRejected")
                existingQuestion.setValue(Date(), forKey: "rejectedAt")
                existingQuestion.setValue(reason, forKey: "rejectionReason")
            } else {
                // Create new rejected question entry
                let questionEntity = SavedQuestionEntity(context: context)
                questionEntity.setValue(UUID(), forKey: "id")
                questionEntity.setValue(question, forKey: "question")
                questionEntity.setValue(Date(), forKey: "createdAt")
                questionEntity.setValue(true, forKey: "isRejected")
                questionEntity.setValue(Date(), forKey: "rejectedAt")
                questionEntity.setValue(reason, forKey: "rejectionReason")
                questionEntity.setValue(categoryEntity, forKey: "category")
            }
            
            // Keep only the 20 most recent rejected questions for this category
            let rejectedRequest: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            rejectedRequest.predicate = NSPredicate(format: "category == %@ AND isRejected == YES", categoryEntity)
            rejectedRequest.sortDescriptors = [NSSortDescriptor(key: "rejectedAt", ascending: false)]
            
            let rejectedQuestions = try context.fetch(rejectedRequest)
            if rejectedQuestions.count > 20 {
                // Delete the oldest rejected questions beyond the 20 most recent
                let questionsToDelete = Array(rejectedQuestions.dropFirst(20))
                for questionEntity in questionsToDelete {
                    context.delete(questionEntity)
                }
            }
            
            try context.save()
            loadCategories()  // Reload to update the view
            print("Successfully rejected question in custom category")
        } catch {
            print("Failed to reject question: \(error)")
        }
    }
    
    // MARK: - Delete Question
    
    func deleteQuestion(_ question: SavedQuestion, from categoryId: UUID) {
        let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", question.id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
                loadCategories()
            }
        } catch {
            print("Failed to delete question: \(error)")
        }
    }
    
    // Delete question by index set (for List swipe-to-delete)
    func deleteQuestion(at offsets: IndexSet, in category: CustomCategory) {
        let idsToDelete = offsets.compactMap { category.questions[$0].id }
        let request: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", idsToDelete)
        
        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            try context.save()
            loadCategories()
        } catch {
            print("Failed to delete questions by offsets: \(error)")
        }
    }
    
    // MARK: - Unsave Question (delete by question text)
    
    func unsaveQuestion(_ question: String, from categoryId: UUID) -> Bool {
        let categoryRequest: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            guard let categoryEntity = try context.fetch(categoryRequest).first else {
                return false
            }
            
            // Find the question by text in this category
            let questionRequest: NSFetchRequest<SavedQuestionEntity> = SavedQuestionEntity.fetchRequest()
            questionRequest.predicate = NSPredicate(format: "category == %@", categoryEntity)
            
            let questions = try context.fetch(questionRequest)
            if let questionEntity = questions.first(where: { ($0.value(forKey: "question") as? String) == question }) {
                context.delete(questionEntity)
                try context.save()
                loadCategories()
                return true
            }
            return false
        } catch {
            print("Failed to unsave question: \(error)")
            return false
        }
    }
}
