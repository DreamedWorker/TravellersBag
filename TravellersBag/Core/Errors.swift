//
//  Errors.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/16.
//

import Foundation

/// 自定义的错误类型
enum TBErrors: Error {
    /// 索引文件时出错
    case indexFileError(String)
    
    //登录时可能的出错
    /// 二维码状态不是已确认
    case qrCodeStateError(String)
}
