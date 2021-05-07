//
//  MyWebVC.swift
//  InjectJS
//
//  Created by 尚雷勋 on 2021/5/1.
//

import UIKit
import WebKit
import SDWebImage
import JXPhotoBrowser

class MyWebVC: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    let callbackPictureList = "callbackPictureList"
    let callbackShowPicture = "callbackShowPicture"

    var pictures = [String]()

    var myWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WebVC"

        let config = WKWebViewConfiguration()
        let js = getMyJavaScript()
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        config.userContentController.addUserScript(script)
        config.userContentController.add(self, name: callbackPictureList)
        config.userContentController.add(self, name: callbackShowPicture)

        myWebView = WKWebView(frame: view.bounds, configuration: config)
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        view.addSubview(myWebView!)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let myProjectBundle: Bundle = Bundle.main

        let myUrl = myProjectBundle.url(forResource: "sample1", withExtension: "html")!
        myWebView.loadFileURL(myUrl, allowingReadAccessTo: myUrl)

        // let url = URL(string: "https://appsdeveloperblog.com")!
        // myWebView.load(URLRequest(url: url))

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userContentCtrl().removeAllUserScripts()
        userContentCtrl().removeScriptMessageHandler(forName: callbackPictureList)
        userContentCtrl().removeScriptMessageHandler(forName: callbackShowPicture)
    }

    private func userContentCtrl() -> WKUserContentController {
        myWebView.configuration.userContentController
    }

    func getMyJavaScript() -> String {
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        webView.evaluateJavaScript("getPictureList();") { _, error in
            if let err = error {
                print("Run javascript error: \(err.localizedDescription)")
            } else {
                print("Run javascript Ok.")
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if message.name == callbackPictureList,
           let data = message.body as? [String] {
            pictures = data
        }

        if message.name == callbackShowPicture,
           let idx = message.body as? String {

            let lan = JXPhotoBrowser()
            lan.numberOfItems = { [weak self] in
                self?.pictures.count ?? 0
            }
            lan.reloadCellAtIndex = { [weak self] context in
                let lanternCell = context.cell as? JXPhotoBrowserImageCell
                let imgUrl = self?.pictures[context.index]
                guard let imgURL = imgUrl else {
                    return
                }
                lanternCell?.imageView.sd_setImage(with: URL(string: imgURL), completed: nil)
                lanternCell?.longPressedAction = { cell, _ in

                    let alertVC = UIAlertController(title: "Save Image", message: "Do you wanna save it?", preferredStyle: .actionSheet)
                    let action1 = UIAlertAction(title: "Save", style: .default) { _ in

                        let imageHelper = SMMSaveImageHelper.shared
                        imageHelper.albumName = "HelloWorld"
                        imageHelper.save(cell.imageView.image!, mode: .systemLibrary) { _, _, msg in
                            debugPrint("Save image msg: \(String(describing: msg))")
                        }
                    }
                    let action2 = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

                    alertVC.addAction(action1)
                    alertVC.addAction(action2)

                    cell.photoBrowser?.present(alertVC, animated: true, completion: nil)
                }
            }
            lan.pageIndex = Int(idx)!
            lan.show()
        }
    }

    deinit {
        print("MyWebVC dealloc")
    }

}
