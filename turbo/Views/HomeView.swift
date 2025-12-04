//
//  ContentView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Talkaholic")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink("Select Category") {
                    PlaceholderView(title: "Category Selection")
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Send Questions") {
                    PlaceholderView(title: "Send Questions")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.medium)
            .padding()
            .navigationTitle(title)
    }
}

#Preview {
    HomeView()
}
