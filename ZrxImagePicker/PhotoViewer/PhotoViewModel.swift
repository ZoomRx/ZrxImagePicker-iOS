//
//  PhotoViewModel.swift
//  PhotoPreviewer
//
//  Created by Swaminathan on 05/02/21.
//  Copyright © 2021 ZoomRx. All rights reserved.
//

import Foundation
import UIKit
import BSImagePicker
import Photos
import ZrxCameraViewController

public enum SettingsKeys {
    public static let maxLimit = "maxSelection"
    public static let leftBarButton = "leftBarButton"
    public static let rightBarButton = "rightBarButton"
    public static let navButtonTintColor = "navButtonTintColor"
    public static let sendButtonTintColor = "sendButtonTintColor"
    public static let navBarTintColor = "navBarTintColor"
    public static let allowEditing = "allowEditing"
    public static let allowCaption = "allowCaption"
    public static let captionPlaceHolderText = "captionPlaceHolderText"
    public static let font = "font"
}

class PhotoViewModel: NSObject {
    
    //MARK: - Properties
    var coordinator: PhotoViewCoordinator?
    var settings: [String:Any]?
    
    public lazy var maxLimit: Int = {
        if let limit = settings?[SettingsKeys.maxLimit] as? Int {
            return limit
        }
        
        return 10
    }()
    
    public lazy var leftBarButtonItem: UIBarButtonItem = {
        if let item = settings?[SettingsKeys.leftBarButton] as? UIBarButtonItem {
            return item
        }
        
        let button = UIBarButtonItem(image: bundledImage(named: "Back"), style: .plain, target: nil, action: nil)
        
        if let color = settings?[SettingsKeys.navButtonTintColor] as? UIColor {
            button.tintColor = color
        }
        
        return button
    }()
    
    public lazy var rightBarButtonItem: UIBarButtonItem = {
        if let item = settings?[SettingsKeys.rightBarButton] as? UIBarButtonItem {
            return item
        }

        let button = UIBarButtonItem(title: "Continue", style: .done, target: nil, action: nil)
        
        if let color = settings?[SettingsKeys.navButtonTintColor] as? UIColor {
            button.tintColor = color
        }
        
        return button
    }()
    
    public lazy var barTintColor: UIColor? = {
        return settings?[SettingsKeys.navBarTintColor] as? UIColor
    }()
    
    //MARK: - Methods
    
    /// This is used to return the UIImage from a specified bundle and not the default app bundle
    /// - Parameter named: name of the image
    /// - Returns: Optional UIImage object
    func bundledImage(named: String) -> UIImage? {
        return UIImage(named: named, in: PhotoPreviewViewController.bundle, compatibleWith: nil)
    }

    
    /// Opens Camera to take photo
    func takePhoto() {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            print("Cant open camera")
            coordinator?.finishedSelecting(with: nil)
            return
        }
        
        let picker = CameraViewController()
        let nav = UINavigationController(rootViewController: picker)
        picker.delegate = self
        
        leftBarButtonItem.target = self
        leftBarButtonItem.action = #selector(backAction)
        
        picker.navigationItem.leftBarButtonItem = leftBarButtonItem
        if let color = barTintColor {
            nav.navigationBar.barTintColor = color
        }
        nav.setNavigationBarHidden(false, animated: false)

