//
//  Race.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 22/09/2025.
//

import Foundation
import SwiftData

@Model
final class Race {
    var name: String
    var start: Date
    var end: Date
    var yourPosition: Int

    init(name: String, start: Date, end: Date, yourPostion: Int) {
        self.name = name
        self.start = start
        self.end = end
        self.yourPosition = yourPostion
    }
    
    func minutesLeft() -> Double {
        return end.timeIntervalSince(Date()) / 60
    }
    
    func timeLeft() -> String {
        let minutes = Int(ceil(minutesLeft()))
        
        if ( minutes/60 > 24 ){
            return "\(minutes/60/24) days left"
        }
        
        if ( minutes < 120 ){
            return "\(minutes) minutes left"
        }
        
        return "\(minutes/60) hours left"
    }
}
