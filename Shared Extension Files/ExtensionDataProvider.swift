//
//  ExtensionDataProvider.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/7/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import FMDB

// This is needed because I can't import existing models and objects into an extension without a whole mess of
// Other problems realted to Swift and Objective-C bridging header junk. Eventually, this should replace everything
// And be renamed from ExtensionDataProvider to something else that represents models and data access for both the
// Main app and all extensions. For now, these models are on an "add what you need when you need it" basis.

struct DataProvider {
    let queue = FMDatabaseQueue(path: URL.dbURL().path)
    
    func fetchLists(_ completion:(([List]) -> (Void))) {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectLists.rawValue, values: nil) {
                var lists: [List] = []
                
                while (res.next()) {
                    let list = List.listFrom(resultSet: res)
                    lists.append(list)
                }
                
                completion(lists)
            } else {
                completion([])
            }
        }
    }
    
    func fetchMonthlySubscriptionsForThisMonth(_ completion:((MonthlySubscriptions) -> (Void))) {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectRecurringPricedItemsForThisMonth.rawValue, values: nil) {
                var listItems: [ListItem] = []
                
                while (res.next()) {
                    let listItem = ListItem.itemFrom(resultSet: res)
                    listItems.append(listItem)
                }
                
                completion(MonthlySubscriptions(items: listItems, currencyIdentifier: ""))
            } else {
                completion(MonthlySubscriptions(items: [], currencyIdentifier: ""))
            }
        }
    }
    
    func fetchTags(_ completion:(([UserTag]) -> (Void))) {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectTags.rawValue, values: nil) {
                var tags: [UserTag] = []
                
                while (res.next()) {
                    let tag = UserTag.userTagFrom(resultSet: res)
                    tags.append(tag)
                }
                
                completion(tags)
            } else {
                completion([])
            }
        }
    }
    
    func fetchFirstTag(_ completion:((UserTag?) -> (Void))) {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectFirstTag.rawValue, values: nil) {
                var tag: UserTag?
                
                while (res.next()) {
                    tag = UserTag.userTagFrom(resultSet: res)
                }
                
                completion(tag)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchFirstList(_ completion:((List?) -> (Void))) {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectFirstList.rawValue, values: nil) {
                var list: List?
                
                while (res.next()) {
                    list = List.listFrom(resultSet: res)
                }
                
                completion(list)
            } else {
                completion(nil)
            }
        }
    }
    
    enum TagTimeRange {
        case week,month,year
    }
    
    func fetchItemFor(tagID:String, range:TagTimeRange, completion:(([ListItem], String) -> (Void))) {
        queue?.inDatabase{ db in
            if var res = try? db.executeQuery(Queries.selectItemsWithTagID.rawValue, values: [tagID]) {
                var items: [ListItem] = []
                var tagColor: String = "70A2F9"
                
                while (res.next()) {
                    items.append(ListItem.itemFrom(resultSet: res))
                }
                
                res = try! db.executeQuery(Queries.selectColorForTagID.rawValue, values: [tagID])
                
                while (res.next()) {
                    tagColor = res.string(forColumn: "color") ?? "appleRed"
                }
                
                completion(items, tagColor)
            } else {
                completion([], "")
            }
        }
    }
    
    func fetchListInsights(forListID listID:String, completion:((ListInsight) -> (Void))) {
        queue?.inDatabase{ db in
            var list: List?
            var tags: [UserListTag] = []
            var items: [ListItem] = []
            
            // The list iteself
            if var res = try? db.executeQuery(Queries.selectListByID.rawValue, values: [listID]) {
                while (res.next()) {
                    list = List.listFrom(resultSet: res)
                }
                
                // Get items
                res = try! db.executeQuery(Queries.selectItemsWithListD.rawValue, values: [listID])
                while (res.next()) {
                    items.append(ListItem.itemFrom(resultSet: res))
                }
                
                // Get tags for those items
                res = try! db.executeQuery(Queries.selectListTagsWithListID.rawValue, values: [listID])
                while (res.next()) {
                    tags.append(UserListTag.userListTagFrom(resultSet: res))
                }
                
                // Add in misc tag if needed
                if !items.filter({ $0.tagID == "" }).isEmpty {
                    tags.append(UserListTag.miscListTag)
                }
                
                let insights = ListInsight(list: list!, tags: tags, items: items)
                completion(insights)
            } else {
                let insights = ListInsight(list: List(identifier: "", name: "", count: 0, total: "", currencyIdentifier: ""), tags: [], items: [])
                completion(insights)
            }
        }
    }
    
    func fetchAppleCardChargesForThisMonth(with completion:(([UserListTag:[ListItem]]) -> (Void))) -> Void {
        queue?.inDatabase{ db in
            if let res = try? db.executeQuery(Queries.selectListItemsWithAppleCardForThisMonth.rawValue, values: nil) {
                var listItems: [ListItem] = []
                var tags: Set<UserListTag> = Set()
                var data: [UserListTag: [ListItem]] = Dictionary()
                
                // Apple Card charges for this month
                while (res.next()) {
                    let listItem = ListItem.itemFrom(resultSet: res)
                    listItems.append(listItem)
                }
                
                // Get tags for those items
                listItems.forEach {
                    let res = try! db.executeQuery(Queries.selectListTagsWithListTagID.rawValue, values: [$0.tagID])
                    while (res.next()) {
                        tags.insert(UserListTag.userListTagFrom(resultSet: res))
                    }
                }
                
                // Add in misc tag if needed
                if !listItems.filter({ $0.tagID == "" }).isEmpty {
                    tags.insert(UserListTag.miscListTag)
                }
                
                // Now create a dictionary and assign items to their tag
                tags.forEach { listTag in
                    var tagItems:[ListItem]
                    if listTag == UserListTag.miscListTag {
                        tagItems = listItems.filter { $0.tagID == "" }
                    } else {
                        tagItems = listItems.filter { $0.tagID == listTag.identifier }
                    }

                    data[listTag] = tagItems
                }
                
                completion(data)
            } else {
                completion([:])
            }
        }
    }
}

