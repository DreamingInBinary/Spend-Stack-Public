//
//  LineView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

public struct LineView: View {
    @ObservedObject var data: ChartData
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var showLegend = false
    @State private var dragLocation:CGPoint = .zero
    @State private var indicatorLocation:CGPoint = .zero
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity:Double = 0
    @State private var currentDataNumber: Double = 0
    @State private var hideHorizontalLines: Bool = false
    private var hideGradient: Bool
    
    public init(data: [Double], hideGradient: Bool = false) {
        self.data = ChartData(points: data)
        self.hideGradient = hideGradient
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading, spacing: 8) {
                ZStack{
                    GeometryReader{ reader in
                        Line(data: self.data,
                             frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 30, height: reader.frame(in: .local).height)),
                             minDataValue: .constant(nil),
                             maxDataValue: .constant(nil),
                             gradient: GradientColor(start: Colors.GradientPurple, end: Colors.GradientNeonBlue),
                             fillGradient: Color("Primary"),
                             hideGradient: hideGradient
                        )
                        .offset(x: 30, y: -20)
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: 240)
                    .offset(x: 0, y: 40 )
                }
                .frame(width: geometry.frame(in: .local).size.width, height: 240)
            }
        }
    }
    
    func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(floor((toPoint.x-15)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentDataNumber = points[index]
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineView(data: [8,23,54,32,12,37,7,23,43])
            
            LineView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188])
            
        }.previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

