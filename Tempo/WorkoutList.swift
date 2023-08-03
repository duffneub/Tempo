//
//  WorkoutList.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit
import SwiftUI

struct WorkoutList: View {

    @Environment(\.loadWorkouts) private var loadWorkouts

    @State private var isLoading = false
    @State private var workouts: [Date: [HKWorkout]] = [:]

    var body: some View {
        VStack {
            List {
                ForEach(workoutMonths, id: \.self) { date in
                    Section {
                        ForEach(workouts(for: date)) { workout in
                            Row(workout: workout)
                        }
                    } header: {
                        Text(date.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                    }
                }
            }
            .task(loadWorkouts)
            .redacted(reason: isLoading ? .placeholder : [])
        }
        .navigationTitle("Workouts")
    }
    
}

// MARK: - Views

private extension WorkoutList {
    
    var workoutMonths: [Date] {
        let workouts = isLoading ? workoutsPlaceholder : workouts
        return workouts.keys.sorted().reversed()
    }
    
    func workouts(for date: Date) -> [HKWorkout] {
        let workouts = isLoading ? workoutsPlaceholder : workouts
        return (workouts[date] ?? []).sorted(by: { $0.endDate > $1.endDate })
    }
    
    var workoutsPlaceholder: [Date: [HKWorkout]] {
        [
            Date(): [
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
            ],
            Date.distantPast: [
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
            ],
            Date.distantFuture: [
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
                HKWorkout(activityType: .running, start: Date(), end: Date()),
            ]
        ]
    }
    
}

// MARK: - Actions

private extension WorkoutList {
    
    @Sendable
    func loadWorkouts() async {
        guard workouts.isEmpty else { return }

        do {
            isLoading = true
            workouts = (try await loadWorkouts())
                .grouping { workout in
                    let comps = Calendar.current.dateComponents([.year, .month], from: workout.endDate)
                    return Calendar.current.date(from: comps)!
                }
            isLoading = false
        } catch {
            print("Error: \(error).")
        }
    }
    
}

// MARK: - WorkoutRow

private extension WorkoutList {
    
    private struct Row: View {
        
        let workout: HKWorkout
        
        var body: some View {
            NavigationLink(value: workout) {
                HStack {
                    Image(systemName: workout.systemImage)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("\(workout.name)")
                            .font(.subheadline)
                        Text("\(workout.info)")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    Text("\(workout.relativeDate)")
                        .font(.caption)
                }
            }
        }
        
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
