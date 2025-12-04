//
//  Category.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation

struct Category: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let imageName: String
    let questions: [String]
}
