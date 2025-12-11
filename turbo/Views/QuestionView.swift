//
//  QuestionView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct QuestionView: View {

    let category: Category
    @StateObject private var viewModel: QuestionViewModel

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

                // Card stack - matching old pattern exactly
                ZStack {
                    if !viewModel.cards.isEmpty {
                        ForEach((0...(viewModel.cards.count - 1)).reversed(), id: \.self) { index in
                            if index == viewModel.cards.count - 1 {
                                // Show starter card with "Click Reset" message - not swipeable
                                ZStack {
                                    CardView(card: viewModel.cards[index], animation: animation)
                                        .frame(width: viewModel.cardWidth(), height: viewModel.cardHeight(for: 0))
                                    VStack {
                                        Text("").padding(.bottom, 330)
                                        HStack {
                                            Text("").padding(.trailing, 150)
                                            Text("Click Reset").fontWeight(.bold).foregroundColor(Color.gray)
                                        }
                                    }
                                }
                            } else {
                                // Regular card - swipeable
                                HStack {
                                    Spacer()
                                    CardView(card: viewModel.cards[index], animation: animation)
                                        .frame(width: viewModel.cardWidth(), height: viewModel.cardHeight(for: index))
                                        .rotationEffect(.init(degrees: viewModel.cardRotation(for: index)))
                                    Spacer(minLength: 0)
                                }
                                .frame(height: 400)
                                .contentShape(Rectangle())
                                .offset(x: viewModel.cards[index].offset)
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged({ (value) in
                                        viewModel.onChanged(value: value, index: index)
                                    }).onEnded({ (value) in
                                        viewModel.onEnd(value: value, index: index)
                                    }))
                            }
                        }
                    }
                }
                .padding(.top, 25)
                .padding(.horizontal, 30)

                Spacer()

                // Reset button (same style as old app)
                Button(action: {
                    viewModel.reset()
                }) {
                    Text("Reset")
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                        .padding(20)
                        .font(.system(size: 20))
                        .background(Color.white)
                        .cornerRadius(80.0)
                        .shadow(radius: 10)
                }

                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
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
