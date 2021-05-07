//
//  SMMAlertSheetController.swift
//  InjectJS
//
//  Created by suxiangnan on 2021/5/7.
//

import UIKit

class SMMAlertSheetAction: NSObject {
    typealias ActionCallback = (SMMAlertSheetAction) -> Void
    public private(set) var actionHandler: ActionCallback?
    public var title: String?

    init(title: String?, handler: ActionCallback?) {
        self.title = title
        self.actionHandler = handler
    }

}

class SMMAlertSheetController: UIView {

    public var title: String?
    public var actions: [SMMAlertSheetAction]?

    public func addAction(_ action: SMMAlertSheetAction) {

    }

    public func showOn(_ view: UIView) {

    }

}
