//
//  Card.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation

struct Card: Identifiable, Hashable {
    let id = UUID()
    let text: String
}
