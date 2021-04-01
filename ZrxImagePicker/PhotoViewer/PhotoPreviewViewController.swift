//
//  PhotoPreviewViewController.swift
//  PhotoPreviewer
//
//  Created by Swaminathan on 04/02/21.
//  Copyright © 2021 ZoomRx. All rights reserved.
//

import UIKit
import Photos
import ZrxCropViewController

class PhotoPreviewViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var captionView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var thumbnailCollectionView: UICollectionView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var thumbnailCollectionViewHeight: NSLayoutConstraint!
    
    //MARK: - Properties
    var delegate: UIViewController?
    var images: [UIImage]?
    var captions: [String]?
    var selectedIndex = 0
    var keyboardPadding: CGFloat = 10
    var captionViewPlaceholder = "Add a Caption"
    var placeholderTextColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    var borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    var allowEditing = true
    var allowCaption = true
    var navButtonTintColor: UIColor? = nil
    var sendButtonTintColor: UIColor? = .white
    var leftBarButtonItem: UIBarButtonItem? = nil
    var captionFont: UIFont? = nil
    var coordinator: PhotoViewCoordinator?
    
    static var bundle: Bundle {
        return Bundle(for: PhotoPreviewViewController.self)
    }
    
    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isBeingPresented || isMovingToParent {
            setupView()
        }
        
        if allowCaption {
            NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification , object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification , object: nil)
        }
        
        loadPreviewImages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Utility functions
    
    /// Action when back button is pressed
    @objc func backAction() {
        self.coordinator?.remove(self, animated: true)
    }
    
    /// This is used to return the UIImage from a specified bundle and not the default app bundle
    /// - Parameter named: name of the image
    /// - Returns: Optional UIImage object
    func bundledImage(named: String) -> UIImage? {
        return UIImage(named: named, in: PhotoPreviewViewController.bundle, compatibleWith: nil)
    }
    
    /// Sets up different views and buttons with appropriate properties
    func setupView() {
        if images?.count == 1 {
            thumbnailCollectionView.isHidden = true
            thumbnailCollectionViewHeight.constant = 0
        }
        
        
        if !allowCaption {
            captionView.alpha = 0
            captionView.isUserInteractionEnabled = false
        } else {
            captionView.text = captionViewPlaceholder
            captionView.textColor = placeholderTextColor
            captionView.layer.borderColor = borderColor.cgColor
            captionView.textContainerInset = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
            if let font = captionFont {
                captionView.font = font
            }
            captionView.delegate = self
        }
        
        leftBarButtonItem?.target = self
        leftBarButtonItem?.action = #selector(backAction)
        
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        if allowEditing {
            let cropButton = UIBarButtonItem(image: bundledImage(named: "Crop"), style: .plain, target: self, action: #selector(cropClicked))
            if let color = navButtonTintColor {
                cropButton.tintColor = color
            }
            self.navigationItem.rightBarButtonItem = cropButton
        }
        
        sendButton.setImage(bundledImage(named: "Send"), for: .normal)
        sendButton.backgroundColor = navigationController?.navigationBar.tintColor
        if let color = sendButtonTintColor {
            sendButton.tintColor = color
        }
    }
    
    /// Loads the preview image and the caption
    func loadPreviewImages() {
        guard let images = images else {
            return
        }
        
        if captions == nil {
            // Captions needs to be initiated only once. This will be called after cropping. At that time no need to initialise with empty values
            captions = [String](repeating: "", count: images.count)
        }
        
        previewImageView.image = images[selectedIndex]
        
        if !thumbnailCollectionView.isHidden {
            // Reload the thumbnail of the selected image as the thumbnail might be different after crop/ rotate
            // FIXME: this reloads when the view appears initially which is not needed
            thumbnailCollectionView.reloadItems(at: [IndexPath(row: selectedIndex, section: 0)])            
        }
    }
    
    /// Action when crop button is pressed
    @objc func cropClicked() {
        if let image = previewImageView.image {
            let cropViewController = CropViewController(croppingStyle: .default, image: image)
            cropViewController.toolbarPosition = .top
            cropViewController.showOnlyIcons = true
            cropViewController.delegate = self
            cropViewController.doneButtonColor = .white
            cropViewController.cancelButtonColor = .white
            cropViewController.toolBarTintColor = self.navigationController?.navigationBar.tintColor
            coordinator?.push(cropViewController, animated: true)
        }
    }
    
    
    /// Action when send is pressed
    /// - Parameter sender: the sender object
    @IBAction func sendPressed(_ sender: UIButton) {
        if !captionView.text.hasPrefix(captionViewPlaceholder) {
            captions?[selectedIndex] = captionView.text
        }
        coordinator?.finishedSelecting(with: images, and: captions)
        coordinator?.dismiss(animated: true)
    }
    
    /// Returns the text that is to be displayed as the placeholder text
    /// - Parameter caption: the current caption of the textField
    /// - Returns: the placeholder text
    func getCaptionText(for caption: String) -> String {
        if caption == "" {
            return captionViewPlaceholder
        }
        
        return caption
    }
    
    /// Adjusts the frame of bottomView when the keyboard shows
    /// - Parameter notification: notification object
    @objc func showKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let initialFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        // When the textField resigns responder keyboard's frame will be adjusted. Hence willShow notification will be fired.
        if initialFrame == endFrame {
            return
        }
        
        UIView.animate(withDuration: 0.2) {
            var originalFrame = self.bottomView.frame
            var bottomPadding: CGFloat = 0
            if #available(iOS 11.0, *) {
                bottomPadding = (UIApplication.shared.keyWindow?.safeAreaInsets.bottom)!
            }
            originalFrame.origin.y = originalFrame.origin.y - endFrame.size.height + bottomPadding - self.keyboardPadding
            self.bottomView.frame = originalFrame
        }
    }
    
    /// Adjusts the frame of bottomView when the keyboard shows
    /// - Parameter notification: notification object
   @objc func dismissKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.2) {
            var originalFrame = self.bottomView.frame
            var bottomPadding: CGFloat = 0
            if #available(iOS 11.0, *) {
                bottomPadding = (UIApplication.shared.keyWindow?.safeAreaInsets.bottom)!
            }
            originalFrame.origin.y = originalFrame.origin.y + endFrame.size.height - bottomPadding + self.keyboardPadding
            self.bottomView.frame = originalFrame
        }
    }

}

