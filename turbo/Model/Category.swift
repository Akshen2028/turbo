//
//  Category.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct Category: Identifiable, Equatable {
    let id: Int       // 0...5 like old infoView.id
    let name: String  // "Family", "Friends", etc.
    let imageName: String
}

