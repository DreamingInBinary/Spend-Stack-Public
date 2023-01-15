//
//  SwiftExtensions.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/17/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import SnapKit

extension Int {
    func toNumber() -> NSNumber {
        return NSNumber(integerLiteral: self)
    }
    
    func toInsets() -> UIEdgeInsets {
        let floatSelf = CGFloat(self)
        return UIEdgeInsets(top: floatSelf,
                            left: floatSelf,
                            bottom: floatSelf,
                            right: floatSelf)
    }
    
    func degreesToRadians() -> Double {
        return Double(self * Int(Double.pi) / 180)
    }
    
    static func tableViewBatchDuration() -> Double {
        return Double(SSUIKitTableViewBatchAnimationDuration)
    }
    
    static func dividerHeight() -> CGFloat {
        let height = SSCitizenship.accessibilityFontsEnabled() || SSCitizenship.prefersBoldText() ? 2.0 : 1.0/UIScreen.main.scale
        return height as CGFloat
    }
}

extension Double {
    func secondDelayThen(completion:@escaping (()-> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + self, execute: completion)
    }
}

extension UIScreen {
    class func isTinyPhone() -> Bool {
        return UIScreen.main.nativeBounds.size.height <= ss_tinyPhoneThreshold
    }
}

extension SSPopupModalPresentationController {
    class func adaptivePresent(from presenter:UIViewController, presented:UIViewController) {
        if UIScreen.isTinyPhone() {
            let navVC = SSNavigationController(rootViewController: presented)
            presenter.present(navVC, animated: true)
        } else {
            SSPopupModalPresentationController.presentPresentationController(from: presenter, presentedController: presented)
        }
    }
}

extension UICollectionView {
    func deselectedItem(withCoordinater coordinator: UIViewControllerTransitionCoordinator?) {
        guard let selectedIDP = indexPathsForSelectedItems?.first else { return }
        
        if let transitionCTX = coordinator {
            transitionCTX.animate { (ctx) in
                self.deselectItem(at: selectedIDP, animated: true)
            } completion: { (ctx) in
                if ctx.isCancelled {
                    self.selectItem(at: selectedIDP, animated: true, scrollPosition: .bottom)
                }
            }
        } else {
            self.deselectItem(at: selectedIDP, animated: true)
        }
    }
    
    func keyframeFade() {
        UIView.animateKeyframes(withDuration: 1.0, delay: 0.0, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.alpha = 0.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.alpha = 1.0
            }
        } completion: { _ in }
    }
}

extension UIWindow {
    // MARK: Drag Thing
    
    @objc final class DragThing : UIView {
        public static let height = 54
        private var icon:String
        private var text:String
        private var iconView:UIImageView = UIImageView(frame: .zero)
        private var textLabel:UILabel = UILabel(frame: .zero)
        
        required init(frame: CGRect, icon:String, text:String) {
            self.icon = icon
            self.text = text

            super.init(frame: .zero)
            
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 6
            layer.shadowOpacity = Float(0.16)
            layer.cornerRadius = CGFloat(DragThing.height/2)
            layer.cornerCurve = .continuous
            backgroundColor = .secondarySystemBackground
            
            addSubviews([textLabel, iconView])
            
            textLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            textLabel.textColor = .secondaryLabel
            textLabel.text = text
            textLabel.lineBreakMode = .byTruncatingTail
            textLabel.snp.makeConstraints { make in
                make.leading.equalTo(iconView.snp.trailingMargin).offset(16)
                make.centerY.equalTo(self.snp.centerY)
                make.trailing.equalTo(self.snp.trailingMargin).offset(-16)
            }
            
            iconView.contentMode = .scaleAspectFit
            iconView.snp.makeConstraints { make in
                make.leading.equalTo(self.snp.leadingMargin).offset(8)
                make.centerY.equalTo(self.snp.centerY)
                make.height.width.equalTo(24)
            }
            
            iconView.image = UIImage(systemName: icon)
            iconView.tintColor = .tertiaryLabel
            iconView.transform = transform.scaledBy(x: 0.4, y: 0.4)
            iconView.alpha = 0.0
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: Public API
        
        func show(in view:UIView, autoDimiss:Bool = true) {
            // No idea why, but it's not initially centered correctly.
            self.snp.updateConstraints { make in
                make.centerX.equalTo(view.safeAreaLayoutGuide.snp.centerX)
            }
            view.layoutIfNeeded()
            
            self.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
                make.height.equalTo(DragThing.height)
                make.width.equalTo(self.snp.width).priority(.medium)
                make.width.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.width).offset(-32)
                make.centerX.equalTo(view.safeAreaLayoutGuide.snp.centerX)
            }
            
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0.4, options: .curveEaseOut, animations: ({
                view.layoutIfNeeded()
            })) { completion in
            
            }
            
            UIView.animate(withDuration: 1.5, delay: 0.35, usingSpringWithDamping: 0.44, initialSpringVelocity: 0.3, options: .curveEaseOut, animations: ({
                self.iconView.transform = .identity
                self.iconView.alpha = 1
            })) { completion in
                if autoDimiss {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.hide(in: view)
                    }
                }
            }
        }
        
        func hide(in view:UIView) {
            self.snp.updateConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-140)
            }
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseIn, animations: {
                view.layoutIfNeeded()
                self.alpha = 0.25
            }, completion: nil)
        }
        
        func update(text updatedText:String, icon:String) {
            
        }
    }
    
    @objc func showDragThing(withIcon icon:String, text:String) {
        let dragThing = DragThing(frame: bounds, icon: icon, text: text)
        addSubview(dragThing)
        
        dragThing.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(-140)
            make.height.equalTo(DragThing.height)
            make.width.equalTo(dragThing.snp.width)
            make.centerX.equalTo(self.safeAreaLayoutGuide.snp.centerX)
        }
        
        dragThing.show(in: self)
    }
    
    @objc class func firstActiveScene() -> UIWindowScene? {
        for scene in UIApplication.shared.connectedScenes {
            if (scene.activationState == .foregroundActive && scene is UIWindowScene) {
                return scene as? UIWindowScene
            }
        }
        
        return nil
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}

extension Array where Element: Hashable {
    func ss_difference(from that: [Element]) -> [Element] {
        let this = Set(self)
        let that = Set(that)
        return Array(this.symmetricDifference(that))
    }
}
