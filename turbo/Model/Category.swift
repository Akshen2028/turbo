//
//  Category.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct Category: Identifiable, Equatable {
    let id: Int       // 0...6 for default categories, or -1 for custom categories
    let name: String  // "Family", "Friends", etc.
    let imageName: String
    let isCustom: Bool
    let customCategoryId: UUID? // Only set for custom categories
    
    init(id: Int, name: String, imageName: String, isCustom: Bool = false, customCategoryId: UUID? = nil) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.isCustom = isCustom
        self.customCategoryId = customCategoryId
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id && lhs.isCustom == rhs.isCustom && lhs.customCategoryId == rhs.customCategoryId
    }
}

