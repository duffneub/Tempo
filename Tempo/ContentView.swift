//
//  ContentView.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit
import SwiftUI

struct ContentView: View {

    @Binding var workouts: [HKWorkout]

    @Environment(\.loadWorkouts) private var loadWorkouts

    @State private var isLoading = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
            } else {
                List(workouts, id: \.uuid) { workout in
                    NavigationLink(value: workout) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(workout.name)")
                                    .font(.headline)
                                Text("\(workout.info)")
                                    .font(.subheadline)
                            }

                            Spacer()

                            Text("\(workout.relativeDate)")
                                .font(.caption)
                        }
                    }

                }
                .task {
                    guard workouts.isEmpty else { return }

                    do {
                        isLoading = true
                        workouts = try await loadWorkouts()
                        isLoading = false
                        print("Fetched \(workouts.count) workouts!")
                    } catch {
                        print("Error: \(error).")
                    }
                }
            }
        }
        .navigationTitle("Workouts")
    }
}

extension HKWorkout {

    var name: String {
        if let brandName = metadata?[HKMetadataKeyWorkoutBrandName] as? String {
            return brandName
        }

        let activity = workoutActivities.first!
        let config = activity.workoutConfiguration

        switch config.activityType {
        case .running:
            switch config.locationType {
            case .outdoor:
                return "Outdoor Run"
            case .indoor:
                return "Indoor Run"
            case .unknown:
                return "Run"
            @unknown default:
                return "Run"
            }
        default:
            return "Unsupported"
        }
    }

    var info: String {
        let activity = workoutActivities.first!
        let config = activity.workoutConfiguration

        switch config.activityType {
        case .running:
            let distance = statistics(for: .init(.distanceWalkingRunning))
            let meters = distance?.sumQuantity()?.doubleValue(for: .meter())
            let measurement = Measurement(value: meters!, unit: UnitLength.meters)
            return measurement.formatted(.measurement(width: .abbreviated))

        default:
            return Duration
                .seconds(duration)
                .formatted(
                    .time(pattern: .hourMinute)
                )
        }
    }

    var relativeDate: String {
        if startDate.inTheLastWeek() {
            return startDate.formatted(.dateTime.weekday(.wide))
        } else {
            return startDate.formatted(date: .numeric, time: .omitted)
        }
    }

}

extension Date {

    func inTheLastWeek(calendar: Calendar = .current, now: Date = Date()) -> Bool {
        let startOfDay = calendar.startOfDay(for: now)
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfDay)!
        return self > sixDaysAgo
    }

}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(workouts: .constant([]))
//            .environment(\.loadWorkouts, .init(store: MockHealthStore(
//                isHealthDataAvailableHandler: { true },
//                requestAuthorizationHandler: { _, _ in },
//                executeHandler: { query in
//                    query.res[
//                        HKWorkout(activityType: .running, start: Date(), end: Date().addingTimeInterval(60 * 60))
//                    ]
//                }
//            )))
//    }
//}
