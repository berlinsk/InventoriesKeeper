//
//  RealmConfig.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation
import RealmSwift

enum RealmConfig {
    static func configure(
        resetOnLaunch: Bool = false,
        inMemoryIdentifier: String? = nil,
        objectTypes: [Object.Type]? = nil
    ) {
        if resetOnLaunch {
            RealmResetService.reset()
        }

        let config = Realm.Configuration(
            inMemoryIdentifier: inMemoryIdentifier,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: objectTypes ?? [
                RItem.self,
                RInventory.self,
                ItemInventoryCommonFields.self,
                FoodItemDetails.self,
                LiquidItemDetails.self,
                BookItemDetails.self,
                WeaponItemDetails.self,
                CharacterInventoryDetails.self,
                LocationInventoryDetails.self,
                VehicleInventoryDetails.self
            ]
        )

        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
}
