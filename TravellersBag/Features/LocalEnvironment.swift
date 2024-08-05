//
//  LocalEnvironment.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import Foundation
import MMKV
import CryptoKit

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
        //TODO: 设备指纹的申请将在之后完成
    }
    
}
