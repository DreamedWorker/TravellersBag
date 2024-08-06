//
//  LocalNotification.swift
//  TravellingBag
//
//  Created by 鸳汐 on 2024/8/4.
//

import Foundation
import UserNotifications
import MMKV

class LocalNotification {
    private static var instance: LocalNotification?
    private var shouldMakeNotice: Bool
    let center = UNUserNotificationCenter.current()
    
    private init() {
        shouldMakeNotice = MMKV.default()!.bool(forKey: "canNotice", defaultValue: false)
    }
    
    static var shared: LocalNotification {
        if instance == nil {
            instance = LocalNotification()
        }
        return instance!
    }
    
    /// 发起权限请求 如果被拒绝了后续则静默 每次都执行以判断用户是否允许发送通知 并将情况写入config
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {granted, error in
            guard granted else { return }
            self.center.getNotificationSettings(completionHandler: {settings in
                MMKV.default()!.set((settings.authorizationStatus == .authorized), forKey: "canNotice")
            })
        })
    }
}
