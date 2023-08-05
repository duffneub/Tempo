//
//  TempoApp.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit
import SwiftUI

@main
struct TempoApp: App {
    
    let healthStore = HKHealthStore()

    @State private var workouts: [Date: [HKWorkout]] = [:]

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WorkoutList()
                    .navigationDestination(for: HKWorkout.self, destination: WorkoutDetailsView.init)
            }
            .environment(\.loadWorkouts, .init(store: healthStore))
            .environment(\.workoutRoute, .init(service: healthStore))
        }
    }
}
