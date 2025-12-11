//
//  CustomCategoryModels.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-10.
//

import Foundation

struct CustomCategory: Identifiable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let questions: [SavedQuestion]
    
    static func == (lhs: CustomCategory, rhs: CustomCategory) -> Bool {
        lhs.id == rhs.id
    }
}

struct SavedQuestion: Identifiable, Equatable {
    let id: UUID
    let question: String
    let createdAt: Date
    
    static func == (lhs: SavedQuestion, rhs: SavedQuestion) -> Bool {
        lhs.id == rhs.id
    }
}

