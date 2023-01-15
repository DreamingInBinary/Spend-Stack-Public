//
//  AppleCardImportViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 4/13/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class AppleCardImportViewController: SSBaseViewController, UIDocumentPickerDelegate {
    
    // MARK: Public Properties
    
    var onImport:(([SSListItem]) -> (Void))?
    
    // MARK: Private Properties
    
    private let appleCardItems:[AppleCardImportItem]
    private let progressBar:UIProgressView = UIProgressView(progressViewStyle: .default)
    private let importingLbl:SSLabel = SSLabel(textStyle: .headline)
    private weak var list:SSList!
    private weak var dataSource:ListDataSource!
    private var importCount:Int = 0
    
    // MARK: Initializers
    
    init(withAppleCardImportItems importItems:[AppleCardImportItem], list:SSList, dataSource:ListDataSource) {
        appleCardItems = importItems
        self.list = list
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SSCitizenship.setViewAsTransparentIfPossible(view)

        importingLbl.textAlignment = .center
        importingLbl.configureFontWeight(.bold)
        importingLbl.textAlignment = .center
        updateImportLabel()
        importingLbl.sizeToFit()
                
        progressBar.tintColor = UIColor.ssPrimary()
        
        view.addSubviews([importingLbl, progressBar])

        importingLbl.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(view.snp.centerY).offset(SSBottomJumboElementMargin)
        }
        
        progressBar.snp.makeConstraints { make in
            make.centerY.equalTo(view.snp.centerY).offset(SSTopJumboElementMargin)
            make.width.equalTo(view.safeAreaLayoutGuide.snp.width).multipliedBy(0.50)
            make.centerX.equalTo(view.snp.centerX)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        importItems()
    }
    
    // MARK: Import Logic
    
    private func testImport() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.importCount += 1
            let totalWork:Float = 10
            let progress = Float(Float(self.importCount)/totalWork)
            
            self.progressBar.setProgress(progress, animated: true)
            let localizedText = ss_Localized("appleCard.import")
            let localized = String.localizedStringWithFormat(localizedText, String(self.importCount), String(Int(totalWork)))
            self.importingLbl.text = localized
            
            if self.progressBar.progress == 1 {
                timer.invalidate()
                self.onImport!([])
                self.dismissOrPopKeyAction()
            }
        }
    }
    
    private func importItems() {
        guard appleCardItems.count > 0 else { return }
        
        var listItems:[SSListItem] = []
        var tagCategories:[String:[SSListItem]] = Dictionary()
        
        var currentItemIndex = 0
        let fakeOutTimer = Double.random(in: 0.02..<0.075)
        Timer.scheduledTimer(withTimeInterval: fakeOutTimer, repeats: true) { [unowned self] timer in
            let item = self.appleCardItems[currentItemIndex]
            let listItem = AppleCardImportItem.importItemToSpendStackItem(importItem: item, forList: self.list)
            listItems.append(listItem)
            
            if (tagCategories[item.category] == nil) {
                tagCategories[item.category] = []
            }
            tagCategories[item.category]?.append(listItem)
            
            self.importCount += 1
            self.updateImportLabel()
            currentItemIndex += 1
            
            if (currentItemIndex == self.appleCardItems.count) {
                timer.invalidate()
                self.saveListItems(withTagCategories: tagCategories, listItems: listItems)
            }
        }
    }
    
    private func saveListItems(withTagCategories tagCategories:[String:[SSListItem]], listItems:[SSListItem]) {
        // A lot of transactions here. So create our own DB and take care of business.
        let db = self.dataSource.store.createDatabaseInstance()
        guard db.open() else {
            fatalError("Spend Stack - Cannot open database.")
        }
        
        var savedSSObjs:[SSObject] = []
        
        var existingSharedListTags:[SSListTag] = []
        if (self.list.listIsSharedWithMe()) {
            // Check if the original owner has any of the Apple Card import tags
            let tagCategories = Array(tagCategories.keys).filter { $0 != "Other" }
            existingSharedListTags = self.dataSource.snapshot().sectionIdentifiers.filter { sharedListTag in
                return tagCategories.contains(sharedListTag.name)
            }
        }
        
        // First, are there any tags we need to save as master tags that don't exist yet?
        // If a list tag already exists, it'll just be used during the save anyways.
        var masterTags:[SSTag] = SSDataStore.sharedInstance().queryAllMasterTags() ?? []
        let masterTagNames:[String] = Array(masterTags.map { $0.name as String })
        let missingMasterTags:[String] = Array(tagCategories.keys).filter { !masterTagNames.contains($0) && $0 != "Other" }
        
        // Save the master tags
        let tagColorStrings:[String] = SSTag.tagColorStrings()
        missingMasterTags.forEach { missingMasterTag in
            let randomColor = tagColorStrings.randomElement() ?? AppleRed
            let orderingIndex:Int = db.mostRecentOrderingIndexForTags()
            let tag:SSTag = SSTag(color: randomColor, name: missingMasterTag, order: orderingIndex.toNumber())
            db.insertTag(intoDB: tag)
            savedSSObjs.append(tag)
            masterTags.append(tag)
        }
        
        // Attach tags to items
        tagCategories.keys.forEach { tagName in
            // Might be misc tag, which from an Apple Import is "Other"
            let tag:SSTag? = masterTags.filter { $0.name == tagName }.first
            let sharedListTag:SSListTag? = existingSharedListTags.filter { $0.name == tagName }.first
            
            tagCategories[tagName]!.forEach { listItem in
                assert(listItem.fkListID == self.list.dbID, "List ID and item ID do not match.")
                if let sharedTag = sharedListTag {
                    listItem.addSharedListTag(sharedTag, with: self.list)
                } else if let tagToAdd = tag {
                    listItem.addListTag(tagToAdd, with: self.list, withDB: db)
                }
                db.insertListItem(intoDB: listItem, taxInfo: self.list.taxInfo, taxUtil:self.list.taxUtil)
                savedSSObjs.append(listItem)
            }
        }
        
        self.list.dbForList().save(savedSSObjs, with: .allKeys, delete: []) { error in
            if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
        }
        db.close()
        
        if let handler = self.onImport {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { 
                handler(listItems)
            }
        }
        
        self.dismissOrPopKeyAction()
    }
    
    private func updateImportLabel() {
        guard appleCardItems.count > 0 else { return }
        let totalWork:Float = Float(appleCardItems.count)
        let completedWork:Float = Float(importCount)
        let progress = completedWork/totalWork
        progressBar.setProgress(progress, animated: true)
        
        let localizedText = ss_Localized("appleCard.import")
        let localized = String.localizedStringWithFormat(localizedText, String(self.importCount), String(Int(totalWork)))
        self.importingLbl.text = localized
        importingLbl.text = localized
    }
}
