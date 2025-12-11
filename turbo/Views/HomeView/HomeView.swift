//
//  HomeView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI
import MessageUI
import CoreData

struct HomeView: View {
    @StateObject private var mailVM = MailViewModel()
    
    // MARK: - Background Animation State
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
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                animatedGradientBackground
                animatedIconGrid
                mainContent
                bottomButtons
            }
        }
        .sheet(isPresented: $mailVM.isShowingMailComposer) {
            MailView(
                result: $mailVM.mailResult,
                subject: mailVM.subject,
                body: mailVM.body
            )
        }
        .accentColor(.black)
    }
    
    // MARK: - Gradient Background
    private var animatedGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundGradient),
            startPoint: gradientStart,
            endPoint: gradientEnd
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Animated Icons
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
        .onAppear { isAnimatingBackground = true }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            Text("Talkaholic")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.black)
            
            NavigationLink(destination: CategoryListView()) {
                Text("Select Category")
                    .homePrimaryButton()
            }
            
            NavigationLink(destination: CustomCategoriesView()) {
                Text("My Categories")
                    .homeSecondaryButton(tealColor: tealColor)
            }
            
            Spacer().frame(height: 200)
        }
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                InfoNavButton()
                HelpNavButton()
                MailNavButton {
                    mailVM.prepareForQuestion()
                }
            }
            Spacer().frame(height: 200)
        }
    }
    
    // MARK: - Helpers
    private func iconName(for index: Int) -> String {
        String(index % 2)
    }
    
    private func numberOfRows() -> Int {
        let cellHeight = UIScreen.main.bounds.width / CGFloat(itemsPerRow)
        return Int(UIScreen.main.bounds.height / cellHeight) + 1
    }
}

#Preview {
    HomeView()
}

