//
//  GetWorkoutRoute.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/4/23.
//

import Foundation
import HealthKit
import MapKit
import SwiftUI

protocol WorkoutRouteService {

    func isHealthDataAvailable() -> Bool
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws
    func execute(_ query: HKQuery)

}

class MockWorkoutRouteService: WorkoutRouteService {

    private let isHealthDataAvailableHandler: () -> Bool
    private let requestAuthorizationHandler: (Set<HKSampleType>, Set<HKObjectType>) async throws -> Void
    private let executeHandler: (HKQuery) -> Void

    init(
        isHealthDataAvailableHandler: @escaping () -> Bool,
        requestAuthorizationHandler: @escaping (Set<HKSampleType>, Set<HKObjectType>) async throws -> Void,
        executeHandler: @escaping (HKQuery) -> Void
    ) {
        self.isHealthDataAvailableHandler = isHealthDataAvailableHandler
        self.requestAuthorizationHandler = requestAuthorizationHandler
        self.executeHandler = executeHandler
    }

    func isHealthDataAvailable() -> Bool {
        isHealthDataAvailableHandler()
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>, read typesToRead: Set<HKObjectType>
    ) async throws {
        try await requestAuthorizationHandler(typesToShare, typesToRead)
    }

    func execute(_ query: HKQuery) {
        executeHandler(query)
    }

}

extension WorkoutRouteService where Self == MockWorkoutRouteService {

    static var fatal: MockWorkoutRouteService {
        MockWorkoutRouteService(
            isHealthDataAvailableHandler: { fatalError() },
            requestAuthorizationHandler: { _, _ in fatalError() },
            executeHandler: { _ in fatalError() }
        )
    }

}

struct WorkoutRouteKey: EnvironmentKey {
    static var defaultValue = WorkoutRoute(service: .fatal)
}

extension EnvironmentValues {

    var workoutRoute: WorkoutRoute {
        get { self[WorkoutRouteKey.self] }
        set { self[WorkoutRouteKey.self] = newValue }
    }

}

@MainActor
struct WorkoutRoute {
    
    let service: WorkoutRouteService
    
    func callAsFunction(workout: HKWorkout) async throws -> [CLLocation] {
        guard service.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }
        
        // TODO: Move all this permission query stuff out
        try await service.requestAuthorization(
            toShare: [],
            read: [
                HKSeriesType.workoutRoute(),
                HKSeriesType.workoutType(),
            ]
        )
        
        let route: HKWorkoutRoute = try await service.samples(
            type: HKSeriesType.workoutRoute(),
            predicate: HKQuery.predicateForObjects(from: workout),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ).first!
        
        return try await service.locations(for: route)
    }
    
}

private extension WorkoutRouteService {
    
    @MainActor
    func samples<S : HKSample>(
        type: HKSampleType,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        limit: Int
    ) async throws -> [S] {
        try await withUnsafeThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: type,
                predicate: predicate,
                anchor: anchor,
                limit: limit
            ) { _, samples, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples!.compactMap { $0 as? S })
            }
            
            execute(query)
        }
    }
    
    @MainActor
    func locations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withUnsafeThrowingContinuation { continuation in
            var allLocations: [CLLocation] = []

            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                allLocations.append(contentsOf: locations!)
                
                guard !done else {
                    continuation.resume(returning: allLocations)
                    return
                }
            }
            
            execute(query)
        }
    }
    
}

extension HKHealthStore: WorkoutRouteService {}
