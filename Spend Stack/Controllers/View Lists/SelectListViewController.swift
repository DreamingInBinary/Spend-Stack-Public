//
//  SelectListViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/29/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine

class SelectListViewController: SSBaseViewController {
    typealias onListSelect = ((SSList, SelectListViewController) -> Void)
    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<ListsSection, SSList>!
    private var listIDsToExlude: [String] = []
    private var onSelection: onListSelect
    private var store = DataStore()
    private var emptyState: SSEmptyStateView?
    private var subs: [AnyCancellable] = []
    
    init(excluding lists:[SSList] = [], title:String = ss_Localized("selectLists.move"), onSelect:@escaping onListSelect) {
        listIDsToExlude = lists.map { $0.dbID }
        onSelection = onSelect
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if let ssNav = navigationController as? SSNavigationController {
            ssNav.styleNavigationBarAsPlainWhiteWithBoldText()
        }

        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissOrPopKeyAction))
        navigationItem.leftBarButtonItem = cancel

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.backgroundColor = UIColor.systemBackground
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(SSListTableViewCell.self, forCellReuseIdentifier: VIEW_LISTS_VC_CELL_ID)

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        let nc = NotificationCenter.default
        nc.publisher(for: .listCRUD)
        .merge(with: nc.publisher(for: .newListsSnapshotAvailable))
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyListDiff(animate: true)
        }.store(in: &subs)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureDataSource()
        applyListDiff(animate: false)
    }
    
    // MARK: Datasoure
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, identifier: SSList) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: VIEW_LISTS_VC_CELL_ID, for: indexPath) as! SSListTableViewCell
            cell.setData(identifier)
            return cell
        }
    }
    
    private func applyListDiff(animate animation:Bool) {
        store.fetchAllLists { [weak self] lists in
            guard let self = self else { return }
            
            let items = lists.filter{ !self.listIDsToExlude.contains($0.dbID) }

            if items.isEmpty {
                self.emptyState = SSEmptyStateView(stateText: ss_Localized("selectLists.empty"), performAnimaton: true)
                self.tableView!.superview!.addSubview(self.emptyState!)
                self.emptyState!.snp.makeConstraints { make in
                    make.edges.equalTo(self.tableView!)
                }
            } else {
                if let emptyView = self.emptyState {
                    emptyView.removeFromSuperview()
                }
                
                var snap = ListsDiff()
                
                snap.appendSections([.main])
                snap.appendItems(items)
                
                self.dataSource.apply(snap, animatingDifferences: animation)
            }
        }
    }
}

extension SelectListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let list = dataSource.itemIdentifier(for: indexPath) else { return }
        onSelection(list, self)
    }
}
