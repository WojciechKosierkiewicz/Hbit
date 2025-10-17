//
//  HealthKitAdapter.swift
//  Hbit
//
//  Created by Wojciech Kosierkiewicz on 05/10/2025.
//
import HealthKit
import SwiftUI

public final class HealthKitAdapter {
    public static let instance = HealthKitAdapter()
    public let healthStore = HKHealthStore()
    
    private init() {}
    
    public func requestHealthKitAuthorization() async -> String {
        // Define what data types to read
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        // Define what data types to write (none for now)
        let writeTypes: Set<HKSampleType> = []

        // Bridge the callback to async using a continuation
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if success {
                    continuation.resume(returning: "✅ HealthKit authorization granted")
                } else {
                    continuation.resume(returning: "❌ HealthKit authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
