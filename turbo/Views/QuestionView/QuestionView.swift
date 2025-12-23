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
    @State private var showingSaveSheet = false

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
    }
    
    private var currentQuestion: String {
        let currentIndex = viewModel.swipedCount
        guard currentIndex < viewModel.cards.count else { return "" }
        return viewModel.cards[currentIndex].q
    }
    
    private var isStarterCard: Bool {
        let currentIndex = viewModel.swipedCount
        guard currentIndex < viewModel.cards.count else { return false }
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

                Spacer()

                // Navigation buttons - left and right
                HStack(spacing: 40) {
                    NavigationArrowButton(direction: .left, isEnabled: viewModel.canGoBack) {
                        viewModel.goToPrevious()
                    }
                    
                    NavigationArrowButton(direction: .right, isEnabled: viewModel.canGoForward) {
                        viewModel.goToNext()
                    }
                }
                Spacer()
                Spacer()
                Spacer()
                Spacer()
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

