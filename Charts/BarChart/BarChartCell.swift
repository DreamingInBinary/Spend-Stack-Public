//
//  ChartCell.swift
//  ChartView
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.//

import SwiftUI
import WidgetKit

public struct BarChartCell : View {
    var value: Double
    var index: Int = 0
    var width: Float
    var numberOfDataPoints: Int
    var cellWidth: Double {
        return Double(width)/(Double(numberOfDataPoints) * 1.5)
    }
    var gradient: GradientColor
    
    @State var scaleValue: Double = 0
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(gradient: gradient.getGradient(), startPoint: .bottom, endPoint: .top))
        }
        .frame(width: CGFloat(self.cellWidth))
        .scaleEffect(CGSize(width: 1, height: self.value), anchor: .bottom)
        .offset(x: 0, y: 2.0)
        .clipped()
    }
}

struct ChartCell_Previews : PreviewProvider {
    static var previews: some View {
        BarChartCell(value: Double(0.75), width: 320, numberOfDataPoints: 12, gradient: GradientColor(start: Color.red, end: Color.blue))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
