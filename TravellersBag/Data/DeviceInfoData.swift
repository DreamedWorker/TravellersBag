//
//  DeviceInfoData.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/28.
//

import Foundation

struct DeviceInfoData {
    var deviceId: String = ""
    var bbsDeviceId: String = ""
    var deviceFp: String = ""
    var deviceFpInfo: DeviceFpInfo = DeviceFpInfo()
    
    init() {}
    
    struct DeviceFpInfo {
        var showErrAlert: Bool = false
        var errMsg: String = ""
        
        init() {}
        
        mutating func makeAlert(msg: String) {
            errMsg = msg
            showErrAlert = true
        }
    }
}
