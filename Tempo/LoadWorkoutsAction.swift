//
//  LoadWorkoutsAction.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import Foundation
import HealthKit
import SwiftUI

protocol HealthStore {

    func isHealthDataAvailable() -> Bool
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws
    func execute(_ query: HKQuery)

}

private extension HealthStore {

    @MainActor
    func samples<S : HKSample>(
        ofType sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [S] {
        try await withUnsafeThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                Task { @MainActor in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(returning: samples!.compactMap { $0 as? S })
                }
            }

            execute(query)
        }
    }

}

class MockHealthStore: HealthStore {

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

extension HealthStore where Self == MockHealthStore {

    static var fatal: MockHealthStore {
        MockHealthStore(
            isHealthDataAvailableHandler: { fatalError() },
            requestAuthorizationHandler: { _, _ in fatalError() },
            executeHandler: { _ in fatalError() }
        )
    }

}

struct LoadWorkoutsActionKey: EnvironmentKey {
    static var defaultValue = LoadWorkoutsAction(store: .fatal)
}

extension EnvironmentValues {

    var loadWorkouts: LoadWorkoutsAction {
        get { self[LoadWorkoutsActionKey.self] }
        set { self[LoadWorkoutsActionKey.self] = newValue }
    }

}

@MainActor
struct LoadWorkoutsAction {

    let store: HealthStore

    // Does this throw a specific error without authorization?
    func callAsFunction() async throws -> [HKWorkout] {
        guard store.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }

        let workoutType = HKObjectType.workoutType()

        try await store.requestAuthorization(
            toShare: [],
            read: [workoutType]
        )

//        let now = Date()
//        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
//        let startOfToday = Calendar.current.date(from: components)!
//        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
//        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: tomorrow)!
//        let inTheLastWeek = HKQuery.predicateForSamples(withStart: lastWeek, end: tomorrow)

        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await store.samples(
            ofType: workoutType,
            predicate: nil,//inTheLastWeek,
            limit: 100,
            sortDescriptors: [sortByDate]
        )
    }

}

extension HKHealthStore: HealthStore {

    func isHealthDataAvailable() -> Bool {
        Self.isHealthDataAvailable()
    }

}

