//
//  RealmResetService.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation
import RealmSwift

enum RealmResetService {
    static func reset() {
        guard let baseURL = Realm.Configuration.defaultConfiguration.fileURL else { return }
        let fm = FileManager.default

        fm.removeItemIfExists(at: baseURL)
        fm.removeItemIfExists(at: baseURL.appendingPathExtension("lock"))
        fm.removeItemIfExists(at: baseURL.appendingPathExtension("note"))

        let managementURL = baseURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(baseURL.lastPathComponent).management")
        fm.removeItemIfExists(at: managementURL)
    }
}