enum Queries: String {
    case selectLists = "SELECT * FROM LISTS;",
    selectListByID = "SELECT * FROM LISTS WHERE listID = (?);",
    selectRecurringPricedItemsForThisMonth = "SELECT * FROM LISTITEMS WHERE (recurringPricingCycle != 0 AND strftime('%m', datetime(customDate, 'unixepoch', 'localtime')) = strftime('%m', 'now'));",
    selectTags = "SELECT * FROM TAGS;",
    selectFirstTag = "SELECT * FROM TAGS ORDER BY tagID ASC LIMIT 1;",
    selectFirstList = "SELECT * FROM LISTS LIMIT 1;",
    selectItemsWithTagID = "SELECT * FROM LISTITEMS as li LEFT OUTER JOIN LISTTAGS as lt on lt.listTagID = li.tagID WHERE lt.listTagMasterTagID = (?);",
    selectItemsWithListTagID = "SELECT * FROM LISTITEMS as li LEFT OUTER JOIN LISTTAGS as lt on lt.listTagID = li.tagID;",
    selectItemsWithListD = "SELECT * FROM LISTITEMS WHERE listID = (?);",
    selectColorForTagID = "SELECT color FROM TAGS WHERE tagID = (?) LIMIT 1;",
    selectListTagsWithListID = "SELECT * FROM ListTags WHERE listTagListID = (?);",
    selectListTagsWithListTagID = "SELECT * FROM ListTags WHERE listTagID = (?);",
    selectListItemsWithAppleCardForThisMonth = "SELECT * FROM ListItems WHERE cardImportName = 'Apple Card' AND strftime('%m', datetime(customDate, 'unixepoch', 'localtime')) = strftime('%m', 'now'));"
}

// MARK: Models

protocol UserItem {
    var identifier: String { get }
}

enum AmountType {
    case unchecked, checked, all
}

struct Totaler {
    let formatter = NumberFormatter.userNumberFormatter()
    
    // Tags
    func lowestTagTotal(fromTags tags:[UserListTag], items:[ListItem]) -> String {
        let allTotals: [UserListTag:Double] = calculateAllTagTotals(forTags: tags, items: items)
        let low = allTotals.values.sorted(by: { $0 < $1 }).first ?? 0.0
        return formatter.string(from: NSNumber(value: low)) ?? ""
    }
    
    func highestTagTotal(fromTags tags:[UserListTag], items:[ListItem]) -> String {
        let allTotals: [UserListTag:Double] = calculateAllTagTotals(forTags: tags, items: items)
        let high = allTotals.values.sorted(by: { $0 > $1 }).first ?? 0.0
        return formatter.string(from: NSNumber(value: high)) ?? ""
    }
    
    func calculateAllTagTotals(forTags tags:[UserListTag], items:[ListItem]) -> [UserListTag:Double] {
        var totals: [UserListTag:Double] = [:]
        tags.forEach {
            totals[$0] = doubleTotal(forTag: $0, items: items)
        }
        
        return totals
    }
    
