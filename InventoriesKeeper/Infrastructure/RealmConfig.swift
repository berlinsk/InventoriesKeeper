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
                RGame.self,
                RItem.self,
                RInventory.self,
                ItemInventoryCommonFields.self,
                FoodItemDetails.self,
                LiquidItemDetails.self,
                BookItemDetails.self,
                WeaponItemDetails.self,
                CharacterInventoryDetails.self,
                LocationInventoryDetails.self,
                VehicleInventoryDetails.self,
                Weight.self,
                Currency.self,
                Volume.self,
                Calorie.self,
                GameDate.self
            ]
        )

        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
    
    static func configureForUser(username: String) {
        let fileURL = FileManager.documentsURL.appendingPathComponent("\(username).realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [
                RGame.self,
                RItem.self,
                RInventory.self,
                ItemInventoryCommonFields.self,
                FoodItemDetails.self,
                LiquidItemDetails.self,
                BookItemDetails.self,
                WeaponItemDetails.self,
                CharacterInventoryDetails.self,
                LocationInventoryDetails.self,
                VehicleInventoryDetails.self,
                Weight.self,
                Currency.self,
                Volume.self,
                Calorie.self,
                GameDate.self
            ]
        )
        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
}
