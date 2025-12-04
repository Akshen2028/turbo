//
//  HomeView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI
import MessageUI

struct HomeView: View {

    // MARK: - Email Sheet State
    @State private var showMailComposer = false
    @State private var isSendingFeatureSuggestion = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil

    // MARK: - Background Animation
    @State private var isAnimatingBackground = false
    @State private var gradientStart = UnitPoint(x: 0, y: -2)
    @State private var gradientEnd = UnitPoint(x: 4, y: 0)

    // MARK: - Constants
    private let itemsPerRow = 6
    private let tealColor = Color(red: 55/255, green: 213/255, blue: 209/255)
    private let backgroundGradient = [
        Color.white,
        Color.white,
        Color(red: 55/255, green: 213/255, blue: 209/255)
    ]

    // MARK: - View
    var body: some View {
        NavigationView {
            ZStack {
                animatedGradientBackground
                animatedIconGrid
                mainContent
                bottomButtons
            }
        }
        .sheet(isPresented: $showMailComposer) {
            mailComposerSheet
        }
        .accentColor(.black)
    }

    // MARK: - Background Gradient
    private var animatedGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundGradient),
            startPoint: gradientStart,
            endPoint: gradientEnd
        )
        .ignoresSafeArea()
    }

    // MARK: - Animated Icons Behind UI
    private var animatedIconGrid: some View {
        VStack {
            ForEach(0 ..< numberOfRows()) { row in
                HStack {
                    ForEach(0 ..< itemsPerRow) { col in
                        Image(iconName(for: row * itemsPerRow + col))
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(
                                width: UIScreen.main.bounds.width / CGFloat(itemsPerRow),
                                height: UIScreen.main.bounds.width / CGFloat(itemsPerRow)
                            )
                            .opacity(isAnimatingBackground ? 0.5 : 0)
                            .animation(
                                Animation.linear(duration: Double.random(in: 10...20))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...5)),
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

    // MARK: - Main App UI (Title + Buttons)
    private var mainContent: some View {
        VStack {
            Text("Talkaholic")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.black)

            NavigationLink(destination: CategoryListView()) {
                Text("Select Category")
                    .homePrimaryButton()
            }

            Button(action: openMailComposerForQuestion) {
                Text("Send Questions")
                    .homeSecondaryButton(tealColor: tealColor)
            }
            .sheet(isPresented: $showMailComposer) {
                mailComposerSheet
            }

            Spacer().frame(height: 200)
        }
    }

    // MARK: - Bottom Buttons (Info + Help)
    private var bottomButtons: some View {
        VStack {
            Spacer()
            HStack() {
                InfoNavButton()
                HelpNavButton()
            }
            Spacer().frame(height: 200)
        }
    }

    // MARK: - Mail Composer View
    private var mailComposerSheet: some View {
        MailView(
            result: $mailResult,
            newSubject: isSendingFeatureSuggestion
                ? "New Feature Suggestion"
                : "New Question Suggestion",
            newMsgBody: isSendingFeatureSuggestion
                ? "I am enjoying this app, but I want to suggest a new feature!!!\n\nSuggestion:"
                : "I am enjoying this app, but I want to send a new Question!!!\n\nCategory: \n\nQuestion: "
        )
    }

    // MARK: - Actions
    private func openMailComposerForQuestion() {
        isSendingFeatureSuggestion = false
        attemptToOpenMail()
    }

    private func attemptToOpenMail() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            print("Error: Device cannot send mail.")
        }
    }

    // MARK: - Helpers
    private func iconName(for index: Int) -> String {
        String(index % 2) // uses "0" and "1" image assets
    }

    private func numberOfRows() -> Int {
        let cellHeight = UIScreen.main.bounds.width / CGFloat(itemsPerRow)
        return Int(UIScreen.main.bounds.height / cellHeight) + 1
    }
}

#Preview {
    HomeView()
}
