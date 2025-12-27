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
        // Old code always returned 400; the variable cardHeight
        // only affected offset, not actual height.
        return 400
    }

    func cardOffset(for index: Int) -> CGFloat {
        // Same logic as getCardOffset from old code but for single swipedCount
        return index - swipedCount <= 2
            ? CGFloat(index - swipedCount) * 30
            : 60
    }
    
    // MARK: - Question Generation
    
    /// Prepares data for question generation by randomly selecting liked/disliked questions
    /// - Returns: Tuple containing liked questions, disliked questions with reasons, and deck questions
    func prepareQuestionGenerationData() -> (likedQuestions: [String], dislikedQuestionsWithReasons: [(question: String, reason: String?)], deckQuestions: [String]) {
        // Get ALL liked and disliked questions, then randomly select 10 of each
        let allLikedQuestions: [String]
        let allDislikedQuestionsWithReasons: [(question: String, reason: String?)]
        
        if category.isCustom, let customCategoryId = category.customCategoryId, let categoryService = categoryService {
            allLikedQuestions = categoryService.getAllLikedQuestions(for: customCategoryId)
            allDislikedQuestionsWithReasons = categoryService.getAllDislikedQuestionsWithReasons(for: customCategoryId)
        } else if !category.isCustom, let defaultService = defaultCategoryService {
            allLikedQuestions = defaultService.getAllLikedQuestions(for: category.id)
            allDislikedQuestionsWithReasons = defaultService.getAllDislikedQuestionsWithReasons(for: category.id)
        } else {
            return ([], [], [])
        }
        
        // Randomly select up to 10 liked questions
        let likedQuestions = Array(allLikedQuestions.shuffled().prefix(10))
        
        // Randomly select up to 10 disliked questions with reasons
        let dislikedQuestionsWithReasons = Array(allDislikedQuestionsWithReasons.shuffled().prefix(10))
        
        // Get 10 random questions from the current deck (excluding starter card)
        let deckQuestions = cards
            .filter { $0.q != "Swipe left for a question..." }
            .map { $0.q }
            .shuffled()
            .prefix(10)
            .map { $0 }
        
        return (likedQuestions, dislikedQuestionsWithReasons, Array(deckQuestions))
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
            // Save to custom category
            _ = categoryService.saveQuestion(question, to: customCategoryId)
        } else if !category.isCustom, let defaultService = defaultCategoryService {
            // Save to default category
            defaultService.addGeneratedQuestion(question, to: category.id)
        }
    }
    
    /// Removes the generated question if it was not liked
    /// - Parameter question: The question text to remove
    func removeGeneratedQuestion(_ question: String) {
        // Find and remove the card with this question
        if let index = cards.firstIndex(where: { $0.q == question && $0.id != cards[0].id }) {
            cards.remove(at: index)
            // Adjust swipedCount if we removed a card before the current position
            if index <= swipedCount {
                swipedCount = max(0, swipedCount - 1)
            }
        }
    }
}

// MARK: - Static question data (copied from CarouselViewModel)

enum QuestionData {

    static let familyQuestions: [String] = [
        "What quality do your parents have that you admire?",
        "What is the most significant value your parents have instilled in you?",
        "Who is the most inspiring person in your family?",
        "Out of everyone in your extended family, who are you closest to?",
        "Who’s the most annoying family member to you?",
        "Which family member do you get along with the most and which family member do you get along with the least?",
        "Which TV show best represents your family?",
        "If you could pick anyone in the world to be your parents, who would you choose?",
        "If you could give your kid(s) one talent, what talent would you choose?",
        "If you’re an only child: Do you wish you had siblings?\nIf you have siblings: Do you wish you were an only child?",
        "What's the best family vacation you have been on?",
        "If you plan on having kids in the future, what parenting moment are you looking forward to the most?",
        "Would you consider fostering/adopting a child?",
        "If you were to adopt a child, at what age would you tell them that they are adopted?",
        "What is the best quality each of your siblings have?",
        "If you were to have one more sibling, would you want them to be older or younger than you?",
        "What is the most interesting story your grandparents have told you?",
        "How would your personality change if you were an only child or if you had siblings?",
        "Who's one family member you brag about/show off to others?",
        "What is your most memorable moment with your grandparents?",
        "If you are an older sibling, do you think you’re a good role model?",
        "What are some differences between your mom's side and dad's side of the family?",
        "How did your parents meet?",
        "If you could go back and watch one moment in your grandma's and/or grandpa's life, what would it be?",
        "Would you rather time travel into the past to meet your ancestors or into the future to meet your descendants?"
    ]

