//
//  ListInsightsWidget.swift
//  ListInsightsWidget
//
//  Created by Jordan Morgan on 8/27/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: Data Model
struct ListInsightsEntry: TimelineEntry {
    let date: Date
    let listInsight: ListInsight
    
    func generateMultiLineChartData() -> [MultiLineChartData] {
        var data: [MultiLineChartData] = []
        
        listInsight.tags.forEach {
            let tagCosts: [Double] = listInsight.totaler.itemCosts(forTag: $0, items: listInsight.items)
            if !tagCosts.isEmpty {
                let chartData: MultiLineChartData = MultiLineChartData(points: tagCosts, color: tagColorNameToColor($0.color))
                data.append(chartData)
            }
        }
        
        return data
    }
    
    func tagColorNameToColor(_ tagColor:String) -> Color {
        guard tagColor != UserListTag.miscListTag.color else {
            return Color("Primary")
        }
        let components = String.tagNameToColor(tagColor)
        return Color(red: components.r, green: components.g, blue: components.b, opacity: 1.0)
    }
}

let demoList = List(identifier: "", name: "Groceries", count: 23, total: "514.64", currencyIdentifier: Locale.current.identifier)
let demoTags = [UserListTag(identifier: "11", name: "Dairy", color: "appleBlue"),
                UserListTag(identifier: "12", name: "Fun", color: "appleOrange"),
                UserListTag(identifier: "13", name: "Meat", color: "appleRed")]
let demoItems = [ListItem(identifier: "12", title: "Milk", totalCost: "32.22", date: 1598899739, tagID: "11", isChecked: false),
                 ListItem(identifier: "13", title: "Cheese", totalCost: "12.22", date: 1598899739, tagID: "11", isChecked: true),
                 ListItem(identifier: "14", title: "Pizza", totalCost: "42.22", date: 1598899739, tagID: "11", isChecked: true),
                 ListItem(identifier: "15", title: "Butter", totalCost: "52.22", date: 1598899739, tagID: "11", isChecked: false),
                 ListItem(identifier: "1", title: "Milk", totalCost: "32.22", date: 1598899739, tagID: "12", isChecked: false),
                 ListItem(identifier: "134", title: "Cheese", totalCost: "92.22", date: 1598899739, tagID: "4335", isChecked: false),
                 ListItem(identifier: "234", title: "Pizza", totalCost: "10.22", date: 1598899739, tagID: "12", isChecked: true),
                 ListItem(identifier: "154", title: "Butter", totalCost: "32.22", date: 1598899739, tagID: "12", isChecked: true),
                 ListItem(identifier: "443", title: "Milk", totalCost: "22.22", date: 1598899739, tagID: "13", isChecked: false),
                 ListItem(identifier: "1344", title: "Cheese", totalCost: "32.22", date: 1598899739, tagID: "13", isChecked: false),
                 ListItem(identifier: "14444", title: "Pizza", totalCost: "72.22", date: 1598899739, tagID: "13", isChecked: true),
                 ListItem(identifier: "55444", title: "Butter", totalCost: "82.22", date: 1598899739, tagID: "13", isChecked: false)]
let demoEntry = ListInsightsEntry(date: Date(), listInsight: ListInsight(list: demoList, tags: demoTags, items: demoItems))

// MARK: Timeline Provider
struct Provider: IntentTimelineProvider {
    typealias Entry = ListInsightsEntry
    typealias Intent = DynamicListSearchIntent
    
    func placeholder(in context: Context) -> Entry {
        return demoEntry
    }
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        let handler = IntentHandler()
        let defaultList = handler.defaultList(for: configuration)
        
        let dp = DataProvider()
        let date = Date()
        guard let listID = defaultList?.identifier else {
            completion(demoEntry)
            return
        }
        
