//
//  CardView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import SwiftUI

struct CardView: View {

    let card: Card
    var animation: Namespace.ID

    var body: some View {
        VStack {
            HStack {
                Text(card.q)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(width: 250, alignment: .leading)
                    .padding()

                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.white
                .cornerRadius(25)
        )
        .id(card.id)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        CardView(
            card: Card(q: "Example question"),
            animation: Namespace().wrappedValue
        )
        .frame(width: 300, height: 400)
        .padding()
    }
}
