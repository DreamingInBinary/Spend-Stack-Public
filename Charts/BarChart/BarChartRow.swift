//
//  ChartRow.swift
//  ChartView
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

public struct BarChartRow : View {
    var data: [Double]
    var gradient: GradientColor
    var maxValue: Double {
        guard let max = data.max() else {
            return 1
        }
        return max != 0 ? max : 1
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: (geometry.frame(in: .local).width-22)/CGFloat(self.data.count * 3)) {
                ForEach(0..<self.data.count, id: \.self) { i in
                    BarChartCell(value: self.normalizedValue(index: i),
                                 index: i,
                                 width: Float(geometry.frame(in: .local).width-12),
                                 numberOfDataPoints: self.data.count,
                                 gradient: self.gradient)
                    
                }
            }
            .padding([.leading, .trailing], 10)
        }
    }
    
    func normalizedValue(index: Int) -> Double {
        return Double(self.data[index])/Double(self.maxValue)
    }
}

struct ChartRow_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            BarChartRow(data: [0], gradient: GradientColor(start: Color.blue, end: Color.gray))
            BarChartRow(data: [8,23,54,32,12,37,7], gradient: GradientColor(start: Color.blue, end: Color.gray))
        }
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
