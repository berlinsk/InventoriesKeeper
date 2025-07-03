//
//  GameDate.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

class GameDate: EmbeddedObject {
    @Persisted var day: Int = 1
    @Persisted var month: Int = 1
    @Persisted var year: Int = 1850

    func daysInMonth(month: Int, year: Int) -> Int {
        switch month {
        case 2:
            return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    func incrementDay() {
        day += 1
        if day > daysInMonth(month: month, year: year) {
            day = 1
            month += 1
            if month > 12 {
                month = 1
                year += 1
            }
        }
    }

    func decrementDay() {
        day -= 1
        if day < 1 {
            month -= 1
            if month < 1 {
                month = 12
                year -= 1
            }
            day = daysInMonth(month: month, year: year)
        }
    }

    var formatted: String {
        String(format: "%02d.%02d.%d", day, month, year)
    }

    func isBefore(_ other: GameDate) -> Bool {
        if year != other.year { return year < other.year }
        if month != other.month { return month < other.month }
        return day < other.day
    }

    func isAfter(_ other: GameDate) -> Bool {
        if year != other.year { return year > other.year }
        if month != other.month { return month > other.month }
        return day > other.day
    }
}
