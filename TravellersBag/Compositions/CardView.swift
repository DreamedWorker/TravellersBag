//
//  CardView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/9.
//

import SwiftUI

struct CardView<ChildView: View>: View {
    let content: () -> ChildView
    var body: some View {
        VStack(content: content)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
}