        dp.fetchListInsights(forListID: listID) { insight in
            let entry = ListInsightsEntry(date: date, listInsight: insight)
            completion(entry)
        }
    }
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let dp = DataProvider()
        let date = Date()
        guard let listID = configuration.list?.identifier else {
            completion(Timeline(entries: [demoEntry], policy: .never))
            return
        }
        
        let updateTime = Calendar.current.date(byAdding: .minute, value: 15, to: date) ?? date
        dp.fetchListInsights(forListID: listID) { insight in
            let entries = [ListInsightsEntry(date: date, listInsight: insight)]
            let timeline = Timeline(entries: entries, policy: .after(updateTime))
            completion(timeline)
        }
    }
}

// MARK: Data Model
struct ListInsightsWidgetSmallView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(entry.listInsight.list.name)
                    .font(.system(.subheadline, design: .rounded))
                    .primaryColor()
                    .minimumScaleFactor(0.2)
                Text(entry.listInsight.getTotalFor(amountType: .all))
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.semibold)
                    .primaryColor()
                    .minimumScaleFactor(0.2)
            }
            .padding()
            MultiLineChartView(multiChartData: entry.generateMultiLineChartData())
        }
    }
}

struct TotalRowView: View {
    @Environment(\.colorScheme) var scheme
    let glyphSize = CGFloat(12.0)
    let glyphColor = Color("Primary")
    var imageName: String
    var totalName: String
    var totalAmount: String
    
    var body: some View {
        let bgColor = Color(scheme == .light ? UIColor.secondarySystemBackground : UIColor.tertiarySystemFill)
        HStack(spacing:6.0) {
            Image(systemName: imageName)
                .resizable()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundColor(glyphColor)
            Text(totalName)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .primaryColor()
                .minimumScaleFactor(0.5)
            Text(totalAmount)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .primaryColor()
                .lineLimit(1)
                .padding(.leading, -4.0)
            Spacer()
        }
        .padding(.all, 8)
        .background(bgColor.cornerRadius(4.0))
    }
}

struct ListInsightsWidgetMediumView : View {
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry
    
    var body: some View {
        let bgColor = Color(scheme == .light ? UIColor.secondarySystemBackground : UIColor.tertiarySystemFill)
        
        HStack {
            VStack(alignment: .leading) {
                Text(entry.listInsight.list.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .primaryColor()
                Spacer()
                TotalRowView(imageName: "circle.fill", totalName: "ext.widget.lists.unchecked".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .unchecked))
                Spacer()
                TotalRowView(imageName: "checkmark.circle.fill", totalName: "ext.widget.lists.checked".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .checked))
                Spacer()
                TotalRowView(imageName: "equal.circle.fill", totalName: "ext.widget.lists.all".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .all))
            }
            .padding([.leading, .top, .bottom], 16)
            .frame(minWidth: 0, maxWidth: 160)
            ZStack {
                ContainerRelativeShape()
                    .fill(bgColor)
                VStack(alignment: .leading) {
                    Text("ext.widget.lists.tags")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .primaryColor()
                        .padding([.leading, .trailing, .top], 8)
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .foregroundColor(Color.green)
                            .frame(width: 12, height: 12)
                            .padding(.trailing, -4.0)
                        Text(entry.listInsight.highestTagAmount())
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .primaryColor()
                        Image(systemName: "arrow.down.circle.fill")
                            .resizable()
                            .foregroundColor(Color.blue)
                            .frame(width: 12, height: 12)
                            .padding(.trailing, -4.0)
                        Text(entry.listInsight.lowestTagAmount())
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .primaryColor()
                    }
                    .padding([.leading, .trailing], 8)
                    .offset(x: 0, y: -4.0)
                    MultiLineChartView(multiChartData: entry.generateMultiLineChartData())
                        .offset(x: 0, y: -8.0)
                }
            }
            .padding(EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 16))
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}

