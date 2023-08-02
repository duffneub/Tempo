//
//  WorkoutDetailsView.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit
import MapKit
import SwiftUI

struct WorkoutDetailsView: View {

    let workout: HKWorkout

    var body: some View {
        VStack {
            Text("Morning Run")
                .font(.title)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)

//            Map(coordinateRegion: .constant(.init(center: <#T##CLLocationCoordinate2D#>, latitudinalMeters: <#T##CLLocationDistance#>, longitudinalMeters: <#T##CLLocationDistance#>)))

            Section {

                Grid(horizontalSpacing: 80, verticalSpacing: 20) {
                    GridRow {
                        if let distance = workout.totalDistanceWalkingRunning {
                            VStack {
                                Text("Distance")
                                    .font(.caption)
                                Text(distance.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }

                        if let speed = workout.averageRunningSpeed {
                            VStack {
                                Text("Avg Pace")
                                    .font(.caption)
                                Text(speed.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }
                    }

                    GridRow {
                        VStack {
                            Text("Moving Time")
                                .font(.caption)
                            Text(workout.totalTime.formatted(.measurement(width: .abbreviated)))
                                .font(.headline)
                        }

                        VStack {
                            Text("Elevation Gain")
                                .font(.caption)
                            Text("???")
                                .font(.headline)
                        }
                    }

                    GridRow {
                        VStack {
                            Text("Avg Power")
                                .font(.caption)
                            Text("221 W")
                                .font(.headline)
                        }

                        if let heartRate = workout.averageHeartRate {
                            VStack {
                                Text("Avg Heart Rate")
                                    .font(.caption)
                                Text(heartRate.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .onAppear {
            print("Metadata: \(workout.metadata)")
        }
    }
}

private extension HKWorkout {

    var totalDistanceWalkingRunning: Measurement<UnitLength>? {
        statistics(for: .init(.distanceWalkingRunning))?
            .sumQuantity()
            .map {
                Measurement(
                    value: $0.doubleValue(for: .meter()),
                    unit: UnitLength.meters)
            }
    }

    var averageRunningSpeed: Measurement<UnitSpeed>? {
        guard let distance = totalDistanceWalkingRunning else { return nil }

        return Measurement(value: distance.converted(to: .meters).value / totalTime.converted(to: .seconds).value, unit: UnitSpeed.metersPerSecond)

//        statistics(for: .init(.runningSpeed))?
//            .averageQuantity()
//            .map {
//                Measurement(
//                    value: $0.doubleValue(for: .meter().unitDivided(by: .second())),
//                    unit: UnitSpeed.metersPerSecond)
//            }
    }

    var totalTime: Measurement<UnitDuration> {
        Measurement(value: duration, unit: UnitDuration.seconds)
    }

    var averageHeartRate: Measurement<UnitFrequency>? {
        statistics(for: .init(.heartRate))?
            .averageQuantity()
            .map {
                Measurement(
                    value: $0.doubleValue(for: .count().unitDivided(by: .second())),
                    unit: UnitFrequency(symbol: "bpm"))
            }
    }

}

//struct WorkoutDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutDetailsView(workout: .init)
//    }
//}
