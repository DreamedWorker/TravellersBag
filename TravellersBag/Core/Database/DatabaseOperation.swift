//
//  DatabaseOperation.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import Foundation
import SwiftData

/// 应用数据库
let tbDatabase = try! ModelContainer(
    for: MihoyoAccount.self, HutaoPassport.self, GachaItem.self
)

/// 应用数据库操作封装
class TBDao {
    /// 写入并保存（自动）
    static func writeRow2Db(item row: any PersistentModel..., sendError: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            row.forEach { it in
                tbDatabase.mainContext.insert(it)
            }
            saveAfterChanges(sendError: sendError)
        }
    }
    
    /// 删除并保存（自动）
    static func deleteRow4Db(item row: any PersistentModel..., sendError: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            row.forEach { it in
                tbDatabase.mainContext.delete(it)
            }
            saveAfterChanges(sendError: sendError)
        }
    }
    
    /// 保存此前的全部更改
    static func saveAfterChanges(sendError: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            do {
                try tbDatabase.mainContext.save()
            } catch {
                sendError("数据库保存时出错：\(error.localizedDescription)")
            }
        }
    }
}

extension TBDao {
    @MainActor static func getDefaultAccount() -> MihoyoAccount? {
        let fetch = FetchDescriptor<MihoyoAccount>(predicate: #Predicate { $0.active == true })
        return try? tbDatabase.mainContext.fetch(fetch).first
    }
    
    @MainActor static func getCurrentAccountGachaRecords() -> [GachaItem] {
        if let current = self.getDefaultAccount() {
            let uid = current.gameInfo.genshinUID
            let querier = FetchDescriptor<GachaItem>(predicate: #Predicate { $0.uid == uid })
            do {
                return try tbDatabase.mainContext.fetch(querier)
            } catch {
                return []
            }
        } else {
            return []
        }
    }
}
