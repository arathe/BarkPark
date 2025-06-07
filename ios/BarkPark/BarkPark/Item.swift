//
//  Item.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}