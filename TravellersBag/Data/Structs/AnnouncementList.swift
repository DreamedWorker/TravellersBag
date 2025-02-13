//
//  AnnouncementList.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation

// MARK: - AnnouncementList
struct AnnouncementList: Codable {
    let picList: [JSONAny]
    let picTotal: Int
    let picAlertID: Int
    let alertID: Int
    let picAlert: Bool
    let picTypeList: [JSONAny]
    let t: String
    let staticSign: String
    let total: Int
    let list: [AnnouncementListList]
    let typeList: [TypeList]
    let banner: String
    let timezone: Int
    let alert: Bool
    
    // MARK: - AnnouncementListList
    struct AnnouncementListList: Codable, Hashable {
        let typeLabel: TypeLabel
        let list: [ListList]
        let typeID: Int
        
        enum CodingKeys: String, CodingKey {
            case typeLabel = "type_label"
            case list = "list"
            case typeID = "type_id"
        }
    }

    // MARK: - ListList
    struct ListList: Codable, Hashable {
        let tagEndTime: TagEndTime
        let tagStartTime: TagStartTime
        let endTime: String
        let typeLabel: TypeLabel
        let extraRemind: Int
        let remindVer: Int
        let hasContent: Bool
        let loginAlert: Int
        let banner: String
        let tagIconHover: String
        let remind: Int
        let annID: Int
        let startTime: String
        let alert: Int
        let title: String
        let content: String
        let tagLabel: TagLabel
        let tagIcon: String
        let subtitle: String
        let type: Int
        let lang: Lang
        
        enum CodingKeys: String, CodingKey {
            case tagEndTime = "tag_end_time"
            case tagStartTime = "tag_start_time"
            case endTime = "end_time"
            case typeLabel = "type_label"
            case extraRemind = "extra_remind"
            case remindVer = "remind_ver"
            case hasContent = "has_content"
            case loginAlert = "login_alert"
            case banner = "banner"
            case tagIconHover = "tag_icon_hover"
            case remind = "remind"
            case annID = "ann_id"
            case startTime = "start_time"
            case alert = "alert"
            case title = "title"
            case content = "content"
            case tagLabel = "tag_label"
            case tagIcon = "tag_icon"
            case subtitle = "subtitle"
            case type = "type"
            case lang = "lang"
        }
    }

    enum Lang: String, Codable, Hashable {
        case zhCN = "zh-cn"
    }

    enum TagEndTime: String, Codable, Hashable {
        case the20300102150405 = "2030-01-02 15:04:05"
    }

    enum TagLabel: String, Codable, Hashable {
        case 扭蛋 = "扭蛋"
        case 活动 = "活动"
        case 重要 = "重要"
    }

    enum TagStartTime: String, Codable, Hashable {
        case the20000102150405 = "2000-01-02 15:04:05"
    }

    enum TypeLabel: String, Codable, Hashable {
        case 活动公告 = "活动公告"
        case 游戏公告 = "游戏公告"
    }

    // MARK: - TypeList
    struct TypeList: Codable, Hashable {
        let name: String
        let id: Int
        let mi18NName: TypeLabel
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case id = "id"
            case mi18NName = "mi18n_name"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case picList = "pic_list"
        case picTotal = "pic_total"
        case picAlertID = "pic_alert_id"
        case alertID = "alert_id"
        case picAlert = "pic_alert"
        case picTypeList = "pic_type_list"
        case t = "t"
        case staticSign = "static_sign"
        case total = "total"
        case list = "list"
        case typeList = "type_list"
        case banner = "banner"
        case timezone = "timezone"
        case alert = "alert"
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public func hash(into hasher: inout Hasher) {
        // No-op
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String
    
    required init?(intValue: Int) {
        return nil
    }
    
    required init?(stringValue: String) {
        key = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {
    
    let value: Any
    
    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }
    
    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }
    
    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }
    
    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }
    
    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }
    
    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }
    
    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
