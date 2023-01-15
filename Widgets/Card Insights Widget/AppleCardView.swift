//
//  AppleCardView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 10/5/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

struct AppleCardView: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 22, height: 15, alignment: .center)
            .cornerRadius(2.0)
            .shadow(radius: 1)
            .overlay(
                Text("")
                    .font(.system(size: 4, weight: .regular, design: .default))
                    .padding([.top, .leading], 1),
                alignment: .topLeading)
            .overlay(
                Rectangle()
                    .fill(Color(UIColor.systemGray3))
                    .frame(width: 4, height: 3).cornerRadius(0.5)
                    .padding([.top, .trailing], 2),
                alignment: .topTrailing)
            .overlay(
                Text("Jane Doe")
                    .font(.system(size: 1, weight: .regular, design: .default))
                    .padding([.top, .leading], 1)
                    .padding(EdgeInsets(top: 0, leading: 1, bottom: 3, trailing: 0)),
                alignment: .bottomLeading)
    }
}

struct AppleCardView_Previews: PreviewProvider {
    static var previews: some View {
        AppleCardView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
