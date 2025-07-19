//
//  Weight.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

enum WeightUnit: String, PersistableEnum, CaseIterable {
    case mg
    case g
    case kg
    case tonne
    case lb
    case oz
}

class Weight: EmbeddedObject {
    @Persisted var value: Double
    @Persisted var unit: WeightUnit

    static let baseUnit: WeightUnit = .kg

    convenience init(value: Double, unit: WeightUnit) {
        self.init()
        self.value = value
        self.unit = unit
    }

    static func exchangeRate(from: WeightUnit, to: WeightUnit) -> Double {
        let rates: [WeightUnit: Double] = [
            .mg: 0.000001,
            .g: 0.001,
            .kg: 1,
            .tonne: 1000,
            .lb: 0.453592,
            .oz: 0.0283495
        ]
        return rates[from]! / rates[to]!
    }

    var inBaseUnit: Double {
        value * Self.exchangeRate(from: unit, to: Self.baseUnit)
    }

    func converted(to unit: WeightUnit) -> Double {
        value * Self.exchangeRate(from: self.unit, to: unit)
    }

    func convertedWeight(to unit: WeightUnit) -> Weight {
        let convertedValue = self.converted(to: unit)
        return Weight(value: convertedValue, unit: unit)
    }

    func optimizedUnit() -> Weight {
        let unitsDescending: [WeightUnit] = [.tonne, .kg, .g, .mg]
        for targetUnit in unitsDescending {
            let convertedValue = self.converted(to: targetUnit)
            if convertedValue >= 1 {
                return Weight(value: convertedValue, unit: targetUnit)
            }
        }
        return Weight(value: self.converted(to: .mg), unit: .mg)
    }

    static func +(lhs: Weight, rhs: Weight) -> Weight {
        let total = lhs.inBaseUnit + rhs.inBaseUnit
        return Weight(value: total, unit: .kg)
    }

    static func -(lhs: Weight, rhs: Weight) -> Weight {
        let diff = lhs.inBaseUnit - rhs.inBaseUnit
        return Weight(value: diff, unit: .kg)
    }

    static func <(lhs: Weight, rhs: Weight) -> Bool {
        lhs.inBaseUnit < rhs.inBaseUnit
    }

    static func ==(lhs: Weight, rhs: Weight) -> Bool {
        lhs.inBaseUnit == rhs.inBaseUnit
    }
}
