//
//  TagsHorizontalView.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 9/21/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine

extension Notification.Name {
    static let inlineTagViewAddTapped = Notification.Name.init("tagViewAddPressed")
    static let inlineTagViewTagTapped = Notification.Name.init("tagViewTagPressed")
}

@objc class TagsHorizontalView: UIView {
    
    @objc var onDoneTapped:((SSTagSelectionViewModel?) -> ())?
    @objc var onAddTapped:(() -> ())?
    
    var tags: [SSTagSelectionViewModel]? = nil
    lazy var datasource:UICollectionViewDiffableDataSource<Int, SSTagSelectionViewModel> = {
        return UICollectionViewDiffableDataSource<Int, SSTagSelectionViewModel>(collectionView: cv) { (collectionView: UICollectionView, indexPath: IndexPath, identifier: SSTagSelectionViewModel) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SS_TAG_CELL_ID, for: indexPath) as! SSTagCollectionViewCell
            cell.setData(self.tags![indexPath.item])
            return cell
        }
    }()
    
    @objc var sharedTags: [SSListTag] = []
    var subs: [AnyCancellable] = []
    
    lazy var cv: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        flow.minimumInteritemSpacing = 2.0;
        
        let tagsVC = UICollectionView(frame: self.bounds, collectionViewLayout: flow)
        tagsVC.delegate = self
        tagsVC.showsHorizontalScrollIndicator = false
        tagsVC.backgroundColor = .systemBackground
        tagsVC.register(SSTagCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: SS_TAG_CELL_ID)
        
        return tagsVC
    }()
    
    lazy var emptyViewLabel: SSLabel = {
        let lbl = SSLabel(textStyle: .caption2)
        lbl.text = ss_Localized("tagInline.emtpy")
        lbl.textAlignment = .center
        lbl.configureFontWeight(.semibold)
        lbl.adjustsFontSizeToFitWidth = true
        return lbl
    }()
    
    lazy var doneButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Done", for: .normal)
        btn.layer.cornerRadius = 4.0
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.ssTextPlaceholder(), for: .highlighted)
        btn.setBackgroundImage(UIImage(from: .systemBackground), for: .highlighted)
        btn.backgroundColor = .ssPrimary()
        btn.addTarget(self, action: #selector(self.performOnDone), for: .touchUpInside)
        
        return btn
    }()
    
    lazy var addButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        btn.addTarget(self, action: #selector(self.performOnAddTap), for: .touchUpInside)
        
        return btn
    }()
    
    lazy var sortButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "arrow.up.arrow.down.circle"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        
        if #available(iOS 14.0, *) {
            btn.showsMenuAsPrimaryAction = true
            btn.menu = sortingOptionsMenu()
        }
        
        return btn
    }()
    
    lazy var divider: UIView = {
        let divider = UIView(frame: .zero)
        divider.backgroundColor = .ssMuted()
        divider.isAccessibilityElement = false
        divider.isUserInteractionEnabled = false
        return divider
    }()
    
    @objc init(frame: CGRect, listSharedTags:[SSListTag]) {
        super.init(frame: frame)
        setupUIAndFetchTags(withSharedTags: listSharedTags)
        reloadTagsCollectionView(false)
        
        let nc = NotificationCenter.default
        nc.publisher(for: .newTagCreated)
        .compactMap{ $0.object as? SSTag }
        .sink { [weak self] tag in
            guard let self = self else { return }
            let tagVM = SSTagSelectionViewModel(masterTag: tag)
            self.tags?.insert(tagVM, at: 0)
            self.reloadTagsCollectionView(true)
        }.store(in: &subs)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    override func layoutSubviews() {
        super.layoutSubviews()
        if divider.layer.cornerRadius == 0 && divider.boundsHeight > 0 {
            divider.layer.cornerRadius = divider.boundsWidth/2
        }
    }
    // MARK: Public API
    
    @objc func presentTags() {
        self.isHidden = false
        if let selectedIDP = cv.indexPathsForSelectedItems?.first {
            cv.scrollToItem(at: selectedIDP, at: .centeredHorizontally, animated: false)
        }
    }
    
    @objc func hideTags(_ clearSelection:Bool = false) {
        self.isHidden = true
        
        if clearSelection {
            cv.indexPathsForSelectedItems?.forEach {
                cv.deselectItem(at: $0, animated: false)
            }
        }
    }
    
    // MARK: Private
    private func setupUIAndFetchTags(withSharedTags listSharedTags:[SSListTag]) {
        // First time setup
        backgroundColor = .systemBackground
        
        // Get data models
        let viewModels = SSTagSelectionViewModel.tagViewModelArray(fromTags:SSDataStore.sharedInstance().queryAllMasterTags() ?? [])
        let sharedTagModels = SSTagSelectionViewModel.tagViewModelArray(fromTags: listSharedTags)
        tags = viewModels + sharedTagModels
        
        let isiOS14 = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14
        
        // Add to view
        addSubview(doneButton)
        addSubview(addButton)
        if (isiOS14) { addSubview(sortButton) }
        addSubview(divider)
        addSubview(cv)
        
        doneButton.snp.makeConstraints { make in
            make.left.equalTo(self.snp.left).offset(SSLeftBigElementMargin)
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(44)
        }
        
        addButton.snp.makeConstraints { make in
            make.left.equalTo(self.doneButton.snp.right).offset(SSLeftElementMargin)
            make.centerY.equalTo(self.snp.centerY)
            make.height.width.equalTo(24)
        }
        
        if isiOS14 {
            sortButton.snp.makeConstraints { make in
                make.left.equalTo(self.addButton.snp.right).offset(SSLeftElementMargin)
                make.centerY.equalTo(self.snp.centerY)
                make.height.width.equalTo(24)
            }
        }
        
        divider.snp.makeConstraints { make in
            let snpView = isiOS14 ? self.sortButton : self.addButton
            make.left.equalTo(snpView.snp.right).offset(SSLeftElementMargin)
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(SSCitizenship.accessibilityFontsEnabled() ? 2.0 : 1.0/UIScreen.main.scale)
        }
        
        cv.snp.makeConstraints { make in
            make.left.equalTo(self.divider.snp.right).offset(SSLeftElementMargin)
            make.right.equalTo(self.snp.rightMargin).offset(SSRightElementMargin)
            make.top.equalTo(self.snp.top)
            make.bottom.equalTo(self.snp.bottom)
        }
    }
    
    private func sortingOptionsMenu() -> UIMenu {
        let imgAlpha = UIImage(systemName: "a.circle")
        let acSortAlphabetically = UIAction(title: ss_Localized("general.alphabetically"), image:imgAlpha) { handler in
            self.tags! = self.tags!.sorted(by: { $0.name < $1.name })
            self.reloadTagsCollectionView(true)
        }
        
        let imgNewest = UIImage(systemName: "arrow.up.square")
        let acSortNewest = UIAction(title: ss_Localized("general.newest"), image:imgNewest) { handler in
            self.tags! = self.tags!.sorted(by: { (tag1, tag2) in
                let d1 = tag1.type == .masterTag ? tag1.underlyingTag!.orderingIndex.intValue : tag1.underlyingListTag!.orderingIndex.intValue
                let d2 = tag1.type == .masterTag ? tag2.underlyingTag!.orderingIndex.intValue : tag2.underlyingListTag!.orderingIndex.intValue
                
                return d1 > d2
            })
            self.reloadTagsCollectionView(true)
        }
        
        let imgOldest = UIImage(systemName: "arrow.down.square")
        let acSortOldest = UIAction(title: ss_Localized("general.oldest"), image:imgOldest) { handler in
            self.tags! = self.tags!.sorted(by: { (tag1, tag2) in
                let d1 = tag1.type == .masterTag ? tag1.underlyingTag!.orderingIndex.intValue : tag1.underlyingListTag!.orderingIndex.intValue
                let d2 = tag1.type == .masterTag ? tag2.underlyingTag!.orderingIndex.intValue : tag2.underlyingListTag!.orderingIndex.intValue
                
                return d1 < d2
            })
            self.reloadTagsCollectionView(true)
        }
    
        return UIMenu(title: ss_Localized("tagInline.sortTitle"), children: [acSortOldest,acSortNewest, acSortAlphabetically])
    }
    
    private func reloadTagsCollectionView(_ animated:Bool) {
        if (self.tags!.isEmpty) {
            cv.addSubview(emptyViewLabel)
            emptyViewLabel.snp.makeConstraints{ make in
                make.left.equalTo(cv.snp.left).offset(SSLeftElementMargin/2)
                make.right.equalTo(cv.snp.right).offset(SSRightElementMargin/2)
                make.centerY.equalTo(cv.snp.centerY)
            }
            return
        } else if emptyViewLabel.superview != nil {
            emptyViewLabel.removeFromSuperview()
        }
        
        var snap = datasource.snapshot()
        snap.deleteAllItems()
        snap.appendSections([0])
        snap.appendItems(self.tags!)
        datasource.apply(snap, animatingDifferences: true)
    }
    
    @objc private func performOnDone() {
        guard let handler = onDoneTapped else { return }
        
        var tagVM: SSTagSelectionViewModel?
        if let idx = self.cv.indexPathsForSelectedItems?.first?.item, tags!.count > idx {
            tagVM = tags![idx]
        }
        handler(tagVM)
    }
    
    @objc private func performOnAddTap() {
        guard let handler = onAddTapped else { return }
        handler()
    }
}

// MARK: Collection View Delegate
extension TagsHorizontalView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selection = tags![indexPath.item]
        UIFeedbackGenerator.playFeedback(of: .selectionChanged)
        NotificationCenter.default.post(name: .inlineTagViewTagTapped, object: selection)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let indexPaths = collectionView.indexPathsForSelectedItems, indexPaths.contains(indexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            NotificationCenter.default.post(name: .inlineTagViewTagTapped, object: nil)
            return false
        }

        return true
    }
}

// MARK: Collection View Flow Layout Delegate
extension TagsHorizontalView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let textForItem = self.tags?[indexPath.item].name ?? ""
        let width = (textForItem as NSString).boundingRect(withWidth: collectionView.boundsWidth, text: textForItem, font: UIFont.preferredFont(forTextStyle: .callout)).size.width
        let proposedWidth = 4 + 18 + 4 + width + 4 + 16
        return CGSize(width: proposedWidth, height: boundsHeight)
    }
}