//MARK: - CollectionView delegates
extension PhotoPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        thumbnailCollectionView.register(UINib(nibName: "PhotoThumbnailCell", bundle: PhotoThumbnailCell.bundle), forCellWithReuseIdentifier: "PhotoThumbnailCell")
        let cell = thumbnailCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoThumbnailCell", for: indexPath) as! PhotoThumbnailCell
        cell.thumbnailImage.image = images?[indexPath.row]
//        cell.layer.borderColor = borderColor.cgColor
//        cell.layer.borderWidth = 1
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        previewImageView.image = images?[selectedIndex]
        if allowCaption {
            captionView.text = self.getCaptionText(for: captions?[selectedIndex] ?? "")
            captionView.textColor = .black
            if captionView.text == captionViewPlaceholder {
                captionView.textColor = placeholderTextColor
            }
        }
    }
}

//MARK: - TextView delegates
extension PhotoPreviewViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = .black
        if textView.text.hasPrefix(captionViewPlaceholder) {
            textView.text = ""

        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        captions?[selectedIndex] = textView.text
        
        if textView.text == "" {
            textView.text = captionViewPlaceholder
            textView.textColor = placeholderTextColor
        } else {
            textView.textColor = .black
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
}

//MARK: - CropViewController Delegate
extension PhotoPreviewViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        coordinator?.remove(cropViewController, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        images?[selectedIndex] = image
        coordinator?.remove(cropViewController, animated: true)
    }
}
