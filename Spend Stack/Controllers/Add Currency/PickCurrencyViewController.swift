//
//  PickCurrencyViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 3/12/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine

@objc class PickCurrencyViewController: SSBaseViewController {
    
    @objc var onSelect:((String) -> ())?
    
    // MARK: Private
    private var currencies:[Currency] = []
    private var filteredCurrencies:[Currency] = []
    private var tableViewStyle:UITableView.Style = .insetGrouped
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var datasource:UITableViewDiffableDataSource<Int, Currency>!
    private let searchController = UISearchController(searchResultsController: nil)
    private let keyboardNotifications:[NSNotification.Name] = [UIResponder.keyboardWillShowNotification,
                                                               UIResponder.keyboardDidShowNotification,
                                                               UIResponder.keyboardWillHideNotification,
                                                               UIResponder.keyboardDidHideNotification]
    private var kbSub:AnyCancellable?
    
    // MARK:  Initiailizer
    
    @objc convenience init(withTableViewStyle style:UITableView.Style = .insetGrouped) {
        self.init()
        tableViewStyle = style
    }
    
    @objc init() {
        super.init(nibName: nil, bundle: nil)
        
        title = ss_Localized("list.vc.chooseCurrency")
        
        kbSub = NotificationCenter.default.publisher(for: keyboardNotifications[0])
        .merge(with: NotificationCenter.default.publisher(for: keyboardNotifications[1]))
        .merge(with: NotificationCenter.default.publisher(for: keyboardNotifications[2]))
        .merge(with: NotificationCenter.default.publisher(for: keyboardNotifications[3]))
        .sink(receiveValue: { [weak self] (note) in
            guard let weakSelf = self else { return }
            let keyboardEndFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
            let height = Double(keyboardEndFrame.size.height)
            
            let animationDurationValue = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
            let animationDuration = animationDurationValue.doubleValue
            
            UIView.animate(withDuration: animationDuration) {
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(height), right: 0)
                weakSelf.tableView.contentInset = insets
                weakSelf.tableView.scrollIndicatorInsets = insets
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if tableViewStyle != .insetGrouped {
            tableView = UITableView(frame: .zero, style: tableViewStyle)
        }
        
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: BasicTableViewCell.CELL_ID)
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        datasource = UITableViewDiffableDataSource(tableView: tableView) { [unowned self] tableView, indexPath, currency in
            let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.CELL_ID, for: indexPath) as! BasicTableViewCell
            cell.setLeadingText(currency.name, trailingText: currency.symbol)
            if self.tableViewStyle != .grouped {
                cell.hideDivider = self.filteredCurrencies.count == 1 || (indexPath.row == (self.filteredCurrencies.count - 1))
            }
            
            return cell
        }
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = ss_Localized("currencyVC.searchCurrencies")
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        SSCitizenship.setViewAsTransparentIfPossible(view)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.snp.edges)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.currencies = Currency.allCurrencies()
            
            DispatchQueue.main.async {
                self.reloadAllCurrencies()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        kbSub?.cancel()
    }
    
    // MARK: Datasource
    
    fileprivate func reloadAllCurrencies() {
        var snap = NSDiffableDataSourceSnapshot<Int, Currency>()
        snap.appendSections([0])
        snap.appendItems(self.currencies)
        self.datasource.apply(snap, animatingDifferences: false)
    }
}

// MARK: Search Updating

extension PickCurrencyViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text, searchTerm.isEmpty == false else {
            if currencies.count != datasource.snapshot().itemIdentifiers.count {
                self.reloadAllCurrencies()
            }
            
            return
        }
        
        let term = searchTerm.lowercased()
        filteredCurrencies = currencies.filter { $0.name.lowercased().contains(term) || $0.symbol.lowercased().contains(term) }
        
        var snap = NSDiffableDataSourceSnapshot<Int, Currency>()
        snap.appendSections([0])
        snap.appendItems(filteredCurrencies)
        
        // Edge case, reload if it's only one cell to hide divider.
        if filteredCurrencies.count == 1 {
            snap.reloadItems([filteredCurrencies.first!])
        }
        
        self.datasource.apply(snap, animatingDifferences: true)
    }
}

// MARK: Table View Delegate

extension PickCurrencyViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let currency = datasource.itemIdentifier(for: indexPath) {
            if let onSelect = onSelect {
                onSelect(currency.locale.identifier)
            }
        }
    }
}