        coordinator?.present(nav, animated: false)
    }
    
    /// Action when back button is pressed
    @objc func backAction() {
        self.coordinator?.finishedSelecting(with: nil)
        self.coordinator?.dismiss(animated: true)
    }
    
    /// Asks for permission to use gallery. If given authorized block is executed else cancelled block is executed
    /// - Parameters:
    ///   - authorized: Block to be executed if permission is given
    ///   - cancelled: Block to be executed if permission is not given
    func authorize(_ authorized: @escaping () -> Void, cancelled: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async(execute: authorized)
            case .denied:
                DispatchQueue.main.async(execute: cancelled)
            default:
                break
            }
        }
    }
    
    /// /// Opens gallery to select images
    func selectFromGallery() {
        self.authorize({
            let imagePicker = ImagePickerController()
            imagePicker.settings.dismiss.enabled = false
            imagePicker.modalPresentationStyle = .fullScreen
            imagePicker.settings.selection.max = self.maxLimit + 1 // Adding one more as the library calls limitReached when the count = maxLimit
            imagePicker.imagePickerDelegate = self
            
            if let color = self.barTintColor {
                imagePicker.navigationBar.barTintColor = color
            }
            
            imagePicker.cancelButton = self.leftBarButtonItem
            imagePicker.doneButton = self.rightBarButtonItem
            imagePicker.doneButtonTitle = self.rightBarButtonItem.title ?? "Done"
            self.coordinator?.present(imagePicker, animated: true)
        }, cancelled: {
            self.coordinator?.permissionDenied()
        })
    }
    
    /// Loads the Preview View with images selected and the settings passed
    /// - Parameter images: The array of images selected by the user
    func showPreview(with images: [UIImage]) {
        let previewVC = PhotoPreviewViewController(nibName: "PhotoPreviewViewController", bundle: PhotoPreviewViewController.bundle)
        previewVC.coordinator = coordinator
        previewVC.images = images
        
        if let allowEditing = settings?[SettingsKeys.allowEditing] as? Bool {
            previewVC.allowEditing = allowEditing
        }
        
        if let allowCaption = settings?[SettingsKeys.allowCaption] as? Bool {
            previewVC.allowCaption = allowCaption
        }
        
        if let captionPlaceHolderText = settings?[SettingsKeys.captionPlaceHolderText] as? String {
            previewVC.captionViewPlaceholder = captionPlaceHolderText
        }
        
        if let font = settings?[SettingsKeys.font] as? UIFont {
            previewVC.captionFont = font
        }
        
        if let color = settings?[SettingsKeys.sendButtonTintColor] as? UIColor {
            previewVC.sendButtonTintColor = color
        }
        
        previewVC.navButtonTintColor = leftBarButtonItem.tintColor
        // Creating a new copy of UIBarButtonItem as the action for the back button is different in PhotoPreviewViewController
        previewVC.leftBarButtonItem = UIBarButtonItem(image: leftBarButtonItem.image, style: leftBarButtonItem.style, target: nil, action: nil)
        previewVC.leftBarButtonItem?.tintColor = leftBarButtonItem.tintColor
        
        coordinator?.push(previewVC, animated: true)
    }
    
}

//MARK: - ImagePickerController Delegate
extension PhotoViewModel: ImagePickerControllerDelegate {
    func imagePicker(_ imagePicker: ImagePickerController, didSelectAsset asset: PHAsset) {
        if imagePicker.selectedAssets.count > maxLimit {
            imagePicker.deselect(asset: asset)
            let okayButton = UIAlertAction(title: "Okay", style: .default, handler: nil)
            let alert = UIAlertController(title: "Limit Reached", message: "Cannot select more than \(maxLimit) photo(s)", preferredStyle: .alert)
            alert.addAction(okayButton)
            imagePicker.present(alert, animated: true)
        }
    }

    func imagePicker(_ imagePicker: ImagePickerController, didDeselectAsset asset: PHAsset) {

    }

    func imagePicker(_ imagePicker: ImagePickerController, didFinishWithAssets assets: [PHAsset]) {

        let activityIndicator = UIActivityIndicatorView(style: .white)
        let overlayView = UIView()
        overlayView.backgroundColor = .black
        overlayView.alpha = 0.70

        if let topView = self.coordinator?.presentedViewController?.view {
            overlayView.frame = topView.frame
            topView.addSubview(overlayView)
            topView.addSubview(activityIndicator)
            activityIndicator.frame = topView.frame
            activityIndicator.startAnimating()
        }


        DispatchQueue.global(qos: .userInitiated).async {
            var images = [UIImage]()
            let group = DispatchGroup()

            for assest in assets {
                group.enter()
                
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                
                PHImageManager.default().requestImage(for: assest, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { (image, info) in

                    guard let newImage = image else {
                        group.leave()
                        return
                    }
                    
                    images.append(newImage)
                    group.leave()
                }
            }

            group.wait()

            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                overlayView.removeFromSuperview()
                self.showPreview(with: images)
            }

        }
    }

    func imagePicker(_ imagePicker: ImagePickerController, didCancelWithAssets assets: [PHAsset]) {
        self.coordinator?.finishedSelecting(with: nil)
        self.coordinator?.dismiss(animated: true)
    }

    func imagePicker(_ imagePicker: ImagePickerController, didReachSelectionLimit count: Int) {

    }


}

//MARK: - CameraViewController Delegate
extension PhotoViewModel: CameraViewControllerDelegate {
    func didFinishTaking(image: UIImage?, viewController: CameraViewController) {
        guard let capturedImage = image else {
            coordinator?.finishedSelecting(with: nil)
            coordinator?.dismiss(animated: true)
            return
        }

        self.showPreview(with: [capturedImage])
    }
    
    func didCancelWith(message: String, error: Error?, viewController: CameraViewController) {
        self.coordinator?.finishedSelecting(with: nil)
    }
    
    func permissionDenied(viewController: CameraViewController) {
        self.coordinator?.dismiss(animated: true)
        self.coordinator?.permissionDenied()
    }
}
