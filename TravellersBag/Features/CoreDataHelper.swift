//
//  CoreDataHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/15.
//

import Foundation
import CoreData

/// CoreData 自定的操作单例类
class CoreDataHelper : ObservableObject {
    /// 初始化过的CoreData操作方法
    static let shared = CoreDataHelper()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TravellersBagModel")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    private init (){}
}

extension CoreDataHelper {
    
    /// 保存CoreData的更改
    func save() -> Bool {
        guard persistentContainer.viewContext.hasChanges else { return true } // 没有修改时无需保存 故成功也无妨
        do {
            try persistentContainer.viewContext.save()
            return true
        } catch {
            return false
        }
    }
    
    /// 获取默认账号（如果有）
    func fetchDefaultUser() -> ShequAccount? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ShequAccount")
        request.predicate = NSPredicate(format: "active == %@", "1")
        do {
            guard let result = try self.persistentContainer.viewContext.fetch(request).first else { return nil }
            return result as? ShequAccount
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("error.fetch_default_user", comment: ""),
                    error.localizedDescription
                )
            )
            return nil
        }
    }
    
    /// 删除账号
    func deleteUser(single: ShequAccount) {
        persistentContainer.viewContext.delete(single)
    }
}
