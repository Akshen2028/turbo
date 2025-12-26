//
//  QuestionView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import CoreData

struct QuestionView: View {
    
    let category: Category
    @StateObject private var viewModel: QuestionViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var categoryService: CustomCategoryService
    @EnvironmentObject var defaultCategoryService: DefaultCategoryService
    @State private var showingSaveSheet = false
    
    // Question generation state
    @StateObject private var questionGenerationService = QuestionGenerationService()
    @State private var generatedQuestion: String? = nil
    @State private var isGenerating = false
    @State private var showLikeDislike = false
    
    // Shimmer animation state
    @State private var shimmerOffset: CGFloat = -200
    @State private var glowHue: Double = 0.6  // Start in blue/purple range
    @State private var shadowRadius: CGFloat = 8.0
    @State private var hueTimer: Timer?

    // Background animation state
    private let itemsPerRow = 6
    @State private var isAnimatingBackground = false

    @Namespace private var animation

    init(category: Category) {
        self.category = category
        _viewModel = StateObject(wrappedValue: QuestionViewModel(category: category))
    }
    
    // Update view model's service reference when the environment object is available
    private func updateViewModelService() {
        viewModel.categoryService = categoryService
        viewModel.defaultCategoryService = defaultCategoryService
    }
    
    private var currentQuestion: String {
        let currentIndex = viewModel.swipedCount
        guard currentIndex < viewModel.cards.count else { return "" }
        return viewModel.cards[currentIndex].q
    }
    
    private var isStarterCard: Bool {
        // If cards are empty, treat it as starter card to prevent bookmark flicker
        guard !viewModel.cards.isEmpty else { return true }
        let currentIndex = viewModel.swipedCount
        guard currentIndex < viewModel.cards.count else { return true }
        return viewModel.cards[currentIndex].q == "Swipe left for a question..."
    }

    var body: some View {
        ZStack {
            GradientBackground()

            // Animated bubble background
            bubbleBackground

            // Foreground content: card stack + Reset button
            VStack {
                // Match old layout spacing (3 spacers at top)
                Spacer()
                Spacer()
                Spacer()

                // Card stack - use stable IDs to prevent view recreation
                ZStack {
                    if !viewModel.cards.isEmpty {
                        let currentIndex = viewModel.swipedCount
                        let currentCardOffset = viewModel.cards[currentIndex].offset
                        
                        // Show preview card when swiping
                        // Next card preview (when swiping left)
                        if currentIndex + 1 < viewModel.cards.count && currentCardOffset < 0 {
                            HStack {
                                Spacer()
                                CardView(card: viewModel.cards[currentIndex + 1], animation: animation)
                                    .frame(width: viewModel.cardWidth(), height: viewModel.cardHeight(for: currentIndex + 1))
                                Spacer(minLength: 0)
                            }
                            .frame(height: 400)
                            .zIndex(Double(viewModel.cards.count - currentIndex) - 0.5)
                        }
                        
                        // Previous card preview (when swiping right)
                        if currentIndex > 0 && currentCardOffset > 0 {
                            HStack {
                                Spacer()
                                CardView(card: viewModel.cards[currentIndex - 1], animation: animation)
                                    .frame(width: viewModel.cardWidth(), height: viewModel.cardHeight(for: currentIndex - 1))
                                Spacer(minLength: 0)
                            }
                            .frame(height: 400)
                            .zIndex(Double(viewModel.cards.count - currentIndex) - 0.5)
                        }
                        
                        // Use card IDs instead of indices for stable view identity
                        ForEach((currentIndex...(viewModel.cards.count - 1)).reversed(), id: \.self) { index in
                            let isTopCard = index == currentIndex
                            HStack {
                                Spacer()
                                CardView(card: viewModel.cards[index], animation: animation)
                                    .frame(width: viewModel.cardWidth(), height: viewModel.cardHeight(for: index))
                                    .rotationEffect(.init(degrees: isTopCard ? viewModel.cardRotation(for: index) : 0))
                                Spacer(minLength: 0)
                            }
                            .frame(height: 400)
                            .contentShape(Rectangle())
                            .offset(x: isTopCard ? viewModel.cards[index].offset : 0)
                            .zIndex(isTopCard ? Double(viewModel.cards.count - currentIndex) : Double(viewModel.cards.count - index))
                            .id("card-\(viewModel.cards[index].id)") // Stable ID based on card
                            .gesture(isTopCard ? DragGesture(minimumDistance: 0)
                                .onChanged({ (value) in
                                    viewModel.onChanged(value: value, index: index)
                                }).onEnded({ (value) in
                                    viewModel.onEnd(value: value, index: index)
                                }) : nil)
                        }
                    }
                }
                .transaction { transaction in
                    transaction.animation = .easeOut(duration: 0.3)
                }
                .padding(.top, 25)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)

                // Navigation buttons - left and right
                HStack(spacing: 40) {
                    NavigationArrowButton(direction: .left, isEnabled: viewModel.canGoBack) {
                        viewModel.goToPrevious()
                    }
                    
                    NavigationArrowButton(direction: .right, isEnabled: viewModel.canGoForward) {
                        viewModel.goToNext()
                    }
                }
                .padding(.bottom, 30)
                
                // Generate Question button
                Button(action: {
                    generateQuestion()
                }) {
                    ZStack {
                        // Rainbow gradient background (matching app icon style with more blue)
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.9, blue: 0.2),   // Yellow
                                        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
                                        Color(red: 1.0, green: 0.3, blue: 0.6),   // Pink
                                        Color(red: 0.7, green: 0.2, blue: 0.8),   // Purple
                                        Color(red: 0.4, green: 0.4, blue: 1.0),   // Blue-purple
                                        Color(red: 0.2, green: 0.6, blue: 1.0),   // Bright blue
                                        Color(red: 0.1, green: 0.7, blue: 1.0)    // Clear blue
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Shimmer overlay
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white.opacity(0.4), location: 0.5),
                                        .init(color: .clear, location: 1)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(
                                RoundedRectangle(cornerRadius: 20)
                            )
                        
                        // Button text
                        Text("Generate Question")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 180, height: 50)
                    .shadow(
                        color: Color(hue: glowHue.truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.8),
                        radius: shadowRadius,
                        x: 0,
                        y: 0
                    )
                    .shadow(
                        color: Color(hue: (glowHue + 0.15).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.6),
                        radius: shadowRadius * 1.3,
                        x: 0,
                        y: 0
                    )
                    .shadow(
                        color: Color(hue: (glowHue + 0.3).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.4),
                        radius: shadowRadius * 1.6,
                        x: 0,
                        y: 0
                    )
                }
                .disabled(isGenerating)
                .opacity(isGenerating ? 0.6 : 1.0)
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
            
