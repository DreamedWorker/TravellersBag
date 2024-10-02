//
//  AvatarModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import Foundation
import SwiftyJSON

class AvatarModel: ObservableObject {
    static let shared = AvatarModel()
    let avatarRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "avatars")
    let avatarOverview: URL
    let avatarDetail: URL
    
    @Published var showUI: Bool = false
    var overview: JSON? = nil
    var detail: JSON? = nil
    
    private init() {
        avatarOverview = avatarRoot.appending(component: "avatar_index.json")
        avatarDetail = avatarRoot.appending(components: "avatar_detail.json")
        if !FileManager.default.fileExists(atPath: avatarRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: avatarRoot, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: avatarOverview.toStringPath(), contents: nil)
            FileManager.default.createFile(atPath: avatarDetail.toStringPath(), contents: nil)
        } else {
            loadFile()
            if overview != nil && detail != nil {
                showUI = true
            }
        }
    }
    
    private func loadFile() {
        overview = try? JSON(data: FileHandler.shared.readUtf8String(path: avatarOverview.toStringPath()).data(using: .utf8)!)
        detail = try? JSON(data: FileHandler.shared.readUtf8String(path: avatarDetail.toStringPath()).data(using: .utf8)!)
    }
}
