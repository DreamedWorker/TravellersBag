//
//  WizardResourceData.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/25.
//

import Foundation

struct WizardResourceData {
    var jsonList: [String:String] = [:]
    var showJsonDownload: Bool = false
    var successfulAlert: Bool = false
    var fatalAlert: Bool = false
    var fatalMsg: String = ""
    var canGoNext: Bool = false
    
    var downloadState: Float = 0
    var downloadName: String = ""
    var showDownloadSheet: Bool = false
    
    init() {}
}
