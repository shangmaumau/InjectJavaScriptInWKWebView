//
//  SMMSaveImageHelper.swift
//
//  Created by suxiangnan on 2021/5/7.
//  Copyright © 2021 GiANTLEAP. All rights reserved.
//

import UIKit
import Photos

/// 图片保存助手。
final class SMMSaveImageHelper: NSObject {

    /// 保存模式。
    public enum SaveMode {
        /// 系统相册。
        case systemLibrary
        /// 以app名称创建的文件夹。⚠️注意，多语言环境下app名称不同时，
        /// 创建的相册名称也不会相同。
        case appAlbum
    }

    public enum SaveError: Error {
        case des(String)
    }

    /// 保存图片的回调。
    /// - Parameters:
    ///   - success: 保存的结果。
    ///   - error: 如果有错误，这里会有错误信息。
    ///   - msg: 因为可能用户拒绝授予权限，这里会有相应信息。保存成功或失败，也会有。
    public typealias SaveCallback = (_ success: Bool, _ error: Error?, _ msg: String?) -> Void
    private var saveCallback: SaveCallback?

    static let shared = SMMSaveImageHelper()
    private override init() { }

    /// 相册名称。
    ///
    /// 当保存模式为 `appAlbum` 时，默认此值为app名称，如需自定义，
    /// 请在保存图片前，重设此值。
    public var albumName: String? = Bundle.main.infoDictionary?[String(kCFBundleNameKey)] as? String

    /// 保存图片。
    /// - Parameters:
    ///   - image: UIImage 类型的图片对象。
    ///   - mode: 保存的模式，具体见枚举释义。
    ///   - callback: 保存结果回调。
    public func save(_ image: UIImage, mode: SaveMode = .systemLibrary, callback: SaveCallback? = nil) {

        saveCallback = callback

        let authStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .authorized:
            if mode == .systemLibrary {
                saveImageIntoSystemLibrary(image)
            } else {
                saveImageIntoAlbum(image)
            }

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized:
                    if mode == .systemLibrary {
                        self?.saveImageIntoSystemLibrary(image)
                    } else {
                        self?.saveImageIntoAlbum(image)
                    }

                case .denied:
                    self?.saveCallback?(false, nil, NSLocalizedString("拒绝授予相册写入权限", comment: ""))
                    debugPrint("User denied")
                default:
                    break
                }
            }

        case .denied:
            saveCallback?(false, nil, NSLocalizedString("未授予相册写入权限", comment: ""))
            debugPrint("User denied")

        default:
            break
        }
    }

    private func saveImageIntoSystemLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            saveCallback?(false, error, NSLocalizedString("保存失败", comment: ""))
        } else {
            saveCallback?(true, nil, NSLocalizedString("保存成功", comment: ""))
        }
    }

    private func saveImageIntoAlbum(_ image: UIImage) {

        let createdAssets = createAssetWithImage(image)
        let createdCollection = createCollection()

        guard let cas = createdAssets, let ccs = createdCollection else {
            saveCallback?(false, nil, NSLocalizedString("Asset或相册创建失败", comment: ""))
            return
        }

        do {
            try PHPhotoLibrary.shared().performChangesAndWait({ [weak self] in
                let request = PHAssetCollectionChangeRequest.init(for: ccs)
                request?.insertAssets(cas, at: NSIndexSet(index: 0) as IndexSet)
                self?.saveCallback?(true, nil, NSLocalizedString("保存成功", comment: ""))
            })
        } catch {
            saveCallback?(false, error, NSLocalizedString("保存失败", comment: ""))
            debugPrint("PHPhotoLibrary.shared().performChangesAndWait error: \(error.localizedDescription)")
        }
    }

    private func createAssetWithImage(_ image: UIImage) -> PHFetchResult<PHAsset>? {

        var createdAssetId: String?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                createdAssetId = PHAssetChangeRequest.creationRequestForAsset(from: image).placeholderForCreatedAsset?.localIdentifier
            })
        } catch {
            debugPrint("PHPhotoLibrary.shared().performChangesAndWait error: \(error.localizedDescription)")
        }

        guard let caid = createdAssetId else {
            return nil
        }
        return PHAsset.fetchAssets(withLocalIdentifiers: [caid], options: nil)
    }

    private func createCollection() -> PHAssetCollection? {

        if let title = albumName {

            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)

            for idx in 0..<collections.count where collections[idx].localizedTitle == title {
                return collections[idx]
            }

            var createdCollectionId: String?
            do {
                try PHPhotoLibrary.shared().performChangesAndWait({
                    createdCollectionId = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection.localIdentifier
                })
            } catch {
                debugPrint("PHPhotoLibrary.shared().performChangesAndWait error: \(error.localizedDescription)")
            }

            guard let ccid = createdCollectionId else {
                return nil
            }

            return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [ccid], options: nil).firstObject
        }
        return nil
    }

    private func gimmeError(des: String) -> Error {
        SaveError.des(des)
    }
}
