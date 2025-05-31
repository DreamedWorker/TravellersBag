//
//  StaticHelper.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import Foundation
@preconcurrency import SwiftyJSON

class StaticHelper {
    static let avatars: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Avatar.json"))).arrayValue
    static let weapon: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Weapon.json"))).arrayValue
    static let reliquary: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Reliquary.json"))).arrayValue
    
    static func getIdByName(name: String) -> String {
        if (avatars?.contains(where: { $0["Name"].stringValue == name }) ?? false) {
            let result = avatars!.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else if (weapon?.contains(where: { $0["Name"].stringValue == name }) ?? false) {
            let result = weapon!.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else {
            return "0"
        }
    }
}
