//
//  Item.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 22/09/2025.
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
