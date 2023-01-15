//
//  IconSquare.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/19/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

struct IconSquare: View {
    var systemIcon: String
    var defaultGradients: [Color] = [Color(UIColor.secondarySystemFill), Color(UIColor(red: 0.812, green: 0.851, blue: 0.890, alpha: 1.000))]
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: defaultGradients),
                    startPoint: UnitPoint(x: -1.0, y: -0.5),
                    endPoint: .bottomTrailing
                  ))
                .cornerRadius(4.0)
            Image(systemName: systemIcon)
                .resizable()
                .frame(width: 8, height: 8, alignment: .center)
                .foregroundColor(Color(UIColor.systemBackground))
        }.frame(width: 22, height: 22, alignment: .center)
    }
}

struct IconSquare_Previews: PreviewProvider {
    static var previews: some View {
        IconSquare(systemIcon: "trash"/*, defaultGradients: [.white, Color("Primary")]*/)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
