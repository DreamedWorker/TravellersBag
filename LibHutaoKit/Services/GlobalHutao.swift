//
//  GlobalHutao.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation
import CoreData

/// 给全局使用的胡桃云功能
class GlobalHutao {
    /// 初始化过的胡桃云能力
    static let shared = GlobalHutao()
    private init() {}
    
    var dm: NSManagedObjectContext? = nil
    var hutao: HutaoAccount? = nil
    
    /// 初始化能力 必须在应用显示之前加载
    func initSomething(dm: NSManagedObjectContext) {
        self.dm = dm
        hutao = try? dm.fetch(HutaoAccount.fetchRequest()).first
    }
    
    /// 是否登录
    func hasAccount() -> Bool {
        return hutao != nil
    }
    
    func refresh() {
        hutao = try? dm!.fetch(HutaoAccount.fetchRequest()).first
    }
}
