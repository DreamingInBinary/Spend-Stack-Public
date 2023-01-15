//
//  IntentHandler.swift
//  TagSearchIntent
//
//  Created by Jordan Morgan on 8/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

// MARK: Tag Search Intent
extension IntentHandler : DynamicTagSearchIntentHandling {

    func provideTagOptionsCollection(for intent: DynamicTagSearchIntent, with completion: @escaping (INObjectCollection<IntentTag>?, Error?) -> Void) {
        let dp = DataProvider()
        dp.fetchTags { tags in
            let items: [IntentTag] = tags.map {
                IntentTag(identifier: $0.identifier, display: $0.name)
            }

            completion(INObjectCollection(items: items), nil)
        }
    }

    func defaultTag(for intent: DynamicTagSearchIntent) -> IntentTag? {
        let tagSemaphore = DispatchSemaphore(value: 0)

        var defaultTag: IntentTag?
        let dp = DataProvider()
        dp.fetchFirstTag { tag in
            guard let firstTag = tag else {
                tagSemaphore.signal()
                return
            }

            defaultTag = IntentTag(identifier: firstTag.identifier, display: firstTag.name)
            tagSemaphore.signal()
        }

        tagSemaphore.wait()
        return defaultTag
    }
}

// MARK: List Search Intent
extension IntentHandler : DynamicListSearchIntentHandling {
    
    func provideListOptionsCollection(for intent: DynamicListSearchIntent, with completion: @escaping (INObjectCollection<IntentList>?, Error?) -> Void) {
        let dp = DataProvider()
        dp.fetchLists { lists in
            let formatter = NumberFormatter.userNumberFormatter()
            let items: [IntentList] = lists.map {
                let totalAsNum = NSDecimalNumber(string: $0.total, locale: Locale.current)
                let totalFormatted = formatter.string(from: totalAsNum) ?? "0.00"
                
                return IntentList(identifier: $0.identifier, display: $0.name, subtitle: totalFormatted + " (\($0.count) \($0.count == 1 ? "item" : "items"))", image: nil)
            }

            completion(INObjectCollection(items: items), nil)
        }
    }
    
    func defaultList(for intent: DynamicListSearchIntent) -> IntentList? {
        let listSemaphore = DispatchSemaphore(value: 0)

        var defaultList: IntentList?
        let dp = DataProvider()
        dp.fetchFirstList { list in
            guard let firstList = list else {
                listSemaphore.signal()
                return
            }

            defaultList = IntentList(identifier: firstList.identifier, display: firstList.name)
            listSemaphore.signal()
        }

        listSemaphore.wait()
        return defaultList
    }
}
