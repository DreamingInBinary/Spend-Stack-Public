//
//  ChangeIconViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

struct AppIconAsset : Hashable {
    let displayName:String
    let designerName:String
    let assetName:String
    let twitterHandle:String
    let isDarkIcon:Bool
    
    static func dummyInstance() -> AppIconAsset {
        return AppIconAsset(displayName: "", designerName: "", assetName: "", twitterHandle: "", isDarkIcon: false)
    }
    
    static func allIcons() -> [AppIconAsset] {
        return [AppIconAsset(displayName: "Default", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Double Stack", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDoubleStackDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Budget Burndown", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconBudgetBurndownDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Lift", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDarkLiftDisplay", twitterHandle: "@lorenzvs", isDarkIcon: true),
                AppIconAsset(displayName: "Color Splash", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconColorSplashDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Trio", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconTrioDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Drift", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDriftDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Ghosted", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconGhostedDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Card Splash", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconCardSplashDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Sideways", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconSidewaysDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Dark Double Stack", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDarkDoubleStackDisplay", twitterHandle: "@lorenzvs", isDarkIcon: true),
                AppIconAsset(displayName: "Tri Stack", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconTristackDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Passport", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconPassportDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Clippy Returns", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconClippyReturnsDisplay", twitterHandle: "@lorenzvs", isDarkIcon: false),
                AppIconAsset(displayName: "Dark Card Splash", designerName: "Lorenz Vercauteren-Seghers", assetName: "AppIconDarkCardSplashDisplay", twitterHandle: "@lorenzvs", isDarkIcon: true),
                AppIconAsset(displayName: "Launched", designerName: "Charlie Chapman", assetName: "AppIconLaunchedDisplay", twitterHandle: "@_chuckyc", isDarkIcon: false)]
    }
}

@objc class ChangeIconViewController: SSModalViewController {

    // MARK: Public Properties
    var presentingHDImageView:UIImageView? // Yeah, yeah. I know.
    
    // MARK: Private Properties
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentToggle = UISegmentedControl(items: ["Regular", "Dark"])
    private var datasource:UITableViewDiffableDataSource<Int, AppIconAsset>!
    private var icons:[AppIconAsset] = AppIconAsset.allIcons().filter { $0.isDarkIcon == false }.sorted {
        return $0.displayName < $1.displayName
    }
    private var hasViewedIconInfoBox:Bool {
        return ss_defaults().bool(forKey: SS_HAS_SEEN_APP_ICON_INFO_BOX)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ss_Localized("changeIcon.title")
        
        tableView.register(IconTableViewCell.self, forCellReuseIdentifier: IconTableViewCell.CELL_ID)
        tableView.register(InfoTableViewCell.self, forCellReuseIdentifier: InfoTableViewCell.CELL_ID)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        datasource = UITableViewDiffableDataSource(tableView: tableView) { [unowned self] tableView, indexPath, iconAsset in
            
            if !self.hasViewedIconInfoBox && indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: InfoTableViewCell.CELL_ID, for: indexPath) as! InfoTableViewCell
                
                let trailingImage = UIImage(systemName: "xmark.circle.fill")
                cell.setLeadingText(ss_Localized("changeIcon.preview"), subText: ss_Localized("changeIcon.hd"), leadingImage: nil, trailingImage: trailingImage)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: IconTableViewCell.CELL_ID, for: indexPath) as! IconTableViewCell
                
                let currentIcon = UIApplication.shared.alternateIconName ?? ss_Localized("changeIcon.default")
                let isSelected = iconAsset.displayName == currentIcon
                let fileImage = UIImage(named: iconAsset.assetName)!
                
                cell.setData(iconAsset.displayName, iconDesigner: iconAsset.twitterHandle, appIconImage: fileImage, checked: isSelected)
                
                return cell
            }
        }
        datasource.defaultRowAnimation = .fade
        
        let tb = UIToolbar(frame: .zero)
        tb.addSubview(segmentToggle)
        let appearance:UIToolbarAppearance = UIToolbarAppearance()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.configureWithOpaqueBackground()
        tb.compactAppearance = appearance
        tb.standardAppearance = appearance
        
