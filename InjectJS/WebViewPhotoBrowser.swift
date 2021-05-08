//
//  WebViewPhotoBrowser.swift
//  InjectJS
//
//  Created by suxiangnan on 2021/5/8.
//  Copyright © 2021 GiANTLEAP. All rights reserved.
//

import WebKit

protocol ScriptMessageHandlerDelegate: AnyObject {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    
    deinit { print("____ DEINITED: \(self)") }
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
    
    var callbackPictureList: String { get }
    var callbackShowPicture: String { get }
    var webPictures: [String]? { get set }
    var webView: WKWebView! { get set }
    var scriptMessageHandler: ScriptMessageHandler! { get set }
    
    /// 注入 js 代码
    func addPhotoBrowserScript()
    func runGetPictureListScript(_ webView: WKWebView)
    
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
    
    /// 注入 js 代码
    func addPhotoBrowserScript() {
        
        let script = WKUserScript(source: getMyJavaScript(), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        
        scriptMessageHandler.registerScriptHandling(scriptNames: [ callbackPictureList, callbackShowPicture ])
    }
    
    func runGetPictureListScript(_ webView: WKWebView) {
        webView.evaluateJavaScript("getPictureList();") { _, error in
            if let err = error {
                print("Run javascript error: \(err.localizedDescription)")
            } else {
                print("Run javascript Ok.")
            }
        }
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
