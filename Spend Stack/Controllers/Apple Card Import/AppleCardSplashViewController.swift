//
//  SSAppleCardSplashViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 4/8/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import SafariServices

class AppleCardSplashViewController: SSBaseViewController {

    // MARK: Public Properties
    
    var onGetStartedTapped:(() -> (Void))?
    
    // MARK: Private Properties
    
    private let animContainer = UIView()
    private let cardImg:UIView = AppleCardSplashViewController.makeAppleCard()
    private let cardImg2:UIView = AppleCardSplashViewController.makeAppleCard()
    private let cardImg3:UIView = AppleCardSplashViewController.makeAppleCard()
    private let fxView = SSCitizenship.transparentViewIfPossible()
    private let vStack = SSVerticalView(secondaryBackgroundColor: ())
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Header
        let headerLbl = SSLabel(textStyle: .title2)
        headerLbl.configureFontWeight(.heavy)
        headerLbl.text = ss_Localized("appleCard.header")
        headerLbl.textAlignment = .center
        
        // Image animation
        animContainer.clipsToBounds = false
        animContainer.addSubviews([cardImg3, cardImg2, cardImg])
        animContainer.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.greaterThanOrEqualTo(220)
        }
    
        cardImg.tintColor = UIColor.ssPrimary()
        
        [cardImg, cardImg2, cardImg3].forEach {
            $0.snp.makeConstraints{ make in
                make.height.equalTo(60)
                make.width.equalTo(100)
                make.center.equalTo(animContainer.snp.center)
            }
            
            $0.alpha = 0
        }
        
        // Copy
        let copyLbl = SSLabel(textStyle: .body)
        copyLbl.textAlignment = .center
        copyLbl.text = ss_Localized("appleCard.copy")
        
        // Get Started
        let getStartedButton = SSButton(text: ss_Localized("appleCard.start"))
        let openFilePickerSelector = #selector(tappedGetStarted)
        getStartedButton.addTarget(self, action: openFilePickerSelector, for: .touchUpInside)
        
        // Show me how
        let showMeBtn = SSButton(labelStyle: ss_Localized("appleCard.howTo"))
        let dismissSelector = #selector(showMeHow)
        showMeBtn.addTarget(self, action: dismissSelector, for: .touchUpInside)
        
        var insets = UIEdgeInsets(top: SSTopBigElementMargin, left: SSLeftBigElementMargin, bottom: SSBottomBigElementMargin, right: SSRightBigElementMargin)
        if (self.traitCollection.horizontalSizeClass == .regular) {
            insets = UIEdgeInsets(top: SSTopBigElementMargin, left: SSLeftJumboElementMargin, bottom: SSBottomBigElementMargin, right: SSRightJumboElementMargin)
        }
        vStack.rowInset = insets
        vStack.hidesSeparatorsByDefault = true
        vStack.addRow(headerLbl, animated: false)
        vStack.addRow(animContainer, animated: false)
        vStack.addRow(copyLbl, animated: false)
        vStack.addRow(getStartedButton, animated: false)
        vStack.addRow(showMeBtn, animated: false)
        
        view.addSubview(vStack)
        
        vStack.setInsetForRow(getStartedButton, inset: UIEdgeInsets(top: 64, left: 100, bottom: 0, right: -100))
        vStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(SSTopBigElementMargin)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(SSLeftBigElementMargin)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(SSRightBigElementMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(SSBottomBigElementMargin)
        }
        
        vStack.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        view.addSubview(fxView)
        fxView.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }
        
        // Cursor on iPad can't exit without a button
        if self.isOniPad {
            let dismissSel = #selector(dismissOrPopKeyAction)
            let dismissBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: dismissSel)
            navigationItem.leftBarButtonItem = dismissBarButton
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: Double(SSFastAnimationDuration), delay: 0.25, options: .curveEaseInOut, animations: {
            SSCitizenship.setViewFadeOutAnimation(self.fxView)
            self.vStack.transform = .identity
            [self.cardImg, self.cardImg2, self.cardImg3].forEach {
                $0.alpha = 1
            }
        }, completion: { done in
            
            // Play icon animations
            self.cardImg.snp.updateConstraints { make in
                make.centerY.equalTo(self.animContainer.snp.centerY).offset(4)
            }
            
            self.cardImg2.snp.updateConstraints { make in
                make.centerY.equalTo(self.animContainer.snp.centerY).offset(-30)
            }
            
            self.cardImg3.snp.updateConstraints { make in
                make.centerY.equalTo(self.animContainer.snp.centerY).offset(-50)
            }

            UIView.animate(withDuration: Double(SSBriefAnimationDuration), delay: 0.0, options: .curveEaseInOut, animations: {
                self.animContainer.layoutIfNeeded()
                self.cardImg2.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.cardImg2.alpha = 0.8
                self.cardImg3.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                self.cardImg3.alpha = 0.6
            }, completion: { done in
                if (UIScreen.isTinyPhone() && done) {
                    self.vStack.flashScrollIndicators()
                }
            })
        })
    }
    
    // MARK: Private
    
    fileprivate static func makeAppleCard(withWhiteStyle white:Bool = true) -> UIView {
        let appleCardView = UIView(frame: .zero)
        appleCardView.ss_width = 100
        appleCardView.ss_height = 60
        appleCardView.backgroundColor = white ? .white : .black
        appleCardView.layer.cornerRadius = 4
        appleCardView.clipsToBounds = true
        let r = appleCardView.bounds
        appleCardView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: r.origin.x - 2,
                                                                          y: r.origin.y - 2,
                                                                          width: r.size.width + 4,
                                                                          height: r.size.height + 4),
                                                                    cornerRadius: appleCardView.layer.cornerRadius).cgPath
        appleCardView.layer.shadowColor = UIColor.black.cgColor
        appleCardView.layer.shadowOpacity = white ? 0.15 : 0.0
        appleCardView.layer.shadowOffset = .zero
        appleCardView.layer.shadowRadius = 0.4
        appleCardView.layer.masksToBounds = false
        
        let appleLogo = UILabel()
        appleLogo.ss_width = 100
        appleLogo.ss_height = 10
        appleLogo.ss_y = 10
        appleLogo.backgroundColor = appleCardView.backgroundColor
        appleLogo.text = "  "
        appleLogo.textColor = white ? UIColor.ssMainFont() : .white
        appleLogo.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        appleCardView.addSubview(appleLogo)
        
        let chip = UIView()
        chip.ss_width = 14
        chip.ss_height = 10
        chip.ss_y = 42
        chip.ss_x = 80
        chip.backgroundColor = .lightGray
        chip.clipsToBounds = true
        chip.layer.cornerRadius = 2
        appleCardView.addSubview(chip)
        
        let name = UILabel()
        name.ss_width = 40
        name.ss_height = 10
        name.ss_y = 42
        name.ss_x = 10
        name.backgroundColor = appleCardView.backgroundColor
        name.text = "Jane Doe"
        name.textColor = white ? UIColor.ssMainFont() : .white
        name.font = UIFont.systemFont(ofSize: 6, weight: .regular)
        appleCardView.addSubview(name)
        
        return appleCardView
    }
    
    // MARK: UI Toggle
    
    @objc fileprivate func showMeHow() {
        let helpURL = URL(string: "https://support.apple.com/en-us/HT209489")
        let safariVC = SFSafariViewController(url: helpURL!)
        self.present(safariVC, animated: true)
    }
    
    @objc fileprivate func tappedGetStarted() {
        guard let handler = onGetStartedTapped else { return }
        ss_defaults().set(true, forKey: SS_HAS_SEEN_APPLE_CARD_SPLASH)
        dismiss(animated: true) {
            handler()
        }
    }
}
