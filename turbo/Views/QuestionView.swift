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
    @StateObject private var categoryService = CustomCategoryService(context: PersistenceController.shared.container.viewContext)
    @State private var showingSaveSheet = false

    // Background animation state
    private let itemsPerRow = 6
    @State private var isAnimatingBackground = false
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end   = UnitPoint(x: 4, y: 0)

    private let colors = [
        Color.white,
        Color.white,
        Color(red: 55/255, green: 213/255, blue: 209/255)
    ]

    @Namespace private var animation

    init(category: Category) {
        self.category = category
        _viewModel = StateObject(wrappedValue: QuestionViewModel(category: category))
        
        // Make navigation bar title bigger
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
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
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: start,
                endPoint: end
            )
            .ignoresSafeArea()

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
                    transaction.animation = .easeOut(duration: 0.15)
                }
                .padding(.top, 25)
                .padding(.horizontal, 30)

                Spacer()

                // Navigation buttons - left and right
                HStack(spacing: 40) {
                    // Left button (previous)
                    Button(action: {
                        viewModel.goToPrevious()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(viewModel.canGoBack ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(80.0)
                            .shadow(radius: 10)
                    }
                    .disabled(!viewModel.canGoBack)

                    // Right button (next)
                    Button(action: {
                        viewModel.goToNext()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(viewModel.canGoForward ? Color(red: 55/255, green: 213/255, blue: 209/255) : Color.gray)
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(80.0)
                            .shadow(radius: 10)
                    }
                    .disabled(!viewModel.canGoForward)
                }

                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
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
                categoryService: categoryService,
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
