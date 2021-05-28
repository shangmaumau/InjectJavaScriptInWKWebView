//
//  MyWebVC.swift
//  InjectJS
//
//  Created by 尚雷勋 on 2021/5/1.
//

import UIKit
import WebKit
import SDWebImage
import JXPhotoBrowserMod

class MyWebVC: UIViewController, WKNavigationDelegate, WKUIDelegate, WebViewPhotoBrowser, ScriptMessageHandlerDelegate {

    var webPictures: [String]?
    var webView: WKWebView!
    var scriptMessageHandler: ScriptMessageHandler?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WebVC"

        webView = WKWebView(frame: view.bounds, configuration: WKWebViewConfiguration())
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView!)

        addPhotoBrowserScript(self)

        let myProjectBundle: Bundle = Bundle.main
        let myUrl = myProjectBundle.url(forResource: "sample1", withExtension: "html")!
        webView.loadFileURL(myUrl, allowingReadAccessTo: myUrl)

        // let url = URL(string: "https://appsdeveloperblog.com")!
        // myWebView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        runGetPictureListScript(webView)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if message.name == callbackPictureList,
           let data = message.body as? [String] {
            webPictures = data
        }

        if message.name == callbackShowPicture,
           let idx = message.body as? String {

            let lan = JXPhotoBrowser()
            lan.numberOfItems = { [weak self] in
                self?.webPictures?.count ?? 0
            }
            lan.reloadCellAtIndex = { [weak self] context in
                let lanternCell = context.cell as? JXPhotoBrowserImageCell
                let imgUrl = self?.webPictures?[context.index]
                guard let imgURL = imgUrl else {
                    return
                }
                lanternCell?.imageView.sd_setImage(with: URL(string: imgURL), completed: nil)
                lanternCell?.longPressedAction = { cell, _ in

                    let alertVC = UIAlertController(title: "Save Image", message: "Do you wanna save it?", preferredStyle: .actionSheet)
                    let action1 = UIAlertAction(title: "Save", style: .default) { _ in

                        let imageHelper = SMMSaveImageHelper.shared
                        // imageHelper.albumName = "HelloWorld"
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
        deinitHandler()
        print("MyWebVC dealloc")
    }

}