    func total(forTag userTag:UserListTag, items:[ListItem]) -> String {
        let total: Double = items.filter{
            $0.tagID == userTag.identifier
        }.compactMap {
            return $0.costToDouble()
        }.reduce(0.0) {
            $0 + $1
        }
        
        return formatter.string(from: NSNumber(value: total)) ?? ""
    }
    
    func doubleTotal(forTag userTag:UserListTag, items:[ListItem]) -> Double {
        return items.filter{
            $0.tagID == userTag.identifier
        }.compactMap {
            return $0.costToDouble()
        }.reduce(0.0) {
            $0 + $1
        }
    }
    
    // Items
    func itemCosts(forTag userTag:UserListTag, items:[ListItem]) -> [Double] {
        let tagItems: [ListItem] = items.filter {
            if userTag == UserListTag.miscListTag {
                return $0.tagID == ""
            } else {
                return $0.tagID == userTag.identifier
            }
        }
        let totals: [Double] = tagItems.compactMap{ $0.costToDouble() }
        
        return totals
    }
    
    func doubleTotal(forItems items:[ListItem]) -> [Double] {
        return items.map { $0.costToDouble() }
    }
    
    func averageCost(forItems items:[ListItem]) -> String {
        let itemTotal = doubleSumOf(points: doubleTotal(forItems: items))
        let average = (itemTotal / Double(items.count)).rounded()
        return formatter.string(from: NSDecimalNumber(value: average)) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    func lowestCost(forItems items:[ListItem]) -> String {
        let low = doubleTotal(forItems: items).sorted(by: { $0 < $1 }).first ?? 0.0
        return formatter.string(from: NSDecimalNumber(value: low)) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    func highestCost(forItems items:[ListItem]) -> String {
        let high = doubleTotal(forItems: items).sorted(by: { $0 > $1 }).first ?? 0.0
        return formatter.string(from: NSDecimalNumber(value: high)) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    // List
    func calculateTotal(forList list:List, currencyID:String? = nil) -> String {
        let formatter = NumberFormatter.userNumberFormatter(withCurrencyID: currencyID)
        let number = NSDecimalNumber(string: list.total)
        return formatter.string(from: number) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    func calculateCheckedTotal(forItems items:[ListItem], currencyID:String? = nil) -> String {
        let formatter = NumberFormatter.userNumberFormatter(withCurrencyID: currencyID)
        let number = NSDecimalNumber(value:items.filter{ $0.isChecked }.map{ $0.costToDouble() }.reduce(0.0) {
            $0 + $1
        })
        return formatter.string(from: number) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    func calculateUncheckedTotal(forItems items:[ListItem], currencyID:String? = nil) -> String {
        let formatter = NumberFormatter.userNumberFormatter(withCurrencyID: currencyID)
        let number = NSDecimalNumber(value:items.filter{ !$0.isChecked }.map{ $0.costToDouble() }.reduce(0.0) {
            $0 + $1
        })
        return formatter.string(from: number) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    // General
    func sumOf(points data:[Double]) -> String {
        let sum = data.reduce(0, { x, y in
            x + y
        })
        
        return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: sum)) ?? ""
    }
    
    func doubleSumOf(points data:[Double]) -> Double {
        return data.reduce(0, { x, y in
            x + y
        })
    }
    
    func highestPoint(fromPoints data:[Double]) -> String {
        let low = data.sorted(by: { $0 > $1 }).first ?? 0
        return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: low)) ?? ""
    }
    
    func lowestPoint(fromPoints data:[Double]) -> String {
        let high = data.sorted(by: { $0 < $1 }).first ?? 0
        return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: high)) ?? ""
    }
    
    func formattedMiddleNumber(fromPoints data:[Double]) -> String {
        // Get middle value
        guard data.count != 0 else { return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: 0)) ?? "" }
        let middleIndex = (data.count > 1 ? data.count - 1 : data.count) / 2
        let middleValue: Double = data[middleIndex]
        return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: middleValue)) ?? ""
    }
    
    func formattedMiddleAverage(fromPoints data:[Double]) -> String {
        // Get middle value
        guard data.count != 0 else { return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: 0)) ?? "" }
        let average: Double = (doubleSumOf(points: data)/2)
        return NumberFormatter.userNumberFormatter().string(from: NSNumber(value: average)) ?? ""
    }
}

