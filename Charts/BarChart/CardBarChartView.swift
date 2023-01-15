//
//  CardBarChartView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 10/1/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import SwiftUI
import WidgetKit

struct CardBarData : Identifiable {
    let id = UUID().uuidString
    let amount: Double
    let color: Color
}

struct CardBarChartView: View {
    @Environment(\.colorScheme) var scheme
    let data: [CardBarData]
    let max: Double
    let middle: String
    let totaler = Totaler()
    
    init(withData  data:[CardBarData]) {
        self.data = data.sorted { $0.amount < $1.amount }
        self.max = data.map{ $0.amount }.max() ?? 0.0
        self.middle = totaler.formattedMiddleAverage(fromPoints: data.map { $0.amount })
    }
    
    var body: some View {
        let bgColor = scheme == .light ? Color.clear : Color(UIColor.tertiarySystemBackground)
        
        ZStack {
            VStack(alignment: .leading) {
                Spacer()
                Text(middle)
                    .font(.system(size: 8, weight: .medium, design: .default))
                    .lightPrimaryColor()
                    .minimumScaleFactor(0.5)
                    .padding([.bottom], 14)
                DashedLine()
                    .stroke(Color("LightPrimary"), style: StrokeStyle(lineWidth: 1, dash: [7]))
                    .frame(height: 1)
                    .offset(x: 0, y: -16.0)
                Spacer()
            }
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(self.data) { bar in
                        Rectangle()
                            .fill(bar.color)
                            .frame(height: CGFloat(bar.amount) / CGFloat(self.max) * geo.size.height)
                            .cornerRadius(3, corners: [.topLeft, .topRight])
                    }.offset(x: 0, y: 4.0)
                }
            }
        }.background(bgColor)
    }
}

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct CardBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { scheme in
            CardBarChartView(withData: [10.0,20.0,40.0,44.0,63.1].map{ CardBarData(amount: $0, color: Color(UIColor.systemBlue)) })
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, scheme)
        }
    }
}
