//
//  Volume.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

enum VolumeUnit: String, PersistableEnum, CaseIterable {
    case l
    case ml
    case gal
}

class Volume: EmbeddedObject {
    @Persisted var value: Double
    @Persisted var unit: VolumeUnit

    static let baseUnit: VolumeUnit = .l

    static func exchangeRate(from: VolumeUnit, to: VolumeUnit) -> Double {
        let rates: [VolumeUnit: Double] = [
            .l: 1,
            .ml: 0.001,
            .gal: 3.78541
        ]
        return rates[from]! / rates[to]!
    }

    var inBaseUnit: Double {
        value * Self.exchangeRate(from: unit, to: Self.baseUnit)
    }

    func converted(to unit: VolumeUnit) -> Double {
        value * Self.exchangeRate(from: self.unit, to: unit)
    }

    static func +(lhs: Volume, rhs: Volume) -> Volume {
        let total = lhs.inBaseUnit + rhs.inBaseUnit
        let result = Volume()
        result.value = total / Self.exchangeRate(from: .l, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func -(lhs: Volume, rhs: Volume) -> Volume {
        let diff = lhs.inBaseUnit - rhs.inBaseUnit
        let result = Volume()
        result.value = diff / Self.exchangeRate(from: .l, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func <(lhs: Volume, rhs: Volume) -> Bool {
        lhs.inBaseUnit < rhs.inBaseUnit
    }

    static func ==(lhs: Volume, rhs: Volume) -> Bool {
        lhs.inBaseUnit == rhs.inBaseUnit
    }
}
