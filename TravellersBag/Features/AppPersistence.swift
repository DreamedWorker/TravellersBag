//
//  AppPersistence.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/6.
//

import Foundation
import CoreData

class AppPersistence : ObservableObject {
    static let shared = AppPersistence()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TravellersModel")
        container.loadPersistentStores(completionHandler: {_, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        })
        return container
    }()
    
    private init (){}
}

extension AppPersistence {
    func save() -> EventMessager {
        guard persistentContainer.viewContext.hasChanges else { return EventMessager(evtState: false, data: "无需保存") }
        do {
            try persistentContainer.viewContext.save()
            return EventMessager(evtState: true, data: 0)
        } catch {
            return EventMessager(evtState: false, data: error.localizedDescription)
        }
    }
    
    func deleteUser(item: HoyoAccounts) -> EventMessager {
        persistentContainer.viewContext.delete(item)
        return EventMessager(evtState: true, data: 0)
    }
}
