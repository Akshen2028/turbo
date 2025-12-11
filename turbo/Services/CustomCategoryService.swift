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
            customCategories = entities.map { entity in
                CustomCategory(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    createdAt: entity.createdAt ?? Date(),
                    questions: loadQuestions(for: entity)
                )
            }
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
            questionEntity.setValue(categoryEntity, forKey: "category")
            
            try context.save()
            loadCategories()
            return true
        } catch {
            print("Failed to save question: \(error)")
            return false
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
