//
//  WebViewPhotoBrowser.swift
//  InjectJS
//
//  Created by suxiangnan on 2021/5/8.
//  Copyright © 2021 GiANTLEAP. All rights reserved.
//

import WebKit

protocol ScriptMessageHandlerDelegate: AnyObject {

    /// Tells the handler that a webpage sent a script message.
    ///
    /// Use this method to respond to a message sent from the webpage’s JavaScript code.
    /// Use the message parameter to get the message contents and to determine the originating web view.
    ///
    /// - Parameters:
    ///   - userContentController: The user content controller that delivered the message to your handler.
    ///   - message: An object that contains the message details.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {

    deinit { debugPrint("____ DEINITED: \(self)") }
    private var configuration: WKWebViewConfiguration!
    private weak var delegate: ScriptMessageHandlerDelegate?
    private var scriptNamesSet = Set<String>()

    init(configuration: WKWebViewConfiguration, delegate: ScriptMessageHandlerDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        super.init()
    }

    func deinitHandler() {
        scriptNamesSet.forEach { configuration.userContentController.removeScriptMessageHandler(forName: $0) }
        configuration = nil
    }

    func registerScriptHandling(scriptNames: [String]) {
        for scriptName in scriptNames {
            if scriptNamesSet.contains(scriptName) { continue }
            configuration.userContentController.add(self, name: scriptName)
            scriptNamesSet.insert(scriptName)
        }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

protocol WebViewPhotoBrowser: NSObjectProtocol {

    /// 获取图片链接的脚本消息名称。
    var callbackPictureList: String { get }
    /// 查看大图的脚本消息名称。
    var callbackShowPicture: String { get }
    /// 网页图片列表。
    var webPictures: [String]? { get set }
    /// WKWebView 对象。
    var webView: WKWebView! { get set }
    /// 单独处理脚本的工具类。
    var scriptMessageHandler: ScriptMessageHandler? { get set }

    /// 注入点击网页图片可在原生界面查看大图的 js 脚本。
    /// - Parameter target: 用来处理 ScriptMessageHandlerDelegate 的对象。
    func addPhotoBrowserScript(_ target: AnyObject)

    /// 运行获取图片列表的 js 脚本。
    /// - Parameter webView: 要运行脚本的 webView 对象。
    func runGetPictureListScript(_ webView: WKWebView)
    /// 析构脚本处理者。
    func deinitHandler()

}

extension WebViewPhotoBrowser {

    var callbackPictureList: String {
        get {
            "callbackPictureList"
        }
    }

    var callbackShowPicture: String {
        get {
            "callbackShowPicture"
        }
    }

    func addPhotoBrowserScript(_ target: AnyObject) {
        let script = WKUserScript(source: getMyJavaScript(), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)

        scriptMessageHandler = ScriptMessageHandler(configuration: webView.configuration, delegate: target as! ScriptMessageHandlerDelegate)
        scriptMessageHandler?.registerScriptHandling(scriptNames: [ callbackPictureList, callbackShowPicture ])
    }

    func runGetPictureListScript(_ webView: WKWebView) {
        webView.evaluateJavaScript("getPictureList();") { _, error in
            if let err = error {
                debugPrint("Run javascript error: \(err.localizedDescription)")
            } else {
                debugPrint("Run javascript Ok.")
            }
        }
    }

    func deinitHandler() {
        scriptMessageHandler?.deinitHandler()
    }

    private func getMyJavaScript() -> String {
        if let filepath = Bundle.main.path(forResource: "fetchPictureList", ofType: "js") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
            return ""
        }
    }

}
