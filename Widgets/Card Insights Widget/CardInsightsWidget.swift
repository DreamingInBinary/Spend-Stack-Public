//
//  CardInsightsWidget.swift
//  CardInsightsWidget
//
//  Created by Jordan Morgan on 10/1/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import WidgetKit
import SwiftUI

let demoData: [CardBarData] = [CardBarData(amount: 20.0, color: Color(UIColor.systemBlue)),
                                      CardBarData(amount: 10.0, color: Color(UIColor.systemRed)),
                                      CardBarData(amount: 30.0, color: Color(UIColor.systemGreen)),
                                      CardBarData(amount: 37.0, color: Color(UIColor.systemPink)),
                                      CardBarData(amount: 22.0, color: Color(UIColor.systemIndigo)),
                                      CardBarData(amount: 43.0, color: Color(UIColor.systemTeal))].sorted{ $0.amount < $1.amount }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CardChargeEntry {
        CardChargeEntry(date: Date(), cardData: demoData)
    }

    func getSnapshot(in context: Context, completion: @escaping (CardChargeEntry) -> ()) {
        let entry = CardChargeEntry(date: Date(), cardData: demoData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CardChargeEntry>) -> ()) {
        let dp = DataProvider()
        let totaler = Totaler()
        
        dp.fetchAppleCardChargesForThisMonth { data in
            var widgetData: [CardBarData] = []
            
            // Go through each tag and get a total, and its color
            data.keys.forEach {
                let items: [ListItem] = data[$0]!
                let totalArray = totaler.doubleTotal(forItems: items)
                let total = totaler.doubleSumOf(points: totalArray)
                let tagChartEntry = CardBarData(amount: total, color: tagColorNameToColor($0.color))
                widgetData.append(tagChartEntry)
            }
            
            let timeline = Timeline(entries: [CardChargeEntry(date: Date(), cardData: widgetData)], policy: .never)
            completion(timeline)
        }
    }
    
    private func tagColorNameToColor(_ tagColor:String) -> Color {
        guard tagColor != UserListTag.miscListTag.color else {
            return Color("Primary")
        }
        let components = String.tagNameToColor(tagColor)
        return Color(red: components.r, green: components.g, blue: components.b, opacity: 1.0)
    }
}

struct CardChargeEntry: TimelineEntry {
    let totaler = Totaler()
    let date: Date
    let cardData: [CardBarData]
    
    func totalAmount() -> String {
        return totaler.sumOf(points: cardData.map { $0.amount })
    }
}

// Ended up not using this for now, since it could only show last month's items at best since Apple Card export is manual.
struct CardInsightsWidgetEntryView : View {
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry

    var body: some View {
        let bgColor = scheme == .light ? Color.clear : Color(UIColor.tertiarySystemBackground)
        
        ZStack(alignment: .leading) {
            Color.clear
            if entry.cardData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    AppleCardView()
                    Text("ext.appleCard.noCharges".localized())
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .minimumScaleFactor(0.5)
                }.padding()
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text("ext.appleCard.total".localized())
                            .font(.system(size: 12, weight: .light, design: .default))
                        Spacer()
                        AppleCardView()
                    }.padding(.all, 0)
                    Text(entry.totalAmount())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.top, -10)
                    Spacer()
                    CardBarChartView(withData: entry.cardData)
                        .mask(ContainerRelativeShape())
                }.padding()
            }
        }.background(bgColor)
    }
}

@main
struct CardInsightsWidget: Widget {
    let kind: String = "CardInsightsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CardInsightsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Apple Card Insights")
        .description("Displays your Apple Card charges for this month.")
    }
}

struct CardInsightsWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardInsightsWidgetEntryView(entry: CardChargeEntry(date: Date(), cardData: demoData))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            CardInsightsWidgetEntryView(entry: CardChargeEntry(date: Date(), cardData: []))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            CardInsightsWidgetEntryView(entry: CardChargeEntry(date: Date(), cardData: demoData))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
            CardInsightsWidgetEntryView(entry: CardChargeEntry(date: Date(), cardData: []))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
        }
    }
}