struct List: UserItem {
    let identifier: String
    let name: String
    let count: Int
    let total: String
    let currencyIdentifier: String
    
    static func listFrom(resultSet:FMResultSet) -> List {
        return List(identifier: resultSet.string(forColumn: "listID")!,
                    name: resultSet.string(forColumn: "name") ?? "",
                    count: Int(resultSet.int(forColumn: "itemCount")),
                    total: resultSet.string(forColumn: "totalCost") ?? "0.00",
                    currencyIdentifier: resultSet.string(forColumn: "currencyIdentifier") ?? "")
    }
}

struct ListItem: UserItem {
    let identifier: String
    let title: String
    let totalCost: String
    let date: Double?
    let tagID: String
    let isChecked: Bool
    
    func costToDouble() -> Double {
        return Double(totalCost) ?? 0.0
    }
    
    static func itemFrom(resultSet:FMResultSet) -> ListItem {
        return ListItem(identifier:resultSet.string(forColumn: "listItemID")!,
                        title: resultSet.string(forColumn: "title") ?? "",
                        totalCost: resultSet.string(forColumn: "totalCost") ?? "",
                        date:resultSet.double(forColumn: "customDate"),
                        tagID: resultSet.string(forColumn: "tagID") ?? "",
                        isChecked: resultSet.int(forColumn: "checkedOff") == 1 ? true : false)
    }
}

struct UserTag: UserItem {
    let identifier: String
    let name: String
    let color: String
    
    static func userTagFrom(resultSet:FMResultSet) -> UserTag {
        return UserTag(identifier: resultSet.string(forColumn: "tagID")!,
                       name: resultSet.string(forColumn: "name")!,
                       color: resultSet.string(forColumn: "color")!)
    }
}

struct UserListTag: UserItem, Equatable, Hashable {
    let identifier: String
    let name: String
    let color: String
    static let miscListTag = UserListTag(identifier: UUID().uuidString, name: "Miscellaneous", color: "clear")
    
    static func userListTagFrom(resultSet:FMResultSet) -> UserListTag {
        return UserListTag(identifier: resultSet.string(forColumn: "listTagID")!,
                           name: resultSet.string(forColumn: "name")!,
                           color: resultSet.string(forColumn: "color")!)
    }
    
    func isMiscTag() -> Bool {
        return self == UserListTag.miscListTag
    }
    
    static func == (lhs: UserListTag, rhs: UserListTag) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.name == rhs.name && lhs.color == rhs.color
    }
}

struct MonthlySubscriptions {
    let items: [ListItem]
    let thisMonth: String = {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: now)
        return nameOfMonth
    }()
    let nothingUpText: String = "ext.widget.subs.nothingDue".localized()
    // Currently, this widget pulls monthly costs from *all* lists for this month. But I kept
    // This here in case there is ever an option to toggle it on a list by list basis. In which
    // Case, you'd want to use the list's currency identifier when displaying the amount.
    let currencyIdentifier: String
    
    func totalCost() -> String {
        let totalCost: Double = items.map{
            return Double($0.totalCost) ?? 0
        }.reduce(0.0) {
            $0 + $1
        }
    
        let formatter = NumberFormatter.userNumberFormatter()
        
        let number = NSDecimalNumber(value: totalCost)
        return formatter.string(from: number) ?? formatter.string(from: NSDecimalNumber(value: 0))!
    }
    
    func dueNext() -> String {
        guard !items.isEmpty else { return "" }

        if let nextUpItem = findNextUpItem(), let date = nextUpItem.date {
            let date = Date(timeIntervalSince1970: date)
            let day = date.get(.day)
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .ordinal
            
            if let dateString = numberFormatter.string(from: NSNumber(integerLiteral: day)) {
                return "\(nextUpItem.title) (\(dateString))"
            } else {
                return nextUpItem.title
            }
        } else {
            // Nothing else this month
            return nothingUpText
        }
    }
    
    func nextUpIdentifier() -> String {
        return findNextUpItem()?.identifier ?? "empty"
    }
    
    func createURLForNextUpItem() -> URL {
        return URL(string: SharedConstants.openItemURL + nextUpIdentifier())!
    }
    
    private func findNextUpItem() -> ListItem? {
        // Find the next recurring cost that's due this month, and past or on today's date
        return items.filter {
            return Date(timeIntervalSince1970: $0.date ?? 0).get(.day) >= Date().get(.day)
        }.sorted(by: {
            $0.date ?? -1 < $1.date ?? 0
        }).first
    }
}

