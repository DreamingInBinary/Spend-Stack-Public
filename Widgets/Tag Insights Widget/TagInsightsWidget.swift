//
//  TagInsightsWidget.swift
//  TagInsights
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//


import WidgetKit
import SwiftUI

let snapshotGraphColorName = "Primary"
let snapshotGraphColor = Color("Primary")
let demoTagInsightEntry = TagInsightsEntry(date: Date(),
                                           points: [200.2,142.1,166.4, 133.4,122.3,13.4,233.4,193.4,113.4,100.4,64.4,83.4,173.4,100.4,77.4],
                                           name: "Groceries",
                                           color: snapshotGraphColorName,
                                           range: .month)
let demoEmptyTagInsightEntry = TagInsightsEntry(date: Date(),
                                                points: [],
                                                name: "Groceries",
                                                color: snapshotGraphColorName,
                                                range: .month)

// MARK: Intent Timeline Provider
struct Provider: IntentTimelineProvider {
    typealias Entry = TagInsightsEntry
    typealias Intent = DynamicTagSearchIntent
    
    func placeholder(in context: Context) -> Entry {
        return demoTagInsightEntry
    }
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        let handler = IntentHandler()
        let tag = handler.defaultTag(for: configuration)
        
        guard let defaultTag = tag else {
            completion(demoTagInsightEntry)
            return
        }
        
        let dp = DataProvider()
        let date = Date()
        let range = intentTimeRangeToTagTimeTange(configuration.timeRange)
        let tagID = defaultTag.identifier ?? ""
        let tagName = defaultTag.displayString
        
        dp.fetchItemFor(tagID: tagID, range: range) { (items:[ListItem], tagColor:String) in
            let filteredItemsForRange = filterItems(forTimeRange: range, items: items)
            let dataPoints: [Double] = filteredItemsForRange.map{ $0.costToDouble() }
            
            let entry = TagInsightsEntry(date: date,
                                         points: dataPoints,
                                         name: tagName,
                                         color: tagColor,
                                         range: range)
            
            completion(entry)
        }
    }
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let dp = DataProvider()
        let date = Date()
        let range = intentTimeRangeToTagTimeTange(configuration.timeRange)
        let tagID = configuration.tag?.identifier ?? ""
        let tagName = configuration.tag?.displayString ?? ""
        
        dp.fetchItemFor(tagID: tagID, range: range) { (items:[ListItem], tagColor:String) in
            let filteredItemsForRange = filterItems(forTimeRange: range, items: items)
            let dataPoints: [Double] = filteredItemsForRange.map{ $0.costToDouble() }
            
            let entries: [TagInsightsEntry] = [TagInsightsEntry(date: date,
                                                                points: dataPoints,
                                                                name: tagName,
                                                                color: tagColor,
                                                                range: range)]
            
            let updateTime = Calendar.current.date(byAdding: .minute, value: 15, to: date) ?? date
            let timeline = Timeline(entries: entries, policy: .after(updateTime))
            completion(timeline)
        }
    }
    
    // MARK: Intent data type translators
    private func intentTimeRangeToTagTimeTange(_ intentRange:TagInsightCompareRange) -> DataProvider.TagTimeRange {
        switch intentRange {
        case .unknown:
            return .year
        case .week:
            return .week
        case .month:
            return .month
        case .year:
            return .year
        }
    }
    
    private func filterItems(forTimeRange range:DataProvider.TagTimeRange, items:[ListItem]) -> [ListItem] {
        var sortStrat:Calendar.Component
        
        switch range {
        case .week:
            sortStrat = .weekOfYear
        case .month:
            sortStrat = .month
        case .year:
            sortStrat = .year
        }
        
        let sortValue = Date().get(sortStrat)
        
        return items.filter { Date(timeIntervalSince1970: $0.date ?? 0.0).get(sortStrat) == sortValue }
    }
}

// MARK: Data Model
struct TagInsightsEntry: TimelineEntry {
    let date: Date
    let points: [Double]
    let name: String
    let color: String
    let range: DataProvider.TagTimeRange
    
    func tagColorNameToColor(_ tagColor:String) -> Color {
        guard tagColor != snapshotGraphColorName else { return snapshotGraphColor }
        guard tagColor != UserListTag.miscListTag.color else {
            return Color("Primary")
        }
        let components = String.tagNameToColor(tagColor)
        return Color(red: components.r, green: components.g, blue: components.b, opacity: 1.0)
    }
    
    func rangeAsText() -> String {
        switch range {
        case .week:
            return "ext.widget.tags.rangeWeek".localized()
        case .month:
            return String(format: NSLocalizedString("ext.widget.tags.over", comment: ""), Date().month())
        case .year:
            return String(format: NSLocalizedString("ext.widget.tags.over", comment: ""), Date().year())
        }
    }
}

// MARK: Views
struct TagInsightEntrySmallView: View {
    var entry: Provider.Entry
    
    var body: some View {
        let lineGradient = entry.tagColorNameToColor(entry.color)
        LineChartView(data: entry.points, title: entry.name, lineGradient: lineGradient)
    }
}

struct TagInsightEntryMediumView: View {
    var entry: Provider.Entry
    let totaler = Totaler()
    
