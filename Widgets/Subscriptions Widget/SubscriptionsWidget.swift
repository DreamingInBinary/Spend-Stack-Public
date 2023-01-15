//
//  SubscriptionsWidget.swift
//  SubscriptionsWidget
//
//  Created by Jordan Morgan on 8/7/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import WidgetKit
import SwiftUI

let monthlySub = MonthlySubscriptions(items: [ListItem(identifier:"", title: "Netflix", totalCost: "12.99", date: 1597850206, tagID: "", isChecked: false),
                                              ListItem(identifier:"", title: "Hulu", totalCost: "10.99", date: 1597850206, tagID: "", isChecked: false),
                                              ListItem(identifier:"", title: "Xbox Game Pass", totalCost: "9.99", date: 1597763806, tagID: "", isChecked: false),
                                              ListItem(identifier:"", title: "Gym", totalCost: "29.99", date: 1597850206, tagID: "", isChecked: false),
                                              ListItem(identifier:"", title: "Apple Arcade", totalCost: "4.99", date: 1597504606, tagID: "", isChecked: false)], currencyIdentifier: "")

// MARK: Widget Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RecurringCostEntry {
        RecurringCostEntry(date: Date(), monthRecurringCosts: monthlySub)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RecurringCostEntry) -> ()) {
        let entry = RecurringCostEntry(date: Date(), monthRecurringCosts: monthlySub)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let provider = DataProvider()
        provider.fetchMonthlySubscriptionsForThisMonth{ subs in
            let date = Date()
            let entries = [RecurringCostEntry(date: date, monthRecurringCosts: subs)]
            
            let updateTime = Calendar.current.date(byAdding: .minute, value: 15, to: date) ?? date
            let timeline = Timeline(entries: entries, policy: .after(updateTime))
            completion(timeline)
        }
    }
}

struct RecurringCostEntry: TimelineEntry {
    let date: Date
    var monthRecurringCosts: MonthlySubscriptions
}

// MARK: Widget Views
struct SubscriptionsWidgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family
    
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("Primary"), Color("Primary"), Color("SoftWhite")]),
                startPoint: .bottomTrailing,
                endPoint: UnitPoint(x: -1.0, y: -0.5)
            )
            VStack {
                HStack() {
                    Text(entry.monthRecurringCosts.thisMonth)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.01)
                    Image(systemName: "repeat")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 10, height: 10)
                        .offset(x: 0, y: -0.50)
                    Spacer()
                }
                HStack {
                    Text(entry.monthRecurringCosts.totalCost())
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                    Spacer()
                }.offset(x: 0, y: -8)
                Spacer()
                if (entry.monthRecurringCosts.dueNext().isEmpty) {
                    HStack {
                        Text(entry.monthRecurringCosts.nothingUpText)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                } else {
                    VStack {
                        if (entry.monthRecurringCosts.dueNext() != entry.monthRecurringCosts.nothingUpText) {
                            HStack {
                                Text("ext.widget.subs.nextUp")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        HStack {
                            Text(entry.monthRecurringCosts.dueNext())
                                .font(.system(.footnote, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .widgetURL(entry.monthRecurringCosts.createURLForNextUpItem())
    }
    
    // MARK: Widget Vending
    @main
    struct SubscriptionsWidget: Widget {
        let kind: String = "com.dreaminginbinary.spendstack.SubscriptionsWidget"
        
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: Provider()) { entry in
                SubscriptionsWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("ext.widget.subs.displayName")
            .description("ext.widget.subs.description")
            .supportedFamilies([.systemSmall])
        }
    }
    
    // MARK: Previews
    struct SubscriptionsWidget_Previews: PreviewProvider {
        static var previews: some View {
            let entry = RecurringCostEntry(date: Date(), monthRecurringCosts: monthlySub)
            SubscriptionsWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}
