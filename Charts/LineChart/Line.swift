//
//  Line.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

public struct Line: View {
    @ObservedObject var data: ChartData
    @Binding var frame: CGRect
    @Binding var minDataValue: Double?
    @Binding var maxDataValue: Double?
    @Environment(\.colorScheme) var scheme: ColorScheme
    var gradient: GradientColor = GradientColor(start: Colors.GradientPurple, end: Colors.GradientNeonBlue)
    var fillGradient: Color
    var index:Int = 0
    let padding:CGFloat = 30
    var curvedLines: Bool = true
    var stepWidth: CGFloat {
        if data.points.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.points.count-1)
    }
    var stepHeight: CGFloat {
        var min: Double?
        var max: Double?
        let points = self.data.onlyPoints()
        if minDataValue != nil && maxDataValue != nil {
            min = minDataValue!
            max = maxDataValue!
        }else if let minPoint = points.min(), let maxPoint = points.max(), minPoint != maxPoint {
            min = minPoint
            max = maxPoint
        }else {
            return 0
        }
        if let min = min, let max = max, min != max {
            if (min <= 0){
                return (frame.size.height-padding) / CGFloat(max - min)
            }else{
                return (frame.size.height-padding) / CGFloat(max - min)
            }
        }
        return 0
    }
    var path: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: minDataValue) : Path.linePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight))
    }
    var closedPath: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadClosedCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: minDataValue) : Path.closedLinePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight))
    }
    var hideGradient: Bool
    
    public var body: some View {
        let unitPointTop: UnitPoint = scheme == .light ? .bottom : .top
        let unitPointBottom: UnitPoint = scheme == .light ? .top : .bottom
        
        ZStack {
            // Might be a better way to do this?
            if (self.hideGradient) {
                self.closedPath
                    .fill(Color.clear)
                    .rotationEffect(.degrees(180), anchor: .center)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                self.closedPath
                    .fill(LinearGradient(gradient: Gradient(colors: [fillGradient, Color(UIColor.systemBackground)]), startPoint: unitPointTop, endPoint: unitPointBottom))
                    .rotationEffect(.degrees(180), anchor: .center)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            self.path
                .trim(from: 0, to: 1.0)
                .stroke(fillGradient ,style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
    }
    
    func getClosestPointOnPath(touchLocation: CGPoint) -> CGPoint {
        let closest = self.path.point(to: touchLocation.x)
        return closest
    }
}

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader{ geometry in
            Line(data: ChartData(points: [12,-230,10,54]),
                 frame: .constant(geometry.frame(in: .local)),
                 minDataValue: .constant(nil),
                 maxDataValue: .constant(nil),
                 fillGradient: Color("Primary"),
                 hideGradient: true)
        }.frame(width: 120, height: 120)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .environment(\.colorScheme, ColorScheme.light)
    }
}