    static let relationshipQuestions: [String] = [
        "Should the man pay for the first date?",
        "Why did your last relationship end?",
        "What movie makes you believe in love?",
        "Do you believe in soul mates?",
        "What is your deal breaker in a relationship?",
        "What do you consider cheating?",
        "Do you think you can maintain a long distance relationship?",
        "Do you think you can be friends with your ex?",
        "Do you prefer a significant other that is more similar or more different than you?",
        "What is one thing you have learned about yourself from being in a relationship?",
        "What is the biggest compromise you have made in a relationship?",
        "What is your most memorable date?",
        "Do you think keeping some secrets in a relationship is okay?",
        "Would you rather marry someone you don’t love or marry someone who doesn’t love you?",
        "How did you meet your current partner?",
        "At what age do you think it is appropriate to have a relationship?",
        "How has the relationship between your parents influenced your perception of relationships?",
        "What's something new you started doing after you met your current/past partner?",
        "What do you consider to be the most toxic thing in a relationship?",
        "What is your idea of a perfect date?",
        "What does your ideal wedding look like?",
        "What is too large of an age gap for you in a relationship?",
        "What is the best advice you can give to someone who is new to dating?",
        "What are some toxic relationship traits that you think you have?",
        "Do you believe in love at first sight?"
    ]

    static let friendQuestions: [String] = [
        "What's one thing you would change about your relationship with your friends?",
        "Do you have a friend that you never thought you would be close to when you first met them?",
        "What is the best advice you’ve ever received from a friend?",
        "What was your first impression of your friends?",
        "Which of your friends are you most similar to?",
        "What is a quality in each of your friends that you admire?",
        "What vacation would you like to take with your friends?",
        "What do you value the most in a friendship?",
        "How did you meet your best friend?",
        "Which of your friends would you run a business with?",
        "Which friend do you call when times get hard?",
        "If you had to choose, would you rather have 10 good friends or one best friend?",
        "How would you describe each of your friends in one word?",
        "Which TV show characters do you and your friends resemble the most?",
        "When was the first time your friends witnessed you cry or the first time you witnessed your friends cry?",
        "Would you stand by your friends even if they are in the wrong?",
        "Would you live with your friends?",
        "Which celebrity would you want to be best friends with?",
        "Have you ever broken the law with your friends?",
        "If you had to be trapped on a deserted island, which friend would your bring?",
        "Which one of your friends are most likely to become famous?",
        "If you could live a friend's life for a week, which friend would you choose?",
        "What makes each of your friendships unique?",
        "What's the best gift you have received from a friend?",
        "What is one memory you have with your friends that you want to relive?"
    ]

