//
//  Volume.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

enum VolumeUnit: String, PersistableEnum, CaseIterable {
    case ml
    case l
    case m3
    case gal
    case qt
    case pt
    case floz
}

class Volume: EmbeddedObject {
    @Persisted var value: Double
    @Persisted var unit: VolumeUnit

    static let baseUnit: VolumeUnit = .l

    convenience init(value: Double, unit: VolumeUnit) {
        self.init()
        self.value = value
        self.unit = unit
    }

    static func exchangeRate(from: VolumeUnit, to: VolumeUnit) -> Double {
        let rates: [VolumeUnit: Double] = [
            .ml: 0.001,
            .l: 1,
            .m3: 1000,
            .gal: 3.78541,
            .qt: 0.946353,
            .pt: 0.473176,
            .floz: 0.0295735
        ]
        return rates[from]! / rates[to]!
    }

    var inBaseUnit: Double {
        value * Self.exchangeRate(from: unit, to: Self.baseUnit)
    }

    func converted(to unit: VolumeUnit) -> Double {
        value * Self.exchangeRate(from: self.unit, to: unit)
    }

    func convertedVolume(to unit: VolumeUnit) -> Volume {
        let convertedValue = self.converted(to: unit)
        return Volume(value: convertedValue, unit: unit)
    }

    func optimizedUnit() -> Volume {
        let unitsDescending: [VolumeUnit] = [.m3, .l, .ml]
        for targetUnit in unitsDescending {
            let convertedValue = self.converted(to: targetUnit)
            if convertedValue >= 1 {
                return Volume(value: convertedValue, unit: targetUnit)
            }
        }
        return Volume(value: self.converted(to: .ml), unit: .ml)
    }

    static func +(lhs: Volume, rhs: Volume) -> Volume {
        let total = lhs.inBaseUnit + rhs.inBaseUnit
        return Volume(value: total, unit: .l)
    }

    static func -(lhs: Volume, rhs: Volume) -> Volume {
        let diff = lhs.inBaseUnit - rhs.inBaseUnit
        return Volume(value: diff, unit: .l)
    }

    static func <(lhs: Volume, rhs: Volume) -> Bool {
        lhs.inBaseUnit < rhs.inBaseUnit
    }

    static func ==(lhs: Volume, rhs: Volume) -> Bool {
        lhs.inBaseUnit == rhs.inBaseUnit
    }
}
