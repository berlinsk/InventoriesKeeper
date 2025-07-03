//
//  FileManager+Documents.swift
//  InventoriesKeeper
//
//  Created by Берлинский Ярослав Владленович on 02.07.2025.
//

import Foundation

extension FileManager {
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func removeItemIfExists(at url: URL) {
        if fileExists(atPath: url.path) {
            try? removeItem(at: url)
        }
    }
}
