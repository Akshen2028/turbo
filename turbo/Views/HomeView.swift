//
//  HomeView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI
import UIKit
import MessageUI

struct HomeView: View {
    
    // MARK: - State Properties
    @State private var navigateTo = ""
    @State private var isActives = false
    @State private var isActive = false
    @State private var isActive1 = false
    @State private var show = false
    @State private var sug = false
    @State private var showSheet = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    
    @State private var isAnimating = false
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Constants
    let itemsPerRow = 6
    let colors = [
        Color.white,
        Color.white,
        Color(red: 55/255, green: 213/255, blue: 209/255)
    ]
    
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                
                // Background Gradient Animation
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: start,
                    endPoint: end
                )
                .ignoresSafeArea()
                
                // Animated Background Icons
                animatedBackgroundIcons
                
                // Main Header + Buttons
                mainButtons
                
                // Bottom About/Help Buttons
                bottomButtons
            }
        }
        .accentColor(.black)
    }
    
    
    // MARK: - Background Icons
    private var animatedBackgroundIcons: some View {
        VStack {
            ForEach(0 ..< getNumberOfRows()) { row in
                HStack {
                    ForEach(0 ..< itemsPerRow) { col in
                        Image(getImage(indexLocation: (row * itemsPerRow) + col))
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .frame(
                                width: UIScreen.main.bounds.width / CGFloat(itemsPerRow),
                                height: UIScreen.main.bounds.width / CGFloat(itemsPerRow)
                            )
                            .opacity(isAnimating ? 0.5 : 0)
                            .animation(
                                Animation.linear(duration: Double.random(in: 10...20))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...5)),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    
    // MARK: - Main Buttons & Title
    private var mainButtons: some View {
        VStack {
            Text("Talkaholic")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.black)
            
            // Select Category
            NavigationLink(destination: CategoryListView()) {
                Text("Select Category")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(20)
            }
            .background(Color(red: 55/255, green: 213/255, blue: 209/255))
            .cornerRadius(80)
            .shadow(radius: 10)
            
            // Send Questions
            Button(action: {
                suggestFeature()
                sug = false
            }) {
                Text("Send Questions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                    .padding(20)
            }
            .background(Color.white)
            .cornerRadius(80)
            .shadow(radius: 10)
            .padding(.top, 4)
            .sheet(isPresented: $showSheet) {
                if sug {
                    MailView(
                        result: $result,
                        newSubject: "New Feature Suggestion",
                        newMsgBody: "I am enjoying this app, but I want to suggest a new feature!!!\n\nSuggestion:"
                    )
                } else {
                    MailView(
                        result: $result,
                        newSubject: "New Question Suggestion",
                        newMsgBody: "I am enjoying this app, but I want to send a new Question!!!\n\nCategory: \n\nQuestion: "
                    )
                }
            }
            
            Spacer().frame(height: 200)
        }
    }
    
    
    // MARK: - Bottom Info & Help Buttons
    private var bottomButtons: some View {
        VStack {
            Spacer()
            
            HStack {
                
                NavigationLink(destination: AboutView()) {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .padding(-7)
                        .background(Color.white)
                        .padding(13)
                        .cornerRadius(20)
                        .shadow(radius: 12)
                        .foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                }
                
                NavigationLink(destination: HelpView()) {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .padding(-7)
                        .background(Color(red: 55/255, green: 213/255, blue: 209/255))
                        .padding(13)
                        .cornerRadius(20)
                        .shadow(radius: 12)
                        .foregroundColor(.white)
                }
            }
            
            Spacer().frame(height: 200)
        }
    }
    
    
    // MARK: - Helper Functions
    func getImage(indexLocation: Int) -> String {
        return String(indexLocation % 2)
    }
    
    func getNumberOfRows() -> Int {
        let heightPerItem = UIScreen.main.bounds.width / CGFloat(itemsPerRow)
        return Int(UIScreen.main.bounds.height / heightPerItem) + 1
    }
    
    func suggestFeature() {
        print("Hurray! New Suggestion")
        if MFMailComposeViewController.canSendMail() {
            showSheet = true
        } else {
            print("Error sending mail")
        }
    }
}

#Preview {
    HomeView()
}
