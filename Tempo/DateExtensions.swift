//
//  DateExtensions.swift
//  Tempo
//
//  Created by Duff Neubauer on 8/2/23.
//

import Foundation

extension Date {

    func inTheLastWeek(calendar: Calendar = .current, now: Date = Date()) -> Bool {
        let startOfDay = calendar.startOfDay(for: now)
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfDay)!
        return self > sixDaysAgo
    }

}
