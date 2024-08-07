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
    static var hoyoUA = "Mozilla/5.0 (Linux; Android 9; M2101K9C Build/TKQ1.220829.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/108.0.5359.128 Mobile Safari/537.36 miHoYoBBS/2.71.1" //米社请求UA
    static let DEVICE_ID = "deviceID"
    static let BBS_DEVICE_ID = "bbsDeviceID"
    static let DEVICE_FP = "deviceFp"
    
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
    
    /// 用于生成设备指纹
    /// 只能应用于HomeContainer的onAppear上 在应用主逻辑开始之前加载
    func checkFigurePointer() async {
        if envKV.string(forKey: "deviceFp", defaultValue: "")! != "" {
            return
        } else {
            var req = URLRequest(url: URL(string: ApiEndpoints.getFp)!)
            req.setValue("public-data-api.mihoyo.com", forHTTPHeaderField: "Host")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("okhttp/4.9.3", forHTTPHeaderField: "User-Agent")
            let result = await req.receiveData(
                session: httpSession(),
                isPost: true,
                reqBody: try! JSONSerialization.data(withJSONObject: [
                    "device_id": MMKV.default()!.string(forKey: "deviceID")!,
                    "seed_id": UUID().uuidString.lowercased(),
                    "seed_time": String(NSDate().timeIntervalSince1970),
                    "platform": "2",
                    "device_fp": randomAlphanumericString(length: 13),
                    "app_name": "bbs_cn",
                    "ext_fields": """
{"proxyStatus":0,"isRoot":0,"romCapacity":"512","deviceName":"sdk_gphone64_arm64","productName":"sdk_gphone64_arm64","romRemain":"457","hostname":"abfarm769","screenSize":"1080x2274","isTablet":0,"aaid":"","model":"sdk_gphone64_arm64","brand":"google","hardware":"ranchu","deviceType":"emulator64_arm64","devId":"REL","serialNumber":"unknown","sdCapacity":5951,"buildTime":"1663050617000","buildUser":"android-build","simState":5,"ramRemain":"5198","appUpdateTimeDiff":1722778273952,"deviceInfo":"google sdk_gphone64_arm64 emulator64_arm64:12 SE1A.220630.001.A1 9056438:userdebug dev-keys","vaid":"","buildType":"userdebug","sdkVersion":"31","ui_mode":"UI_MODE_TYPE_NORMAL","isMockLocation":0,"cpuType":"arm64-v8a","isAirMode":0,"ringMode":2,"chargeStatus":1,"manufacturer":"Google","emulatorStatus":0,"appMemory":"512","osVersion":"12","vendor":"unknown","accelerometer":"0.0x9.776321x0.812345","sdRemain":5055,"buildTags":"dev-keys","packageName":"com.mihoyo.hyperion","networkType":"4G","oaid":"","debugStatus":1,"ramCapacity":"5951","magnetometer":"0.0x9.875x-47.75","display":"sdk_gphone64_arm64-userdebug 12 SE1A.220630.001.A1 9056438 dev-keys","appInstallTimeDiff":1722778273952,"packageVersion":"2.20.2","gyroscope":"0.0x0.0x0.0","batteryStatus":100,"hasKeyboard":0,"board":"goldfish_arm64"}
""",
                    "bbs_device_id": MMKV.default()!.string(forKey: "bbsDeviceID")!
                ])
            )
            if result.evtState {
                if (result.data as! String).contains("OK") {
                    do {
                        let json = try JSON(data: (result.data as! String).data(using: .utf8)!)
                        MMKV.default()!.set(json["data"]["device_fp"].stringValue, forKey: "deviceFp")
                        print("使用了已经过验证的fp")
                    } catch {
                        MMKV.default()!.set(randomAlphanumericString(length: 13), forKey: "deviceFp")
                        print("使用了野fp")
                    }
                } else {
                    MMKV.default()!.set(randomAlphanumericString(length: 13), forKey: "deviceFp")
                    print("使用了野fp")
                }
            }
        }
    }
    
    /// 生成随机fp
    private func randomAlphanumericString(length: Int) -> String {
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
