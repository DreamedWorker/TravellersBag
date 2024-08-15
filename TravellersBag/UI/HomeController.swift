//
//  HomeController.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/15.
//

import Foundation
import CoreData

/// 全局管理器
class HomeController : ObservableObject { // 这个类必须是单例类
    static let shared = HomeController()
    private init (){}
    
    @Published var showErrDialog: Bool = false // 显示错误弹窗
    @Published var errDialogMessage: String = ""
    @Published var showInfoDialog: Bool = false // 显示基本消息弹窗
    @Published var infoDialogMessage: String = ""
    
    @Published var context: NSManagedObjectContext? = nil
    @Published var currentUser: ShequAccount? = nil
    
    func initSomething(inContext: NSManagedObjectContext) {
        context = inContext
        currentUser = CoreDataHelper.shared.fetchDefaultUser()
        if currentUser == nil {
            print("you have not set a default account yet.")
        }
    }
    
    /// 呼出一个错误弹窗 【必须在UI线程执行】
    func showErrorDialog(msg: String) {
        showErrDialog = true; errDialogMessage = msg
    }
    
    /// 呼出一个基本信息弹窗 【必须在UI线程执行】
    func showInfomationDialog(msg: String) {
        showInfoDialog = true; infoDialogMessage = msg
    }
}