        segmentToggle.backgroundColor = .clear
        segmentToggle.selectedSegmentIndex = 0
        segmentToggle.addTarget(self, action: #selector(onSegmentChanged(_:)), for: .valueChanged)
        
        var snap = datasource.snapshot()

        if !hasViewedIconInfoBox {
            snap.appendSections([0])
            snap.appendItems([AppIconAsset.dummyInstance()], toSection: 0)
            snap.appendSections([1])
            snap.appendItems(icons, toSection: 1)
        } else {
            snap.appendSections([0])
            snap.appendItems(icons)
        }
        
        datasource.apply(snap, animatingDifferences: false, completion: nil)
        
        SSCitizenship.setViewAsTransparentIfPossible(view)
        view.addSubviews([tableView, tb])

        tableView.snp.makeConstraints { make in
            make.left.top.right.equalTo(view)
            make.bottom.equalTo(tb.snp.top)
        }
        
        tb.snp.makeConstraints { make in
            make.width.equalTo(view.snp.width)
            make.bottom.equalTo(view.snp.bottom)
            make.centerX.equalTo(view.snp.centerX)
            make.height.equalTo(64)
        }
        
        segmentToggle.snp.makeConstraints { make in
            make.centerX.equalTo(tb.snp.centerX)
            make.centerY.equalTo(tb.snp.centerY)
            make.width.equalTo(tb.snp.width).multipliedBy(0.84)
        }
    }
    
    // MARK: Segment Toggle
    
    @objc func onSegmentChanged(_ sender:UISegmentedControl) {
        let onlyDark = sender.selectedSegmentIndex == 1
        icons = AppIconAsset.allIcons().filter { $0.isDarkIcon == onlyDark }.sorted {
            return $0.displayName < $1.displayName
        }
        
        if hasViewedIconInfoBox {
            var snap = datasource.snapshot()
            // If the infobox was dismissed and then we toggle in the same session, 0 is actually still section 1
            // So just query the datasource
            let section = snap.sectionIdentifiers.first!
            snap.deleteItems(snap.itemIdentifiers(inSection: section))
            snap.appendItems(icons, toSection: section)
            datasource.apply(snap)
        } else {
            var snap = datasource.snapshot()
            snap.deleteItems(snap.itemIdentifiers(inSection: 1))
            snap.appendItems(icons, toSection: 1)
            datasource.apply(snap)
        }
    }
}

extension ChangeIconViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !hasViewedIconInfoBox && indexPath.section == 0 {
            datasource.defaultRowAnimation = .right
            
            ss_defaults().set(true, forKey: SS_HAS_SEEN_APP_ICON_INFO_BOX)
            ss_defaults().synchronize()
            
            var snap = datasource.snapshot()
            snap.moveSection(1, beforeSection: 0)
            snap.deleteSections([0])
            datasource.apply(snap)
            
            datasource.defaultRowAnimation = .fade
            return
        }
        
        let isShowingLightIcons = segmentToggle.selectedSegmentIndex == 0
        let isDefaultSelection = datasource.itemIdentifier(for: indexPath)?.displayName == ss_Localized("changeIcon.default")
        let iconName:String? = isDefaultSelection && isShowingLightIcons ? nil : icons[indexPath.row].displayName

        UIApplication.shared.setAlternateIconName(iconName) { [unowned self] error in
            if let error = error {
                self.showAlert(withTitle: "", message: error.localizedDescription)
            }
            self.tableView.reloadData()
        }
    }
}

@objc extension ChangeIconViewController : SSTheaterImageViewProvidingDelegate {
    func ss_presentingControllerImageView() -> UIImageView {
        return presentingHDImageView!
    }
    
    func presentHDPreview() {
        guard let presentingIcon = presentingHDImageView, let iconImg = presentingIcon.image else { return }
        let theatherVC = SSTheaterViewController(image: iconImg, listItem: nil)
        present(theatherVC, animated: true, completion: nil)
    }
}