            // Generated question overlay with like/dislike
            if let generatedQuestion = generatedQuestion, showLikeDislike {
                ZStack {
                    // Blurred background using Material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        // Generated question card (positioned like current card)
                        HStack {
                            Spacer()
                            ZStack {
                                // Card background - show empty or actual question
                                CardView(
                                    card: Card(q: isGenerating ? "Generating question..." : generatedQuestion),
                                    animation: animation,
                                    textColor: isGenerating ? .gray : .black
                                )
                                .frame(width: viewModel.cardWidth(), height: 400)
                                .fixedSize(horizontal: false, vertical: false)  // Prevent expansion
                                .clipped()  // Clip any overflow
                                .opacity(isGenerating ? 0.7 : 1.0)
                                
                                // Rainbow spinner overlay when loading
                                if isGenerating {
                                    RainbowSpinner()
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            .shadow(
                                color: Color(hue: glowHue.truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.8),
                                radius: shadowRadius,
                                x: 0,
                                y: 0
                            )
                            .shadow(
                                color: Color(hue: (glowHue + 0.15).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.6),
                                radius: shadowRadius * 1.3,
                                x: 0,
                                y: 0
                            )
                            .shadow(
                                color: Color(hue: (glowHue + 0.3).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0).opacity(0.4),
                                radius: shadowRadius * 1.6,
                                x: 0,
                                y: 0
                            )
                            Spacer(minLength: 0)
                        }
                        .frame(height: 400)
                        .padding(.top, 25)
                        .padding(.horizontal, 30)
                        
                        Spacer()
                        
                        // Like/Dislike buttons
                        HStack(spacing: 40) {
                            // Dislike button
                            Button(action: {
                                handleDislike()
                            }) {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        Circle()
                                            .fill(isGenerating ? Color.gray : Color.red)
                                    )
                            }
                            .disabled(isGenerating)
                            
                            // Like button
                            Button(action: {
                                handleLike()
                            }) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        Circle()
                                            .fill(isGenerating ? Color.gray : Color.green)
                                    )
                            }
                            .disabled(isGenerating)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                }
                .zIndex(1000)
            }

