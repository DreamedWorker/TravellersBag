//
//  AlertMate.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import Foundation

struct AlertMate {
    var showIt: Bool = false
    var msg: String = ""
    
    init(showIt: Bool = false, msg: String = "") {
        self.showIt = showIt
        self.msg = msg
    }
    
    mutating func showAlert(msg data: String) {
        msg = data; showIt = true;
    }
}
