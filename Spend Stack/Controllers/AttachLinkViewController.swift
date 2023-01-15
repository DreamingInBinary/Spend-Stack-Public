//
//  AttachLinkViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import LinkPresentation

@objc class AttachLinkViewController: SSBaseViewController {
    
    @objc var onLinkMetadataFetched:((LPLinkMetadata?, Error?) -> ())? {
        didSet {
            shouldFetchLinkMetadata = true
        }
    }
    
    @objc var onLinkStringEntered:((String) -> ())? {
        didSet {
            shouldFetchLinkMetadata = false
        }
    }
    
    // MARK: Properties
    
    private let linkTextField = SSTextField(textStyle: .title1)
    private var shouldFetchLinkMetadata:Bool = false
    
    // MARK: Initializer and Viewlifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ss_Localized("attachLink.title")
        
        view.addSubview(linkTextField)
        linkTextField.textColor = UIColor.ssTextPlaceholder()
        linkTextField.placeholder = "https://www."
        linkTextField.clearButtonMode = .always
        linkTextField.keyboardType = .URL
        linkTextField.autocapitalizationType = .none
        linkTextField.autocorrectionType = .no
        linkTextField.delegate = self
        linkTextField.configureFontWeight(.bold)
        linkTextField.snp.makeConstraints { make in
            make.left.equalTo(view.snp.left).offset(SSLeftBigElementMargin)
            make.right.equalTo(view.snp.right).offset(SSRightBigElementMargin)
            make.centerY.equalTo(view.snp.centerY)
        }
        
        let toolbar = SSToolbar(itemTypes: [SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDone])
        toolbar.onDone = { [unowned self] in
            self.attachLink()
        }
        toolbar.clipsToBounds = false
        linkTextField.inputAccessoryView = toolbar
        
        if navigationController?.viewControllers.count ?? 0 > 1 {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.systemBackground
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissOrPopKeyAction))
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(attachLink))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [unowned self] in
            self.linkTextField.becomeFirstResponder()
        }
    }
    
    // MARK: Fetching
    
    @objc func attachLink() {
        let text = trimmedTextFieldText()
        if text.count >= 3 {
            if shouldFetchLinkMetadata {
                fetchLinkMetaData()
            } else {
                if let handler = onLinkStringEntered {
                    handler(text)
                }
            }
        }
        
        dismissOrPopKeyAction()
    }
    
    fileprivate func fetchLinkMetaData() {
        if let handler = onLinkMetadataFetched {
            let text = trimmedTextFieldText()
            let parsedURL = URL(string: text)
            
            if let validURL = parsedURL {
                LPMetadataProvider().startFetchingMetadata(for: validURL) { (metadata, error) in
                    DispatchQueue.main.async {
                        if let linkData = metadata {
                            handler(linkData, nil)
                        } else {
                            handler(nil, error)
                        }
                    }
                }
            } else {
                handler(nil, LPError.init(.metadataFetchFailed))
            }
        }
    }
    
    fileprivate func trimmedTextFieldText() -> String {
        return (linkTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension AttachLinkViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return ((textField.text ?? "").count + string.count) > "https://www.".count
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        if !text.contains("https://www.") {
            textField.text = "https://www."
        }
    }
}
