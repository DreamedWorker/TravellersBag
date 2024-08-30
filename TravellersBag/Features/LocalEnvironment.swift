//
//  LocalEnvironment.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import Foundation
import MMKV

/// 存放一些全局使用的常量，如发起http请求时用到的请求头数据，当前活跃用户（可能）等。
/// 这是一个单例类。
class LocalEnvironment {
    // 单例声明
    private static var instance: LocalEnvironment?
    private var envKV: MMKV
    private init() { envKV = MMKV.default()! }
    static var shared: LocalEnvironment {
        if instance == nil { instance = LocalEnvironment() }
        return instance!
    }
    
    //公开的常量
    static var gameBizGenshin = "hk4e_cn"  //原神游戏ID
    static var xrpcVersion = "2.71.1" //米社版本
    static var clientType = "2" //类型：客户端
    static var hoyoUA = "Mozilla/5.0 (Linux; Android 12; M2101K9C Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/108.0.5359.128 Mobile Safari/537.36 miHoYoBBS/2.71.1" //米社请求UA
    static var commonUA = "Mozilla/5.0 (Linux; Android 12; M2101K9C Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/108.0.5359.128 Mobile Safari/537.36" //人机验证采用的UA
    static var iosHoyoUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 160 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.71.1"
    static let DEVICE_ID = "deviceID"
    static let BBS_DEVICE_ID = "bbsDeviceID"
    static let DEVICE_FP = "deviceFp"
    static let USE_KEY_CHAIN = "use_key_chain"
    static let KEY_CHAIN_NAME = "keychain_name"
    
    //方法区
    /// 检查本地环境是否完整 本方法应该只在应用启动时调用
    func checkEnvironment(){
        if envKV.string(forKey: "deviceID", defaultValue: "")! == "" {
            envKV.set(UUID().uuidString.lowercased(), forKey: "deviceID")
            print("生成了deviceID")
        }
        if envKV.string(forKey: "bbsDeviceID", defaultValue: "")! == "" {
            envKV.set(UUID().uuidString.lowercased(), forKey: "bbsDeviceID")
            print("生成了bbsDeviceID")
        }
        // if envKV.string(forKey: "deviceID40", defaultValue: "")! == "" {} 我们不需要这个ID，因为我们扫码时不采用app_id=4这个参数，而采用「未定事件簿」的
    }
    
    /// 向环境中插入值
    func setStringValue(key: String, value: String) {
        envKV.set(value, forKey: key)
    }
    
    /// 读取环境中的值
    func getEnvStringValue(key: String) -> String {
        return envKV.string(forKey: key)! // 因为这个函数只在完成初始化后才调用，因此可以放心用“!”
    }
    
    /// 用于生成设备指纹
    /// 只能应用于HomeContainer的onAppear上 在应用主逻辑开始之前加载
    func checkFigurePointer() async {
        if envKV.string(forKey: "deviceFp", defaultValue: "")! != "" {
            return
        } else {
            await updateDeviceFp()
        }
    }
    
    /// 据说设备指纹最好要定期更换，故封装之以供其他部分使用。非必要不得随意调用此方法！！！
    func updateDeviceFp() async {
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
            "bbs_device_id": LocalEnvironment.shared.getEnvStringValue(key: LocalEnvironment.BBS_DEVICE_ID),
            "device_fp": getLowerHexString(length: 13)
        ]
        var req = URLRequest(url: URL(string: ApiEndpoints.getFp)!)
        req.setIosUA()
        do {
            let result = try await req.receiveOrThrow(isPost: true, reqBody: try JSON(allDic).rawData())
            if result["code"].intValue == 200 {
                MMKV.default()!.set(result["device_fp"].stringValue, forKey: "deviceFp")
                print("使用了已经过验证的fp")
            } else { // 只要没异常的特别多，外层的代码都是0,所以内部再判断。
                throw NSError(domain: "application.init.device_fp", code: -200, userInfo: [
                    NSLocalizedDescriptionKey: "给出的参数有错误！"
                ])
            }
        } catch {
            MMKV.default()!.set(getLowerHexString(length: 13), forKey: "deviceFp")
            print("使用了野fp，\(error.localizedDescription)")
        }
    }
    
    // 私有区 不确定是否会公开它们
    private func getLowerHexString(length: Int) -> String {
        let base = "0123456789abcdef"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
            randomString += String(base[randomIndex])
        }
        return randomString
    }
    
    private func GetUpperAndNumberString(length: Int) -> String {
        let base = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
            randomString += String(base[randomIndex])
        }
        return randomString
    }
    
    private func GetLowerAndNumberString(length: Int) -> String {
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
