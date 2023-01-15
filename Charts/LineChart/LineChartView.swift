//
//  LineChartView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

public struct LineChartView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var data:ChartData
    public var title: String
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var lineGradient: Color
    public var showLabels: Bool
    @State private var touchLocation:CGPoint = .zero
    @State private var showIndicatorDot: Bool = false
    @State private var currentValue: Double = 2 {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    var frame = CGSize(width: 120, height: 120)
    private var rateValue: Int?
    private var formatter: NumberFormatter = NumberFormatter.userNumberFormatter()
    
    public init(data: [Double],
                title: String,
                style: ChartStyle = Styles.lineChartStyleOne,
                rateValue: Int? = 14,
                lineGradient: Color = Color("Primary"),
                showLabels: Bool = true) {
        
        self.data = ChartData(points: data.count == 1 ? [data.first!, data.first!] : data)
        self.title = title
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.rateValue = rateValue
        self.lineGradient = lineGradient
        self.showLabels = showLabels
    }
    
    public var body: some View {
        let amount = data.onlyPoints().isEmpty ? "--" : formatter.string(from: NSNumber(value: data.sumOfPoints())) ?? ""
        VStack(alignment: .leading){
            if (self.showLabels) {
                VStack(alignment: .leading, spacing: 8){
                    Text(self.title)
                        .font(.system(.subheadline, design: .rounded))
                        .bold()
                        .primaryColor()
                    Text(amount)
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.medium)
                        .primaryColor()
                        .offset(x: 0, y: -6.0)
                }.padding([.leading, .trailing, .top], 16)
            }
            if (data.onlyPoints().isEmpty) {
                Spacer()
                Text("No items found.")
                    .foregroundColor(primaryFont)
                    .font(.system(size: 10))
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                GeometryReader{ geometry in
                    Line(data: self.data,
                         frame: .constant(CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height + 36)),
                         minDataValue: .constant(nil),
                         maxDataValue: .constant(nil),
                         fillGradient: lineGradient,
                         hideGradient: false
                    )
                }
            }
        }
    }
    
    @discardableResult func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(round((toPoint.x)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentValue = points[index]
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Entertainment")
            .environment(\.colorScheme, .light)
            
            LineChartView(data: [], title: "Entertainment")
            .environment(\.colorScheme, .light)
        }.previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
