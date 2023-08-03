//
//  HKWorkoutExtensions.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import HealthKit

// MARK: - Identifiable

extension HKWorkout: Identifiable {
    public var id: UUID { uuid }
}

// MARK: -

extension HKWorkout {
    
    var systemImage: String {
        let activity = workoutActivities.first!
        let config = activity.workoutConfiguration

        switch config.activityType {
        case .cycling:
            switch config.locationType {
            case .outdoor:
                return "figure.outdoor.cycle"
            case .indoor:
                return "figure.indoor.cycle"
            case .unknown:
                return "figure.outdoor.cycle"
            @unknown default:
                return "figure.outdoor.cycle"
            }
        case .functionalStrengthTraining:
            return "figure.strengthtraining.functional"
        case .running:
            return "figure.run"
        case .surfingSports:
            return "figure.surfing"
        case .swimming:
            switch config.swimmingLocationType {
            case .openWater:
                return "figure.open.water.swim"
            case .pool:
                return "figure.pool.swim"
            case .unknown:
                return "figure.pool.swim"
            @unknown default:
                return "figure.pool.swim"
            }
        case .traditionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        default:
            return "figure.walk"
        }
    }

    var name: String {
        if let brandName = metadata?[HKMetadataKeyWorkoutBrandName] as? String {
            return brandName
        }

        let activity = workoutActivities.first!
        let config = activity.workoutConfiguration

        switch config.activityType {
        case .cycling:
            switch config.locationType {
            case .outdoor:
                return "Outdoor Cycling"
            case .indoor:
                return "Indoor Cycling"
            case .unknown:
                return "Cycling"
            @unknown default:
                return "Cycling"
            }
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
        case .surfingSports:
            return "Surfing"
        case .swimming:
            switch config.swimmingLocationType {
            case .openWater:
                return "Open Water Swim"
            case .pool:
                return "Pool Swim"
            case .unknown:
                return "Swimming"
            @unknown default:
                return "Swimming"
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
            let measurement = Measurement(value: meters ?? 0, unit: UnitLength.meters)
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
