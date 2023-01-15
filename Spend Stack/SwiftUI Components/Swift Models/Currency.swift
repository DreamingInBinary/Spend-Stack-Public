//
//  Currency.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 11/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

import Foundation
import Combine

public class Currencies : ObservableObject {
    @Published var options:[Currency]
    @Published var searchTerm:String = ""
    
    private let allCurrencies:[Currency] = Currency.allCurrencies()
    private var searchSub:AnyCancellable?
    
    init() {
        options = allCurrencies
        searchSub = $searchTerm.receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] term in
            guard let weakSelf = self else { return }
                if term.isEmpty && weakSelf.options.count == weakSelf.allCurrencies.count { return }
                weakSelf.filterFrom(query: term)
        }
    }
    
    fileprivate func filterFrom(query searchTerm:String)  {
        let filteredOptions:[Currency]
        if searchTerm.isEmpty {
            filteredOptions = allCurrencies
        } else {
            filteredOptions = allCurrencies.filter {($0.localizedTitle().lowercased().contains(searchTerm.lowercased()) || $0.symbol.contains(searchTerm)) }
        }
        
        DispatchQueue.main.async {
            self.options = filteredOptions
        }
    }
    
}

public struct Currency : Identifiable, Hashable {
    public var id = UUID()
    public let name:String
    public let symbol:String
    public let code:String
    public let locale:Locale
    
    func localizedTitle() -> String {
        return locale.localizedString(forIdentifier: locale.identifier) ?? ""
    }
    
    static func debugPrints(forCurrencySymbol symbol:String) {
        let all = Locale.availableIdentifiers.compactMap{ Locale(identifier: $0)}
        let matchingLocales = all.filter{ $0.currencySymbol == symbol }
        
        let myLocale = Locale.current
        matchingLocales.forEach {
            let code:String = myLocale.localizedString(forCurrencyCode: $0.currencyCode ?? "") ?? ""
            let symbol:String  = $0.currencySymbol ?? "N/A"
            let identifier:String  = myLocale.localizedString(forIdentifier: $0.identifier) ?? ""
            print("Match: " + identifier + " - " + code + "(\(symbol))")
        }
    }
    
    static func allCurrenciesWithFirstMatchingLocale() -> [Currency] {
        let allLocales = Locale.availableIdentifiers.compactMap{ Locale(identifier: $0)}
        var isoCodes:[String] = Locale.isoCurrencyCodes
        var uniqueLocaleWithCurrencies:Set<Locale> = Set()
        
        allLocales.forEach { locale in
            if let code = locale.currencyCode {
                if isoCodes.contains(code), let idx = isoCodes.firstIndex(of: code) {
                    uniqueLocaleWithCurrencies.insert(locale)
                    isoCodes.remove(at: idx)
                }
            }
        }
        
        return uniqueLocaleWithCurrencies.compactMap { (locale) -> Currency? in
            guard let code = locale.currencyCode,
                let name = Locale.current.localizedString(forCurrencyCode: code),
                let localizedLocale = Locale.current.localizedCurrencyLocale(forCurrencyCode: code),
                let symbol = localizedLocale.currencySymbol
                else {  return nil }
            return Currency(name: name, symbol: symbol, code: code, locale: locale)
        }.sorted{ return $0.name < $1.name }
    }
    
    static func allCurrencies() -> [Currency] {
        return Locale.isoCurrencyCodes.compactMap { (code) -> Currency? in
            guard let name = Locale.current.localizedString(forCurrencyCode: code),
                let locale = Locale.current.localizedCurrencyLocale(forCurrencyCode: code),
                let symbol = locale.currencySymbol,
                !name.contains("(")
                else {  return nil }
            return Currency(name: name, symbol: symbol, code: code, locale: locale)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.id == rhs.id
    }
}

@objc public class CurrencyNotification : NSObject {
    @objc public let currencyIdentifier:String
    @objc public let listID:String
    
    public init(withListID listID:String, currencyID:String) {
        self.currencyIdentifier = currencyID
        self.listID = listID
    }
}

extension Locale {
    func localizedCurrencyLocale(forCurrencyCode currencyCode: String) -> Locale? {
        guard let languageCode = languageCode, let regionCode = regionCode else { return nil }
            /*
             Each currency can have a symbol ($, £, ¥),
             but those symbols may be shared with other currencies.
             For example, in Canadian and American locales,
             the $ symbol on its own implicitly represents CAD and USD, respectively.
             Including the language and region here ensures that
             USD is represented as $ in America and US$ in Canada.
            */
        let components: [String: String] = [
                    NSLocale.Key.languageCode.rawValue: languageCode,
                    NSLocale.Key.countryCode.rawValue: regionCode,
                    NSLocale.Key.currencyCode.rawValue: currencyCode,
                    NSLocale.Key.identifier.rawValue: identifier
                ]
        let identifier = Locale.identifier(fromComponents: components)
        return Locale(identifier: identifier)
    }
}
