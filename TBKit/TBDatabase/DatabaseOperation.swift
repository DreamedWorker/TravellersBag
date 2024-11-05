//
//  DatabaseOperation.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import Foundation
import SwiftData

class TBDatabaseOperation {
    @MainActor static func write2db(item: any PersistentModel) throws {
        tbDatabase.mainContext.insert(item)
        try tbDatabase.mainContext.save()
    }
    
    @MainActor static func saveAfterChanges() throws {
        try tbDatabase.mainContext.save()
    }
    
    @MainActor static func delete4db(item: any PersistentModel) throws {
        tbDatabase.mainContext.delete(item)
        try saveAfterChanges()
    }
}
