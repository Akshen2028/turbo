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
    var textColor: Color = .black  // Optional text color, defaults to black

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text(card.q)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .frame(width: min(250, geometry.size.width - 32), alignment: .leading)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.3)  // Allow shrinking down to 30% of original size
                        .padding()

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)
            }
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