    var body: some View {
        let lineGradient = entry.tagColorNameToColor(entry.color)
        let isEmpty = entry.points.isEmpty
        
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 6.0) {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(entry.name)
                            .font(.system(.subheadline, design: .rounded))
                            .bold()
                            .primaryColor()
                            Text(isEmpty ? "" : "  \(totaler.sumOf(points: entry.points)) \(entry.rangeAsText())")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.medium)
                            .primaryColor()
                    }
                    HStack(spacing: 12.0) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .foregroundColor(Color.green)
                                .frame(width: 12, height: 12)
                                .padding(.trailing, -4.0)
                            Text(isEmpty ? "--" :totaler.highestPoint(fromPoints: entry.points))
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .primaryColor()
                        }
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .resizable()
                                .foregroundColor(Color.blue)
                                .frame(width: 12, height: 12)
                                .padding(.trailing, -4.0)
                            Text(isEmpty ? "--" : totaler.lowestPoint(fromPoints: entry.points))
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .primaryColor()
                        }
                    }
                }
                Spacer()
            }.padding()
            Spacer()
            LineChartView(data: entry.points, title: entry.name, lineGradient: lineGradient, showLabels: false)
        }
    }
}

// MARK: Views
struct TagInsightEntryLargeView: View {
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry
    let totaler = Totaler()
    
    struct DataView: View {
        @Environment(\.colorScheme) var scheme
        var image: String
        var imageBackground: Color
        var dataKey: String
        var dataValue: String
        
        var body: some View {
            let bgColor = Color(scheme == .light ? UIColor.secondarySystemBackground : UIColor.tertiarySystemFill)
            
            ZStack {
                ContainerRelativeShape()
                    .fill(bgColor)
                VStack {
                    HStack {
                        Image(systemName: image)
                            .resizable()
                            .foregroundColor(imageBackground)
                            .frame(width: 12, height: 12)
                            .padding(.trailing, -4.0)
                        Text(dataKey)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .primaryColor()
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text(dataValue)
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.semibold)
                            .primaryColor()
                    }
                }
                .padding(.all, 8)
            }
        }
    }
    
    var body: some View {
        let lineGradient = entry.tagColorNameToColor(entry.color)
        let isEmpty = entry.points.isEmpty

        VStack(alignment: .leading) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(entry.name)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .primaryColor()
                Text(String(format: NSLocalizedString("ext.widget.tags.spending", comment: ""), entry.rangeAsText()))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .primaryColor()
                Spacer()
            }
            .minimumScaleFactor(0.4)
            .padding(EdgeInsets(top: 32, leading: 16, bottom: -8.0, trailing: 16))
            VStack {
                HStack {
                    DataView(image: "arrow.up.circle.fill", imageBackground: .green, dataKey: "ext.widget.tags.highest".localized(), dataValue: isEmpty ? "--" : totaler.highestPoint(fromPoints: entry.points))
                    DataView(image: "arrow.down.circle.fill", imageBackground: .blue, dataKey: "ext.widget.tags.lowest".localized(), dataValue: isEmpty ? "--" : totaler.lowestPoint(fromPoints: entry.points))
                }
                HStack {
                    DataView(image: "equal.circle.fill", imageBackground: .primary, dataKey: "ext.widget.tags.total".localized(), dataValue: isEmpty ? "--" : totaler.sumOf(points: entry.points))
                    DataView(image: "number.circle.fill", imageBackground: .purple, dataKey: "ext.widget.tags.count".localized(), dataValue: isEmpty ? "--" : "\(entry.points.count) \(entry.points.count == 1 ? "ext.widget.tags.item".localized() : "ext.widget.tags.items".localized())")
                }
            }
            .padding()
            Spacer()
            LineChartView(data: entry.points, title: entry.name, lineGradient: lineGradient, showLabels: false)
                .frame(width: .infinity, height: 160)
        }
    }
}

struct TagInsightsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var scheme
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        let bgColor = scheme == .light ? Color.clear : Color(UIColor.tertiarySystemBackground)
        switch family {
        case .systemSmall:
            TagInsightEntrySmallView(entry: entry)
                .background(bgColor)
        case .systemMedium:
            TagInsightEntryMediumView(entry: entry)
                .background(bgColor)
        case .systemLarge:
            TagInsightEntryLargeView(entry: entry)
                .background(bgColor)
        @unknown default:
            TagInsightEntrySmallView(entry: entry)
                .background(bgColor)
        }
    }
    
    // MARK: Widget Entry Point
    @main
    struct TagInsights: Widget {
        let kind: String = "TagInsights"
        
        var body: some WidgetConfiguration {
            IntentConfiguration(kind: kind, intent: DynamicTagSearchIntent.self, provider: Provider()) { entry in
                TagInsightsEntryView(entry: entry)
            }
            .configurationDisplayName("ext.widget.tags.displayName")
            .description("ext.widget.tags.description")
        }
    }
    
    // MARK: Preview
    struct TagInsights_Previews: PreviewProvider {
        static var previews: some View {
            let size: WidgetFamily = .systemLarge
            
            Group {
                TagInsightsEntryView(entry: demoTagInsightEntry)
                    .environment(\.colorScheme, ColorScheme.light)
                TagInsightsEntryView(entry: demoEmptyTagInsightEntry)
                    .environment(\.colorScheme, ColorScheme.light)
                TagInsightsEntryView(entry: demoTagInsightEntry)
                    .environment(\.colorScheme, ColorScheme.dark)
                TagInsightsEntryView(entry: demoEmptyTagInsightEntry)
                    .environment(\.colorScheme, ColorScheme.dark)
            }
            .previewContext(WidgetPreviewContext(family: size))
        }
    }
}