            // Edit button for custom categories (bottom right corner)
            if let customCategory = categoryService.customCategories.first(where: { $0.id == category.customCategoryId }) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            CustomCategoryDetailView(category: customCategory, onCategoryDeleted: {
                                // Dismiss QuestionView after deleting category (no animation to avoid flicker)
                                let transaction = Transaction(animation: .none)
                                withTransaction(transaction) {
                                    dismiss()
                                }
                            })
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color(red: 55/255, green: 213/255, blue: 209/255))
                                        .frame(width: 48, height: 48)
                                )
                        }
                        .padding(.trailing, 40)
                        .padding(.bottom, 150)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .onAppear {
            // Update view model with the shared service instance
            updateViewModelService()
            // Ensure cards are loaded if not already
            if viewModel.cards.isEmpty {
                viewModel.loadCards()
            }
            // Start shimmer animation
            startShimmerAnimation()
        }
        .onDisappear {
            // Clean up timer when view disappears
            hueTimer?.invalidate()
            hueTimer = nil
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isStarterCard {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSaveSheet = true
                    }) {
                        Image(systemName: "bookmark")
                            .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                    }
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveQuestionView(
                question: currentQuestion,
                isPresented: $showingSaveSheet
            )
        }
    }

    // MARK: - Bubble Background

    private var bubbleBackground: some View {
        VStack {
            ForEach(0 ..< getNumberOfRows(), id: \.self) { i in
                HStack {
                    ForEach(0 ..< itemsPerRow, id: \.self) { j in
                        Image(getImage(indexLocation: (i * itemsPerRow) + j))
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(
                                width: UIScreen.main.bounds.width / CGFloat(itemsPerRow),
                                height: UIScreen.main.bounds.width / CGFloat(itemsPerRow)
                            )
                            .opacity(isAnimatingBackground ? 0.8 : 0)
                            .animation(
                                Animation.linear(duration: Double.random(in: 1 ... 2))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0 ... 1.5)),
                                value: isAnimatingBackground
                            )
                    }
                }
            }
        }
        .onAppear {
            isAnimatingBackground = true
        }
    }

    private func getImage(indexLocation: Int) -> String {
        // Old project used "0" bubble asset repeatedly
        String(indexLocation % 1)
    }

    private func getNumberOfRows() -> Int {
        let heightPerItem = UIScreen.main.bounds.width / CGFloat(itemsPerRow)
        return Int(UIScreen.main.bounds.height / heightPerItem) + 1
    }
    
    // MARK: - Question Generation
    
    private func generateQuestion() {
        guard !isGenerating else { return }
        
        // Clear any existing generated question first
        if showLikeDislike {
            withAnimation(.easeOut(duration: 0.2)) {
                showLikeDislike = false
            }
        }
        
        // Show the overlay immediately with loading state
        generatedQuestion = "" // Empty text while loading, spinner will show
        isGenerating = true
        
        withAnimation(.easeIn(duration: 0.3)) {
            showLikeDislike = true
        }
        
        Task {
            // Get recent liked and disliked questions to tailor generation to user preferences
            let likedQuestions: [String]
            let dislikedQuestions: [String]
            
            if category.isCustom, let customCategoryId = category.customCategoryId {
                likedQuestions = categoryService.getRecentLikedQuestions(for: customCategoryId, limit: 10)
                dislikedQuestions = categoryService.getRecentDislikedQuestions(for: customCategoryId, limit: 10)
            } else {
                likedQuestions = defaultCategoryService.getRecentLikedQuestions(for: category.id, limit: 10)
                dislikedQuestions = defaultCategoryService.getRecentDislikedQuestions(for: category.id, limit: 10)
            }
            
            let question = await questionGenerationService.generateQuestion(for: category.name, likedQuestions: likedQuestions, dislikedQuestions: dislikedQuestions)
            
            await MainActor.run {
                generatedQuestion = question
                isGenerating = false
            }
        }
    }
    
    private func handleLike() {
        guard let question = generatedQuestion else { return }
        
        // Insert the question into the deck at the current position
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.insertQuestion(question)
            // Hide the overlay
            showLikeDislike = false
            generatedQuestion = nil
        }
    }
    
    private func handleDislike() {
        guard let question = generatedQuestion else { return }
        
        // Save rejected question to Core Data (keeps 20 most recent per category)
        if category.isCustom, let customCategoryId = category.customCategoryId {
            categoryService.rejectQuestion(question, in: customCategoryId)
        } else if !category.isCustom {
            defaultCategoryService.rejectQuestion(question, in: category.id)
        }
        
        // Fade away and return to the current question
        withAnimation(.easeOut(duration: 0.3)) {
            showLikeDislike = false
        }
        
        // Clear the generated question after animation completes
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                generatedQuestion = nil
            }
        }
    }
    
    // MARK: - Shimmer Animation
    
    private func startShimmerAnimation() {
        // Reset to start position
        shimmerOffset = -200
        
        // Animate shimmer across the button
        withAnimation(
            Animation.linear(duration: 2.0)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 400
        }
        
        // Animate glow hue cycling through rainbow colors using Timer
        // This ensures it cycles through all colors including orange, yellow, red
        glowHue = 0.6  // Start at blue
        
        hueTimer?.invalidate()
        hueTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                glowHue = (glowHue + 0.01).truncatingRemainder(dividingBy: 1.0)
            }
        }
        
        // Animate shadow pulsing (bigger and smaller)
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            shadowRadius = 14.0
        }
    }
}

#Preview {
    NavigationStack {
        QuestionView(
            category: Category(
                id: 0,
                name: "Family",
                imageName: "family"
            )
        )
    }
}

