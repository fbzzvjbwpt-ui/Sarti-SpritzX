//
//  Item.swift
//  Sarti SpritzX
//
//  Created by Tobias Thiele on 12.09.26.
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