struct ListInsight {
    var list: List
    var tags: [UserListTag]
    var items: [ListItem]
    let totaler = Totaler()
    
    func getTotalFor(amountType type:AmountType) -> String {
        switch type {
        case .unchecked:
            return totaler.calculateUncheckedTotal(forItems: items, currencyID: list.currencyIdentifier)
        case .checked:
            return totaler.calculateCheckedTotal(forItems: items, currencyID: list.currencyIdentifier)
        case .all:
            return totaler.calculateTotal(forList: list, currencyID: list.currencyIdentifier)
        }
    }
    
    func doubleTotalForItems() -> [Double] {
        return totaler.doubleTotal(forItems: items)
    }
    
    func lowestTagAmount() -> String {
        return totaler.lowestTagTotal(fromTags: tags, items: items)
    }
    
    func highestTagAmount() -> String {
        return totaler.highestTagTotal(fromTags: tags, items: items)
    }
    
    func averageCostForItems() -> String {
        return totaler.averageCost(forItems: items)
    }
    
    func lowestItemAmount() -> String {
        return totaler.lowestTagTotal(fromTags: tags, items: items)
    }
    
    func highestItemAmount() -> String {
        return totaler.highestTagTotal(fromTags: tags, items: items)
    }
    
    func createURLForList() -> URL {
        return URL(string: SharedConstants.openListURL + (list.identifier.isEmpty ? "empty" : list.identifier))!
    }
}

// MARK: Extensions
extension NumberFormatter {
    static func userNumberFormatter(withCurrencyID:String? = nil) -> NumberFormatter {
        let sharedDefaults = SharedConstants().sharedDefaults()
        let isUsingWholeNums = sharedDefaults.bool(forKey: "shouldUseWholeNumbers")
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.maximumFractionDigits = isUsingWholeNums ? 0 : 2
        formatter.minimumFractionDigits = isUsingWholeNums ? 0 : 2
        
        if let customCurrency = withCurrencyID {
            formatter.locale = Locale(identifier: customCurrency)
        } else {
            formatter.locale = Locale.current
        }
        
        return formatter
    }
    
    static func userFormatSpecifier() -> String {
        let sharedDefaults = SharedConstants().sharedDefaults()
        let isUsingWholeNums = sharedDefaults.bool(forKey: "shouldUseWholeNumbers")
        
        return isUsingWholeNums ? "%.0f" : "%.2f"
    }
}

extension URL {
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName)")
    }
    
    static func dbURL() -> URL {
        return URL.storeURL(for: SharedConstants.appGroupID, databaseName: "spendStack.db")
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    func month() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: self)
    }
    
    func year() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: self)
    }
}

extension String {
    // Ugh.....
    static func tagNameToColor(_ tagColorName:String) -> (r:Double, g:Double, b:Double) {
        if tagColorName == "appleRed" {
            return (r:1.000000, g:0.231373, b:0.188235)
        } else if tagColorName == "appleOrange" {
            return (r:1.000000, g:0.584314, b:0.282353)
        } else if tagColorName == "appleYellow" {
            return (r:1.000000, g:0.800000, b:0.000000)
        } else if tagColorName == "appleGreen" {
            return (r:0.298039, g:0.850980, b:0.392157)
        } else if tagColorName == "appleTealBlue" {
            return (r:0.352941, g:0.784314, b:0.980392)
        } else if tagColorName == "appleBlue" {
            return (r:0.000000, g:0.478431, b:1.000000)
        } else if tagColorName == "applePurple" {
            return (r:0.345098, g:0.337255, b:0.839216)
        } else if tagColorName == "applePink" {
            return (r:1.000000, g:0.176471, b:0.333333)
        } else if tagColorName == "appleNavy" {
            return (r:0.172549, g:0.243137, b:0.313725)
        } else if tagColorName == "appleDarkOrange" {
            return (r:0.827450, g:0.329411, b:0.000000)
        } else if tagColorName == "appleDarkGreen" {
            return (r:0.086274, g:0.627450, b:0.521568)
        } else if tagColorName == "appleDarkPurple" {
            return (r:0.607843, g:0.349019, b:0.713725)
        } else if tagColorName == "appleDarkBlue" {
            return (r:0.231373, g:0.349020, b:0.596078)
        } else {
            return (r:0.0, g:0.0, b:0.0)
        }
    }
    
    func localized() -> String {
        return NSLocalizedString(self, comment: "") 
    }
}

extension UIColor {
    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return self
        }
    }
}