    static let icebreakerQuestions: [String] = [
        "If you had to create a show about yourself, what part of your life would you use for the pilot?",
        "Which actor/actress would play you in a movie about your life?",
        "What's the best mistake you've ever made?",
        "If a genie were to grant you 3 wishes right now, what would you wish for?",
        "What do you like and dislike about your current job?",
        "What is something you did last year that you are proud of?",
        "As an employee, what's the worst customer experience you've had?",
        "What’s the worst job you’ve ever had?",
        "What is your dream job?",
        "When you die, what do you want to be remembered for?",
        "If money wasn’t a concern, what career would you pursue?",
        "What’s your favorite way to unwind after a busy day?",
        "If you had to fight for one global cause for the rest of your life, what would it be?",
        "What is your biggest fear?",
        "What is one thing you've always wanted to do, but have been too scared to do it?",
        "Are you a \"save the best for last\" type of person?",
        "If you could drop everything and go anywhere, where would you go?",
        "If you could choose any superpower to have, what would you choose?",
        "Do you have a weird talent?",
        "If you could speak another language, what would it be?",
        "What’s the most useful thing you own?",
        "If you had to delete one social media platform, what would it be?",
        "What is something you would tell your 10 year old self?",
        "What's one thing you would do in your life right now, if you knew you could not fail at it?",
        "What’s your biggest passion?"
    ]

    static let randomQuestions: [String] = [
        "What's a weird smell you like?",
        "What is something you learned after it was already too late?",
        "What's a reoccurring dream/nightmare you have had?",
        "If the whole world was listening and you could say one sentence, what would you say?",
        "What is a lie that you often tell yourself?",
        "If you could have a second chance at one event in your life, what would you choose?",
        "What is your most memorable interaction with a stranger?",
        "If you could pick a new first name, what would it be?",
        "What is your most embarrassing moment?",
        "Would you rather forget everyone you know or have everyone you know forget you?",
        "What is the worst advice you have ever given?",
        "Where do you see yourself in the next 10 years?",
        "Would you rather have a rewind button or a pause button on your life?",
        "Would you rather speak with animals or speak all foreign languages?",
        "Do you believe in life beyond earth?",
        "Do you think alcohol is necessary to have a fun time?",
        "Do you think you have seen every digit combination on the clock?",
        "Would you like to find out how you die?",
        "If you could be immortal for a day, what would you do?",
        "If you could know the absolute truth to one question, what would you ask?",
        "When was the last time you did something for the first time?",
        "What's your biggest insecurity?",
        "How did technology affect your childhood?",
        "If you could live in any story line (movie, book, TV show, etc.), what would it be?",
        "If you had the power to correct one problem in the world, what would it be?"
    ]

    static let controversialQuestions: [String] = [
        "Is the world better with religion or would it be better without it?",
        "Can a person be born evil?",
        "Should the current prison system be abolished?",
        "Are you for or against abortion?",
        "Should human cloning be legal?",
        "Should healthcare be free?",
        "Would you change your future child's genetic makeup if you could?",
        "What's the hardest health to keep healthy? Spiritual, mental, emotional, or physical?",
        "Do you think it should be a fundamental right to own firearms?",
        "Do you believe in fate or free will?",
        "Do you believe in the death penalty?",
        "Should billionaires exist?",
        "Do you agree with the legal drinking age?",
        "Should all recreational drugs be legalized?",
        "Should post secondary education be free?",
        "Do you think social media has improved human communication?",
        "Should all vaccines be mandatory?",
        "Should taxes be raised on the wealthy?",
        "Should animal testing be illegal?",
        "Do you think Zoos should exist?",
        "Should euthanasia be legal?",
        "Should people be fined according to their income?",
        "Should it be mandatory to tip at restaurants?",
        "To what extent should the government have access to your personal information?",
        "Is artificial intelligence more of a threat or a benefit to society?"
    ]
    
    static let wouldYouRatherQuestions: [String] = [
        "Would you rather have the ability to fly or be invisible?",
        "Would you rather always be 10 minutes late or always be 20 minutes early?",
        "Would you rather have unlimited money or unlimited time?",
        "Would you rather be able to read minds or see into the future?",
        "Would you rather live without internet or live without air conditioning and heating?",
        "Would you rather be able to teleport anywhere or be able to read minds?",
        "Would you rather have super strength or super speed?",
        "Would you rather always be cold or always be hot?",
        "Would you rather be famous or be the best friend of someone famous?",
        "Would you rather have the ability to time travel or have the ability to speak every language in the world?"
    ]
}
