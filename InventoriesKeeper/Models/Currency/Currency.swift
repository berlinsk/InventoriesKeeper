//
//  Currency.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 03.07.2025.
//

import Foundation
import RealmSwift

enum CurrencyUnit: String, PersistableEnum, CaseIterable {
    case currency1
    case currency2
    case currency3
    case currency4
}

class Currency: EmbeddedObject {
    @Persisted var value: Double
    @Persisted var unit: CurrencyUnit

    static let baseUnit: CurrencyUnit = .currency1
    
    convenience init(value: Double, unit: CurrencyUnit) {
        self.init()
        self.value = value
        self.unit = unit
    }

    static func exchangeRate(from: CurrencyUnit, to: CurrencyUnit) -> Double {
        let rates: [CurrencyUnit: Double] = [
            .currency1: 1,
            .currency2: 40,
            .currency3: 43,
            .currency4: 2500000
        ]
        return rates[from]! / rates[to]!
    }

    var inBaseUnit: Double {
        value * Self.exchangeRate(from: unit, to: Self.baseUnit)
    }

    func converted(to unit: CurrencyUnit) -> Double {
        value * Self.exchangeRate(from: self.unit, to: unit)
    }

    static func +(lhs: Currency, rhs: Currency) -> Currency {
        let total = lhs.inBaseUnit + rhs.inBaseUnit
        let result = Currency()
        result.value = total / Self.exchangeRate(from: .currency1, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func -(lhs: Currency, rhs: Currency) -> Currency {
        let diff = lhs.inBaseUnit - rhs.inBaseUnit
        let result = Currency()
        result.value = diff / Self.exchangeRate(from: .currency1, to: lhs.unit)
        result.unit = lhs.unit
        return result
    }

    static func <(lhs: Currency, rhs: Currency) -> Bool {
        lhs.inBaseUnit < rhs.inBaseUnit
    }

    static func ==(lhs: Currency, rhs: Currency) -> Bool {
        lhs.inBaseUnit == rhs.inBaseUnit
    }
}
