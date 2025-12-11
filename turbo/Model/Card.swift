//
//  Card.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation

struct Card: Identifiable, Equatable {
    var id = UUID().uuidString
    var offset: CGFloat = 0
    var q: String
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}
