//
//  DeviceEnv.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class DeviceEnv {
    nonisolated(unsafe) static let deviceFp = DeviceFingerprint(configKey: "deviceFingerprintLastCheck")
    
    /// 检查本地环境是否完整 本方法应该只在应用启动时调用
    static func checkEnvironment() {
        if ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: "") == "" {
            ConfigManager.setSettingsValue(key: ConfigKey.DEVICE_ID, value: UUID().uuidString.lowercased())
        }
        if ConfigManager.getSettingsValue(key: ConfigKey.BBS_DEVICE_ID, value: "") == "" {
            ConfigManager.setSettingsValue(key: ConfigKey.BBS_DEVICE_ID, value: UUID().uuidString.lowercased())
        }
    }
}

extension DeviceEnv {
    class DeviceFingerprint: AutocheckedKey {
        init(configKey: String) {
            super.init(configKey: configKey, dailyCheckedKey: false)
        }
        
        func getDeviceFp() async -> Result<String, Error> {
            do {
                if shouldFetchFromNetwork {
                    let body = try generateRequestBody()
                    let request = RequestBuilder.buildRequest(
                        method: .POST, host: Endpoints.PublicDataApi, path: "/device-fp/api/getFp", queryItems: [],
                        body: body
                    )
                    let fp = try await NetworkClient.simpleDataClient(request: request, type: DeviceFp.self)
                    if fp.data.code != 200 {
                        return .failure(NSError(domain: "DeviceFP", code: fp.data.code, userInfo: [NSLocalizedDescriptionKey: fp.data.msg]))
                    } else {
                        storeFetch(date: Date.now)
                        ConfigManager.setSettingsValue(key: ConfigKey.DEVICE_FP, value: fp.data.deviceFP)
                        return .success(fp.data.deviceFP)
                    }
                } else {
                    let localFp = ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_FP, value: "")
                    return .success((localFp != "") ? localFp : getLowerHexString(length: 13))
                }
            } catch {
                return .failure(NSError(domain: "DeviceFP", code: -1, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            }
        }
        
        private func generateRequestBody() throws -> Data {
            let device = getUpperAndNumberString(length: 12)
            let product = getUpperAndNumberString(length: 6)
            let oldFp = ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_FP, value: "")
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
                "packageVersion": "2.71.1",
                "networkType": "WiFi"
            ]
            let allDic: [String:Any] = [
                "device_id": getLowerHexString(length: 16),
                "seed_id": getLowerHexString(length: 16),
                "platform": "2",
                "seed_time": "\(String(Int(Date().timeIntervalSince1970)))000",
                "ext_fields": "\(String(data: try! JSONSerialization.data(withJSONObject: ext), encoding: .utf8)!)",
                "app_name": "bbs_cn",
                "bbs_device_id": ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: ""),
                "device_fp": (oldFp == "") ? getLowerHexString(length: 13) : oldFp
            ]
            return try JSONSerialization.data(withJSONObject: allDic)
        }
        
        private func getUpperAndNumberString(length: Int) -> String {
            let base = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            var randomString: String = ""
            
            for _ in 0..<length {
                let randomValue = arc4random_uniform(UInt32(base.count))
                let randomIndex = base.index(base.startIndex, offsetBy: Int(randomValue))
                randomString += String(base[randomIndex])
            }
            return randomString
        }
        
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
    }
}

extension DeviceEnv {
    private struct DeviceFp: Codable {
        let retcode: Int
        let message: String
        let data: DataClass
    }

    private struct DataClass: Codable {
        let deviceFP: String
        let code: Int
        let msg: String

        enum CodingKeys: String, CodingKey {
            case deviceFP = "device_fp"
            case code, msg
        }
    }
}
