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
                    .environment(\.loadWorkouts, .init(store: healthStore))
                    .navigationDestination(for: HKWorkout.self, destination: WorkoutDetailsView.init)
            }
        }
    }
}
