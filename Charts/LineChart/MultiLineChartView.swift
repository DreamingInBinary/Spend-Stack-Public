//
//  MultiLineChartView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

public struct MultiLineChartView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var data:[MultiLineChartData]
    var globalMin:Double {
        if let min = data.flatMap({$0.onlyPoints()}).min() {
            return min
        }
        return 0
    }
    var globalMax:Double {
        if let max = data.flatMap({$0.onlyPoints()}).max() {
            return max
        }
        return 0
    }
    private var rateValue: Int?
    
    public init(data: [([Double], GradientColor)]) {
        self.data = data.map({ MultiLineChartData(points: $0.0, gradient: $0.1)})
    }
    
    public init(multiChartData: [MultiLineChartData]) {
        self.data = multiChartData
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            ZStack{
                ForEach(0..<self.data.count) { i in
                    Line(data: self.data[i],
                         frame:.constant(geometry.frame(in: .local)),
                         minDataValue: .constant(self.globalMin),
                         maxDataValue: .constant(self.globalMax),
                         gradient: self.data[i].getGradient(),
                         fillGradient: self.data[i].fill,
                         index: i,
                         hideGradient: true)
                }
            }
        }
    }
}

struct MultiWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MultiLineChartView(data: [([20.0,90,0,40.0],
                                   GradientColors.orange),
                                  ([20.0,90,0,40.0].reversed(),
                                                             GradientColors.orange)])
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
