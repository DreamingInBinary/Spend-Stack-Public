//
//  DateEditorViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 6/4/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class DateEditorViewController: BottomModalViewController {
    // MARK: Public Properties
    let listItem:SSListItem
    
    // MARK: Private Properties
    private let picker = UIDatePicker(frame: .zero)
    private let commitSelections:(Date) -> (Void)
    private var selectedDate:Date = Date()
    
    // MARK: Initializer
    @objc init(withListItem item:SSListItem, onDimiss:@escaping ((Date) -> (Void))) {
        listItem = item
        commitSelections = onDimiss
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .inline
        } else {
            picker.preferredDatePickerStyle = .automatic
        }
        if let currentItemDate = listItem.customDate {
            selectedDate = currentItemDate
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let doneBarBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(commitSelection))
        navigationItem.rightBarButtonItem = doneBarBtn
        
        view.addSubview(picker)
        picker.snp.makeConstraints{ make in
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(view.snp.centerY)
            make.width.height.equalTo(320)
        }

        picker.datePickerMode = .date
        picker.setDate(selectedDate, animated: false)
    }
    
    // MARK: Misc
    
    @objc public func commitSelection() {
        selectedDate = picker.date
        self.commitSelections(selectedDate)
        dismiss(animated: true)
    }
}
