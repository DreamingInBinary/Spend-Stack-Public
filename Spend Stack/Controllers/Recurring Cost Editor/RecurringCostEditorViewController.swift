//
//  RecurringCostEditorViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 3/26/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

enum RecurringPickerComponents : Int, CaseIterable {
    case RecurringLabel, RecurringFrequency, RecurringChoice
}

class RecurringCostEditorViewController: BottomModalViewController {
    // MARK: Public Properties
    
    let listItem:SSListItem
    
    // MARK: Private Properties
    
    private let picker = UIPickerView(frame: .zero)
    private let commitSelections:(Int, ListItemRecurringPricingChoice) -> (Void)
    private var isPluralDuration:Bool = false
    private var recurringFrequency:Int = 1
    private var recurringChoice:ListItemRecurringPricingChoice = .day
    
    // MARK: Initializer
    
    @objc init(withListItem item:SSListItem, onDimiss:@escaping ((Int, ListItemRecurringPricingChoice) -> (Void))) {
        listItem = item
        commitSelections = onDimiss
        super.init(nibName: nil, bundle: nil)
        
        recurringFrequency = item.recurringPricingFrequency.intValue - 1
        recurringChoice = item.recurringPricingCycle
        isPluralDuration = recurringFrequency > 0
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
            make.edges.equalTo(view.snp.edges).inset(Int(SSSpacingMargin).toInsets())
        }
        picker.dataSource = self
        picker.delegate = self
        
        // Select freq and choice
        picker.selectRow(recurringFrequency,
                         inComponent: RecurringPickerComponents.RecurringFrequency.rawValue,
                         animated: false)
        picker.selectRow(Int(recurringChoice.rawValue - 1),
                         inComponent: RecurringPickerComponents.RecurringChoice.rawValue,
                         animated: false)
    }

    // MARK: Misc
    
    @objc public func commitSelection() {
        if recurringFrequency == 0 {
            recurringFrequency = 1
        }
        
        self.commitSelections(recurringFrequency, recurringChoice)
        dismiss(animated: true)
    }
}

extension RecurringCostEditorViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return RecurringPickerComponents.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let frequencyComponent:RecurringPickerComponents = RecurringPickerComponents(rawValue: component) ?? RecurringPickerComponents.RecurringLabel
        
        switch frequencyComponent {
        case .RecurringLabel:
            return 1
        case .RecurringFrequency:
            return 100
        case .RecurringChoice:
            return 4
        }
    }
}

extension RecurringCostEditorViewController : UIPickerViewDelegate {
    func titleForRow(_ row:Int, component:Int) -> String? {
        let frequencyComponent:RecurringPickerComponents = RecurringPickerComponents(rawValue: component) ?? RecurringPickerComponents.RecurringLabel
        
        switch frequencyComponent {
        case .RecurringLabel:
            return ss_Localized("listEdit.every")
        case .RecurringFrequency:
            return String(row + 1)
        case .RecurringChoice:
            switch row {
            case 0:
                return isPluralDuration ? ss_Localized("listEdit.days") : ss_Localized("listEdit.day")
            case 1:
                return isPluralDuration ? ss_Localized("listEdit.weeks") : ss_Localized("listEdit.week")
            case 2:
                return isPluralDuration ? ss_Localized("listEdit.months") : ss_Localized("listEdit.month")
            case 3:
                return isPluralDuration ? ss_Localized("listEdit.years") : ss_Localized("listEdit.year")
            default:
                return nil
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let label = view, let lbl = label as? UILabel {
            lbl.text = titleForRow(row, component: component)
            return lbl
        } else {
            let lbl = UILabel(frame: .zero)
            lbl.textColor = UIColor.ssMainFont()
            
            let fontStyle:UIFont.TextStyle = SSCitizenship.accessibilityFontsEnabled() ? .title1 : .title3
            let weight:UIFont.Weight = SSCitizenship.accessibilityFontsEnabled() ? .heavy : .medium
            
            let fontMetrics = UIFontMetrics(forTextStyle: fontStyle)
            let scaledFont = fontMetrics.scaledFont(for: UIFont.preferredFont(forTextStyle: fontStyle))
            lbl.font = UIFont.systemFont(ofSize: scaledFont.pointSize, weight: weight)
            lbl.textAlignment = .center
            lbl.text = titleForRow(row, component: component)
            
            return lbl
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let frequencyComponent:RecurringPickerComponents = RecurringPickerComponents(rawValue: component) ?? RecurringPickerComponents.RecurringLabel
        
        if frequencyComponent == .RecurringFrequency {
            isPluralDuration = row >= 1
            [0,1,2,3].forEach {
                if let lbl = pickerView.view(forRow: $0, forComponent: 2) as? UILabel {
                    lbl.text = titleForRow($0, component: 2)
                }
            }
            pickerView.setNeedsLayout()
            
            let stringFrq = titleForRow(row, component: RecurringPickerComponents.RecurringFrequency.rawValue)
            let freqInt = Int(stringFrq ?? "1") ?? 1
            self.recurringFrequency = freqInt
        } else if frequencyComponent == .RecurringChoice {
            let choice:ListItemRecurringPricingChoice = ListItemRecurringPricingChoice(rawValue: UInt(row + 1)) ?? ListItemRecurringPricingChoice.day
            self.recurringChoice = choice
        }
    }
}
