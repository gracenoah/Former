//
//  TextFieldRowFormer.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 7/25/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit

public protocol TextFieldFormableRow: FormableRow {
    
    func formTextField() -> UITextField
    func formTitleLabel() -> UILabel?
}

public class TextFieldRowFormer<T: UITableViewCell where T: TextFieldFormableRow>
: CustomRowFormer<T>, FormValidatable {
    
    // MARK: Public
    
    override public var canBecomeEditing: Bool {
        return enabled
    }
    
    public var onValidate: (String? -> Bool)?
    
    public var onTextChanged: (String -> Void)?
    public var text: String?
    public var placeholder: String?
    public var attributedPlaceholder: NSAttributedString?
    public var textDisabledColor: UIColor? = .lightGrayColor()
    public var titleDisabledColor: UIColor? = .lightGrayColor()
    public var titleEditingColor: UIColor?
    public var returnToNextRow = true
    
    required public init(instantiateType: Former.InstantiateType = .Class, cellSetup: (T -> Void)? = nil) {
        super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }
    
    deinit {
        let textField = typedCell.formTextField()
        textField.delegate = nil
        let events: [(Selector, UIControlEvents)] = [("textChanged:", .EditingChanged),
            ("editingDidBegin:", .EditingDidBegin),
            ("editingDidEnd:", .EditingDidEnd)]
        events.forEach {
            typedCell.formTextField().removeTarget(self, action: $0.0, forControlEvents: $0.1)
        }
    }
    
    public override func cellInitialized(cell: UITableViewCell) {
        super.cellInitialized(cell)
        if let row = cell as? TextFieldFormableRow {
            let events: [(Selector, UIControlEvents)] = [("textChanged:", .EditingChanged),
                ("editingDidBegin:", .EditingDidBegin),
                ("editingDidEnd:", .EditingDidEnd)]
            events.forEach {
                row.formTextField().addTarget(self, action: $0.0, forControlEvents: $0.1)
            }
        }
    }
    
    public override func update() {
        super.update()
        
        typedCell.selectionStyle = .None
        let titleLabel = typedCell.formTitleLabel()
        let textField = typedCell.formTextField()
        textField.text = text
        _ = placeholder.map { textField.placeholder = $0 }
        _ = attributedPlaceholder.map { textField.attributedPlaceholder = $0 }
        textField.userInteractionEnabled = false
        textField.delegate = observer
        
        if enabled {
            if isEditing {
                if titleColor == nil { titleColor = titleLabel?.textColor }
                _ = titleEditingColor.map { titleLabel?.textColor = $0 }
            } else {
                _ = titleColor.map { titleLabel?.textColor = $0 }
                titleColor = nil
            }
            _ = textColor.map { textField.textColor = $0 }
            textColor = nil
        } else {
            if titleColor == nil { titleColor = titleLabel?.textColor }
            if textColor == nil { textColor = textField.textColor }
            titleLabel?.textColor = titleDisabledColor
            textField.textColor = textDisabledColor
        }
    }
    
    public override func cellSelected(indexPath: NSIndexPath) {
        super.cellSelected(indexPath)
        
        let textField = typedCell.formTextField()
        if !textField.editing {
            textField.userInteractionEnabled = true
            textField.becomeFirstResponder()
        }
    }
    
    public func validate() -> Bool {
        return onValidate?(text) ?? true
    }
    
    // MARK: Private
    
    private var textColor: UIColor?
    private var titleColor: UIColor?
    
    private lazy var observer: Observer<T> = { [unowned self] in
        Observer<T>(textFieldRowFormer: self)
        }()
    
    private dynamic func textChanged(textField: UITextField) {
        if enabled {
            let text = textField.text ?? ""
            self.text = text
            onTextChanged?(text)
        }
    }
    
    private dynamic func editingDidBegin(textField: UITextField) {
        let titleLabel = typedCell.formTitleLabel()
        if titleColor == nil { textColor = textField.textColor }
        _ = titleEditingColor.map { titleLabel?.textColor = $0 }
    }
    
    private dynamic func editingDidEnd(textField: UITextField) {
        let titleLabel = typedCell.formTitleLabel()
        if enabled {
            _ = titleColor.map { titleLabel?.textColor = $0 }
            titleColor = nil
        } else {
            if titleColor == nil { titleColor = titleLabel?.textColor }
            _ = titleEditingColor.map { titleLabel?.textColor = $0 }
        }
        typedCell.formTextField().userInteractionEnabled = false
    }
}

private class Observer<T: UITableViewCell where T: TextFieldFormableRow>: NSObject, UITextFieldDelegate {
    
    private weak var textFieldRowFormer: TextFieldRowFormer<T>?
    
    init(textFieldRowFormer: TextFieldRowFormer<T>) {
        self.textFieldRowFormer = textFieldRowFormer
    }
    
    private dynamic func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let textFieldRowFormer = textFieldRowFormer else { return false }
        if textFieldRowFormer.returnToNextRow {
            let returnToNextRow = (textFieldRowFormer.former?.canBecomeEditingNext() ?? false) ?
                textFieldRowFormer.former?.becomeEditingNext :
                textFieldRowFormer.former?.endEditing
            returnToNextRow?()
        }
        return !textFieldRowFormer.returnToNextRow
    }
}