//
//  Weight.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

enum WeightUnit: String, PersistableEnum, CaseIterable {
    case kg
    case g
    case lb
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
            .kg: 1,
            .g: 0.001,
            .lb: 0.453592
        ]
        return rates[from]! / rates[to]!
    }

    var inBaseUnit: Double {
        value * Self.exchangeRate(from: unit, to: Self.baseUnit)
    }

    func converted(to unit: WeightUnit) -> Double {
        value * Self.exchangeRate(from: self.unit, to: unit)
    }

    static func +(lhs: Weight, rhs: Weight) -> Weight {
        let total = lhs.inBaseUnit + rhs.inBaseUnit
        let result = Weight()
        result.value = total / Self.exchangeRate(from: .kg, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func -(lhs: Weight, rhs: Weight) -> Weight {
        let diff = lhs.inBaseUnit - rhs.inBaseUnit
        let result = Weight()
        result.value = diff / Self.exchangeRate(from: .kg, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func <(lhs: Weight, rhs: Weight) -> Bool {
        lhs.inBaseUnit < rhs.inBaseUnit
    }

    static func ==(lhs: Weight, rhs: Weight) -> Bool {
        lhs.inBaseUnit == rhs.inBaseUnit
    }
}
