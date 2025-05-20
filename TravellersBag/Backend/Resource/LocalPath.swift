//
//  LocalPath.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class LocalPath {
    static func getPath(prefix: URL, relative: String) -> URL {
        let prefixPath = prefix.path(percentEncoded: false)
        return URL(filePath: prefixPath + "/" + relative)
    }
}
