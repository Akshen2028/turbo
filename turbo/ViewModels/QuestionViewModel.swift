//
//  Untitled.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import Combine
import CoreData

@MainActor
class QuestionViewModel: ObservableObject {

    // Cards for the currently selected category
    @Published var cards: [Card] = []
    @Published var swipedCount: Int = 0

    // Screen width used for swipe thresholds
    private let width = UIScreen.main.bounds.width

    let category: Category
    var categoryService: CustomCategoryService? {
        didSet {
            setupServiceObservation()
        }
    }
    var defaultCategoryService: DefaultCategoryService? {
        didSet {
            loadCards()
        }
    }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(category: Category) {
        self.category = category
        // Initialize with starter card immediately to prevent fade-in
        let starter = Card(q: "Swipe left for a question...")
        cards = [starter]
    }
    
    // MARK: - Service Observation
    
    private func setupServiceObservation() {
        guard let categoryService = categoryService, category.isCustom else { return }
        
        // Clear any existing subscriptions
        cancellables.removeAll()
        
        // Observe changes to custom categories and reload if this category's questions changed
        categoryService.$customCategories
            .dropFirst() // Skip initial value
            .sink { [weak self] categories in
                guard let self = self else { return }
                // Check if this category's questions changed
                if let updatedCategory = categories.first(where: { $0.id == self.category.customCategoryId }) {
                    let oldCount = self.cards.count - 1 // Subtract starter card
                    let newCount = updatedCategory.questions.count
                    if oldCount != newCount {
                        // Reload cards to reflect the change
                        let oldSwipedCount = self.swipedCount
                        self.loadCards()
                        // Reset swipedCount if it's beyond the new card count
                        if oldSwipedCount >= self.cards.count {
                            self.swipedCount = max(0, self.cards.count - 1)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Load cards for category (from old CarouselViewModel)

    func loadCards() {
        // If we already have the starter card, keep it; otherwise create it
        let starter: Card
        if let existingStarter = cards.first, existingStarter.q == "Swipe left for a question..." {
            starter = existingStarter
        } else {
            starter = Card(q: "Swipe left for a question...")
        }

        let categoryCards: [Card]
        
        // Check if this is a custom category
        if category.isCustom, let customCategoryId = category.customCategoryId {
            // Load from custom category
            categoryCards = loadCustomCategoryQuestions(categoryId: customCategoryId)
        } else {
            // Load from Core Data for default categories
            if let defaultService = defaultCategoryService {
                let questions = defaultService.loadQuestions(for: category.id)
                categoryCards = questions.shuffled().map { Card(q: $0) }
            } else {
                // Fallback to hardcoded questions if service not available
                categoryCards = loadHardcodedQuestions()
            }
        }

        // Update cards without animation to prevent fade
        var transaction = Transaction(animation: .none)
        withTransaction(transaction) {
            // Keep starter card at the bottom of the stack
            cards = [starter] + categoryCards
        }
    }
    
    private func loadHardcodedQuestions() -> [Card] {
        switch category.id {
        case 0: // Family
            return QuestionData.familyQuestions.shuffled().map { Card(q: $0) }
        case 1: // Relationships
            return QuestionData.relationshipQuestions.shuffled().map { Card(q: $0) }
        case 2: // Friends
            return QuestionData.friendQuestions.shuffled().map { Card(q: $0) }
        case 3: // Icebreakers
            return QuestionData.icebreakerQuestions.shuffled().map { Card(q: $0) }
        case 4: // Random
            return QuestionData.randomQuestions.shuffled().map { Card(q: $0) }
        case 5: // Controversial
            return QuestionData.controversialQuestions.shuffled().map { Card(q: $0) }
        case 6: // Would You Rather
            return QuestionData.wouldYouRatherQuestions.shuffled().map { Card(q: $0) }
        default:
            return []
        }
    }

    private func loadCustomCategoryQuestions(categoryId: UUID) -> [Card] {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<CustomCategoryEntity> = CustomCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
        
        do {
            if let categoryEntity = try context.fetch(request).first {
                // Access questions through the relationship using KVC
                if let questionsSet = categoryEntity.value(forKey: "questions") as? NSSet,
                   let questions = questionsSet.allObjects as? [NSManagedObject] {
                    return questions.compactMap { entity in
                        // Use KVC to access the question property
                        if let question = entity.value(forKey: "question") as? String {
                            return Card(q: question)
                        }
                        return nil
                    }
                }
            }
        } catch {
            print("Failed to load custom category questions: \(error)")
        }
        
        return []
    }

    // MARK: - Navigation

    func goToNext() {
        if swipedCount < cards.count - 1 {
            // Update asynchronously to avoid blocking gesture recognition
            Task { @MainActor in
                swipedCount += 1
                // Reset all offsets immediately
                for index in cards.indices {
                    cards[index].offset = 0
                }
            }
        }
    }

    func goToPrevious() {
        if swipedCount > 0 {
            // Update asynchronously to avoid blocking gesture recognition
            Task { @MainActor in
                swipedCount -= 1
                // Reset all offsets immediately
                for index in cards.indices {
                    cards[index].offset = 0
                }
            }
        }
    }

    // MARK: - Drag handling (onChanged / onEnd from old Home)

    func onChanged(value: DragGesture.Value, index: Int) {
        let isFirst = swipedCount == 0
        let isLast = swipedCount == cards.count - 1
        let translation = value.translation.width

        // Block swiping right on first card or left on last card
        if (isFirst && translation > 0) || (isLast && translation < 0) {
            cards[index].offset = 0
            return
        }

        cards[index].offset = translation
    }

    func onEnd(value: DragGesture.Value, index: Int) {
        let isFirst = swipedCount == 0
        let isLast = swipedCount == cards.count - 1
        let translation = value.translation.width

        // If swipe is blocked at the edges, snap back
        if (isFirst && translation > 0) || (isLast && translation < 0) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                cards[index].offset = 0
            }
            return
        }

        if abs(value.translation.width) > width / 3 {
            // Update asynchronously to avoid blocking gesture recognition
            Task { @MainActor in
                if value.translation.width < 0 {
                    // Swipe left - go to next
                    if swipedCount < cards.count - 1 {
                        swipedCount += 1
                    }
                } else {
                    // Swipe right - go to previous
                    if swipedCount > 0 {
                        swipedCount -= 1
                    }
                }
                // Reset all offsets immediately
                for i in cards.indices {
                    cards[i].offset = 0
                }
            }
        } else {
            // Snap back with quick animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                cards[index].offset = 0
            }
        }
    }

    // MARK: - Card layout helpers

    func cardRotation(for index: Int) -> Double {
        let boxWidth = Double(width / 3)
        let offset = Double(cards[index].offset)
        let angle: Double = 5
        return (offset / boxWidth) * angle
    }
    
    var canGoBack: Bool {
        swipedCount > 0
    }
    
    var canGoForward: Bool {
        swipedCount < cards.count - 1
    }

    func cardWidth() -> CGFloat {
        UIScreen.main.bounds.width - 60 - 60
    }

    func cardHeight(for index: Int) -> CGFloat {
        return 400
    }

    func cardOffset(for index: Int) -> CGFloat {
        return index - swipedCount <= 2
            ? CGFloat(index - swipedCount) * 30
            : 60
    }
    
    // MARK: - Question Generation
    
    /// Returns a hybrid mix of (mostly) recent items + (some) random older items, capped to `maxCount`.
    /// Note: This assumes the input list is in chronological order (older -> newer). If not, it still
    /// behaves as a good diversity sampler.
    private func hybridRecentAndRandom<T>(
        _ items: [T],
        maxCount: Int = 10,
        recentCount: Int = 7,
        randomOlderCount: Int = 3
    ) -> [T] {
        guard !items.isEmpty else { return [] }
        if items.count <= maxCount {
            return items.shuffled()
        }
        
        let recentTake = min(recentCount, maxCount, items.count)
        let recent = Array(items.suffix(recentTake))
        
        let older = Array(items.dropLast(recent.count))
        let remainingSlots = max(0, maxCount - recent.count)
        let randomTake = min(randomOlderCount, remainingSlots, older.count)
        let randomOlder = Array(older.shuffled().prefix(randomTake))
        
        // Shuffle final selection so we don't imply priority or "recency" in ordering.
        return (recent + randomOlder).shuffled()
    }
    
    /// Prepares data for question generation by selecting a hybrid mix:
    /// - Mostly recent liked/disliked items (to reflect current preferences)
    /// - A smaller random sample from older history (to improve novelty)
    /// - Plus a random slice of current deck questions (for additional variety)
    func prepareQuestionGenerationData() -> (
        subtopic: String,
        likedQuestions: [String],
        dislikedQuestionsWithReasons: [(question: String, reason: String?)],
        deckQuestions: [String]
    ) {
        let allLikedQuestions: [String]
        let allDislikedQuestionsWithReasons: [(question: String, reason: String?)]
        
        if category.isCustom, let customCategoryId = category.customCategoryId, let categoryService = categoryService {
            allLikedQuestions = categoryService.getAllLikedQuestions(for: customCategoryId)
            allDislikedQuestionsWithReasons = categoryService.getAllDislikedQuestionsWithReasons(for: customCategoryId)
        } else if !category.isCustom, let defaultService = defaultCategoryService {
            allLikedQuestions = defaultService.getAllLikedQuestions(for: category.id)
            allDislikedQuestionsWithReasons = defaultService.getAllDislikedQuestionsWithReasons(for: category.id)
        } else {
            return ("", [], [], [])
        }
        
        // Random subtopic for default categories
        let subtopic = category.getRandomSubtopic()
        
        // Hybrid selection: mostly recent + some random older (capped at 10)
        let likedQuestions = hybridRecentAndRandom(
            allLikedQuestions,
            maxCount: 10,
            recentCount: 7,
            randomOlderCount: 3
        )
        
        let dislikedQuestionsWithReasons = hybridRecentAndRandom(
            allDislikedQuestionsWithReasons,
            maxCount: 10,
            recentCount: 7,
            randomOlderCount: 3
        )
        
        // Get 10 random questions from the current deck (excluding starter card)
        let deckQuestions = cards
            .filter { $0.q != "Swipe left for a question..." }
            .map { $0.q }
            .shuffled()
            .prefix(10)
            .map { $0 }
        
        return (subtopic, likedQuestions, dislikedQuestionsWithReasons, Array(deckQuestions))
    }
    
    /// Inserts a new question card at the current position and moves to it
    /// - Parameter question: The question text to insert
    func insertQuestion(_ question: String) {
        let newCard = Card(q: question)
        // Insert at the position after the current card (swipedCount + 1)
        let insertIndex = swipedCount + 1
        if insertIndex <= cards.count {
            cards.insert(newCard, at: insertIndex)
        } else {
            cards.append(newCard)
        }
        // Move to the newly inserted question
        swipedCount = insertIndex
        // Reset all offsets
        for index in cards.indices {
            cards[index].offset = 0
        }
        
        // Save to Core Data
        if category.isCustom, let customCategoryId = category.customCategoryId, let categoryService = categoryService {
            _ = categoryService.saveQuestion(question, to: customCategoryId)
        } else if !category.isCustom, let defaultService = defaultCategoryService {
            defaultService.addGeneratedQuestion(question, to: category.id)
        }
    }
    
    /// Removes the generated question if it was not liked
    /// - Parameter question: The question text to remove
    func removeGeneratedQuestion(_ question: String) {
        if let index = cards.firstIndex(where: { $0.q == question && $0.id != cards[0].id }) {
            cards.remove(at: index)
            if index <= swipedCount {
                swipedCount = max(0, swipedCount - 1)
            }
        }
    }
}