struct TotalRowGridView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.listInsight.list.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .primaryColor()
            HStack {
                TotalRowView(imageName: "circle.fill", totalName: "ext.widget.lists.unchecked".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .unchecked))
                Spacer()
                TotalRowView(imageName: "checkmark.circle.fill", totalName: "ext.widget.lists.checked".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .checked))
            }
            HStack {
                TotalRowView(imageName: "equal.circle.fill", totalName: "ext.widget.lists.all".localized(), totalAmount: entry.listInsight.getTotalFor(amountType: .all))
                Spacer()
                TotalRowView(imageName: "divide.circle.fill", totalName: "ext.widget.lists.average".localized(), totalAmount: entry.listInsight.averageCostForItems())
            }
            HStack {
                TotalRowView(imageName: "arrow.up.circle.fill", totalName: "ext.widget.lists.highest".localized(), totalAmount: entry.listInsight.highestItemAmount())
                Spacer()
                TotalRowView(imageName: "arrow.down.circle.fill", totalName: "ext.widget.lists.lowest".localized(), totalAmount: entry.listInsight.lowestItemAmount())
            }
        }
    }
}

struct ListInsightsWidgetLargeView : View {
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry
    
    var body: some View {
        let bgColor = Color(scheme == .light ? UIColor.secondarySystemBackground : UIColor.tertiarySystemFill)
        
        VStack(alignment: .leading) {
            TotalRowGridView(entry: entry)
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            HStack {
                ZStack {
                    ContainerRelativeShape()
                        .fill(bgColor)
                    VStack(alignment: .leading) {
                        Text("ext.widget.lists.tags")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .primaryColor()
                            .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .foregroundColor(Color.green)
                                .frame(width: 12, height: 12)
                                .padding(.trailing, -4.0)
                            Text(entry.listInsight.highestTagAmount())
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .primaryColor()
                            Image(systemName: "arrow.down.circle.fill")
                                .resizable()
                                .foregroundColor(Color.blue)
                                .frame(width: 12, height: 12)
                                .padding(.trailing, -4.0)
                            Text(entry.listInsight.lowestTagAmount())
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .primaryColor()
                        }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                        MultiLineChartView(multiChartData: entry.generateMultiLineChartData())
                            .offset(x: 0, y: -8.0)
                    }
                }
                ZStack {
                    ContainerRelativeShape()
                        .fill(bgColor)
                    VStack(alignment: .leading) {
                        Text("ext.widget.lists.items")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .primaryColor()
                            .padding(EdgeInsets(top: 16, leading: 8, bottom: 0, trailing: 8))
                            .frame(height: 14)
                        BarChartRow(data: entry.listInsight.doubleTotalForItems(), gradient: GradientColor(start: Color("Primary"), end: .accentColor))
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
    }
}

struct ListInsightsWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry
    
    @ViewBuilder
    var body: some View {
        let bgColor = scheme == .light ? Color.clear : Color(UIColor.tertiarySystemBackground)
        
        switch family {
        case .systemSmall:
            ListInsightsWidgetSmallView(entry: entry)
                .background(bgColor)
                .widgetURL(entry.listInsight.createURLForList())
        case .systemMedium:
            ListInsightsWidgetMediumView(entry: entry)
                .background(bgColor)
                .widgetURL(entry.listInsight.createURLForList())
        case .systemLarge:
            ListInsightsWidgetLargeView(entry: entry)
                .background(bgColor)
                .widgetURL(entry.listInsight.createURLForList())
        default:
            ListInsightsWidgetSmallView(entry: entry)
                .background(bgColor)
                .widgetURL(entry.listInsight.createURLForList())
        }
    }
    
    // MARK: Widget Entry Point
    @main
    struct ListInsightsWidget: Widget {
        let kind: String = "ListInsightsWidget"
        
        var body: some WidgetConfiguration {
            IntentConfiguration(kind: kind, intent: DynamicListSearchIntent.self, provider: Provider()) { entry in
                ListInsightsWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("ext.widget.lists.displayName")
            .description("ext.widget.lists.description")
        }
    }
    
    // MARK: Previews
    struct ListInsightsWidget_Previews: PreviewProvider {
        static var previews: some View {
            let size: WidgetFamily = .systemLarge
            
            Group {
                ListInsightsWidgetEntryView(entry: demoEntry)
                    .previewContext(WidgetPreviewContext(family: size))
                ListInsightsWidgetEntryView(entry: demoEntry)
                    .previewContext(WidgetPreviewContext(family: size))
                    .environment(\.colorScheme, .dark)
            }
        }
    }
}
