//
//  ModifiedConfigHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/24.
//

import Foundation
import SwiftyJSON

extension UserDefaults {
    public static let preferences = UserDefaults.init(suiteName: "preferences")!
    
    /// 从全局K-V存储中获取值
    static func configGetConfig<T>(forKey key: String, def defaultKey: T) -> T {
        if let result = UserDefaults.preferences.object(forKey: key) as? T {
            return result
        } else {
            return defaultKey
        }
    }
    
    /// 将值插入全局K-V中
    static func configSetValue<T>(key forKey: String, data value: T) {
        UserDefaults.preferences.set(value, forKey: forKey)
    }
}

/// 系统自带存储
extension UserDefaults {
    static func langGetCurrentLanguage() -> String {
        return (UserDefaults.standard.object(forKey: "AppleLanguages") as! NSArray).firstObject as! String
    }
    
    static func langWriteNeoLanguage(langType: String) {
        switch langType {
        case "chs":
            UserDefaults.standard.set(["zh-Hans-CN"], forKey: "AppleLanguages")
            break
        case "en":
            UserDefaults.standard.set([langType], forKey: "AppleLanguages")
            break
        case "def":
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            break
        default:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            break
        }
        UserDefaults.standard.synchronize()
    }
}

/// 一些约定的访问key
struct TBConfigKeys {
    static var gameBizGenshin = "hk4e_cn"  //原神游戏ID
    static var xrpcVersion = "2.71.1" //米社版本
    static var clientType = "2" //类型：客户端
    static var hoyoUA = "Mozilla/5.0 (Linux; Android 12; M2101K9C Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/108.0.5359.128 Mobile Safari/537.36 miHoYoBBS/2.71.1" //米社请求UA
    static var iosHoyoUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 160 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.71.1"
    static let DEVICE_ID = "deviceID"
    static let BBS_DEVICE_ID = "bbsDeviceID"
    static let DEVICE_FP = "deviceFp"
    static let USE_KEY_CHAIN = "use_key_chain"
    static let KEY_CHAIN_NAME = "keychain_name"
}

class ModifiedConfigHelper {
    /// 检查本地环境是否完整 本方法应该只在应用启动时调用
    static func checkEnvironment(){
        if UserDefaults.configGetConfig(forKey: TBConfigKeys.DEVICE_ID, def: "") == "" {
            UserDefaults.configSetValue(key: TBConfigKeys.DEVICE_ID, data: UUID().uuidString.lowercased())
        }
        if UserDefaults.configGetConfig(forKey: TBConfigKeys.BBS_DEVICE_ID, def: "") == "" {
            UserDefaults.configSetValue(key: TBConfigKeys.BBS_DEVICE_ID, data: UUID().uuidString.lowercased())
        }
    }
    
    /// 据说设备指纹最好要定期更换，故封装之以供其他部分使用。非必要不得随意调用此方法！！！
    static func updateDeviceFp() async throws -> String {
        let device = GetUpperAndNumberString(length: 12)
        let product = GetUpperAndNumberString(length: 6)
        let ext: [String:Any] = [
            "oaid": "",
            "vaid": "",
            "aaid": "",
            "serialNumber": "unknown",
            "board": "taro",
            "brand": "XiaoMi",
            "hardware": "qcom",
            "cpuType": "arm64-v8a",
            "deviceType": "OP5913L1",
            "display": "\(product)_13.1.0.181(CN01)",
            "hostname": "dg02-pool03-kvm87",
            "manufacturer": "XiaoMi",
            "productName": "\(product)",
            "model": "\(device)",
            "deviceInfo": "XiaoMi/\(product)/OP5913L1:13/SKQ1.221119.001/T.118e6c7-5aa23-73911:user/release-keys",
            "sdkVersion": "34",
            "osVersion": "14",
            "devId": "REL",
            "buildTags": "release-keys",
            "buildType": "user",
            "buildUser": "android-build",
            "buildTime": "1693626947000",
            "screenSize": "1440x2905",
            "vendor": "unknown",
            "romCapacity": "512",
            "romRemain": "512",
            "ramCapacity": "469679",
            "ramRemain": "239814",
            "appMemory": "512",
            "accelerometer": "1.4883357x7.1712894x6.2847486",
            "gyroscope": "0.030226856x0.014647375x0.010652636",
            "magnetometer": "20.081251x-27.487501x2.1937501",
            "isRoot": 0,
            "debugStatus": 1,
            "proxyStatus": 0,
            "emulatorStatus": 0,
            "isTablet": 0,
            "simState": 5,
            "ui_mode": "UI_MODE_TYPE_NORMAL",
            "sdCapacity": "512215",
            "sdRemain": "239600",
            "hasKeyboard": 0,
            "isMockLocation": 0,
            "ringMode": 2,
            "isAirMode": 0,
            "batteryStatus": 100,
            "chargeStatus": 1,
            "deviceName": "\(device)",
            "appInstallTimeDiff": 1688455751496,
            "appUpdateTimeDiff": 1702604034482,
            "packageName": "com.mihoyo.hyperion",
            "packageVersion": "2.20.1",
            "networkType": "WiFi"
        ]
        let allDic: [String:Any] = [
            "device_id": getLowerHexString(length: 16),
            "seed_id": getLowerHexString(length: 16),
            "platform": "2",
            "seed_time": "\(String(Int(Date().timeIntervalSince1970)))000", //我就说怎么这个方法一直说参数有误，这个**
            "ext_fields": "\(String(data: try! JSONSerialization.data(withJSONObject: ext), encoding: .utf8)!)",
            "app_name": "bbs_cn",
            "bbs_device_id": UserDefaults.configGetConfig(forKey: TBConfigKeys.BBS_DEVICE_ID, def: ""),
            "device_fp": getLowerHexString(length: 13)
        ]
        var req = URLRequest(url: URL(string: ApiEndpoints.getFp)!)
        req.setIosUA()
        let result = try await req.receiveOrThrow(isPost: true, reqBody: JSON(allDic).rawData())
        if result["code"].intValue == 200 {
            return result["device_fp"].stringValue
        } else {
            throw NSError(domain: "icu.bluedream.TravellersBag", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法获取设备指纹：参数有误。"])
        }
    }
    
    //MARK: PRIVATE METHODS
    // 私有区 不确定是否会公开它们
    static func getLowerHexString(length: Int) -> String {
        let base = "0123456789abcdef"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
            randomString += String(base[randomIndex])
        }
        return randomString
    }
    
    static private func GetUpperAndNumberString(length: Int) -> String {
        let base = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
            randomString += String(base[randomIndex])
        }
        return randomString
    }
    
    static private func GetLowerAndNumberString(length: Int) -> String {
        let base = "0123456789abcdefghijklmnopqrstuvwxyz"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
            randomString += String(base[randomIndex])
        }
        return randomString
    }
}
