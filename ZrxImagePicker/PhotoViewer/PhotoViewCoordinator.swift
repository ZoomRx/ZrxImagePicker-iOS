//
//  PhotoViewCoordinator.swift
//  PhotoPreviewer
//
//  Created by Swaminathan on 05/02/21.
//  Copyright © 2021 ZoomRx. All rights reserved.
//

import Foundation
import UIKit

protocol Coordinator {
    func present(_ viewController: UIViewController, animated: Bool)
    func dismiss(animated: Bool)
    func push(_ viewController: UIViewController, animated: Bool)
    func remove(_ viewController: UIViewController, animated: Bool)
}

@objc public protocol PhotoViewCoordinatorDelegate {
    
    /// Called when the user has completed the image picking process
    /// - Parameters:
    ///   - images: Array of UIImages selected by the user
    ///   - captions: Array of captions given by the user for each image
    ///   - source: the PhotoViewSource
    /// - Note: When the user cancels the selection process this method will be called with nil values for images and captions
    func didFinishSelection(images: [UIImage]?, captions: [String]?, source: PhotoViewSource)
    
    /// Called if permission is not given by the user for that module
    /// - Parameter source: the PhotoViewSource for which the permission is not given
    @objc optional func permissionDenied(for source: PhotoViewSource)
}

@objc public enum PhotoViewSource: Int {
    case camera, gallery
}

public class PhotoViewCoordinator: Coordinator {
    
    //MARK: - Properties
    var presentingViewController: UIViewController
    var presentedViewController: UIViewController?
    var model: PhotoViewModel
    public var delegate: PhotoViewCoordinatorDelegate?
    var source: PhotoViewSource!
    
    //MARK: - Methods
    public init(from vc: UIViewController, settings: [String:Any]? = nil) {
        presentingViewController = vc
        model = PhotoViewModel()
        model.coordinator = self
        model.settings = settings
    }
    
    /// Starts the coordinator for the passed source
    /// - Parameter source: The PhotoViewSource
    public func start(source: PhotoViewSource) {
        self.source = source
        switch source {
        case .camera:
            model.takePhoto()
        case .gallery:
            model.selectFromGallery()
        }
    }
    
    /// Called when the user has completed the image picking process
    /// - Parameters:
    ///   - images: Array of UIImages selected by the user
    ///   - captions: Array of captions given by the user for each image
    /// - Note: When the user cancels the selection process this method will be called with nil values for images and captions
    func finishedSelecting(with images: [UIImage]?, and captions: [String]? = nil) {
        delegate?.didFinishSelection(images: images, captions: captions, source: source)
    }
    
    /// Called if permission is not given by the user for that module
    func permissionDenied() {
        delegate?.permissionDenied?(for: self.source)
    }
    
    
    /// Pushes the viewController to navigation stack if the presentedViewController is a UINavigationController. Else it will create UINavigationController and then pushes it
    /// - Parameters:
    ///   - viewController: the viewController to push
    ///   - animated: when animation is required
    func push(_ viewController: UIViewController, animated: Bool) {
        if let navController = presentedViewController as? UINavigationController  {
            navController.pushViewController(viewController, animated: animated)
        } else {
            let navController = UINavigationController()
            navController.pushViewController(viewController, animated: animated)
            self.dismiss(animated: animated)
            presentingViewController.present(navController, animated: animated, completion: nil)
            presentedViewController = navController
        }
    }
    
    /// Removes the passed viewController. Pops if the viewController is on top of the stack else it is removed manually from the array using index
    /// - Parameters:
    ///   - viewController: the viewController to remove
    ///   - animated: when animation is required
    func remove(_ viewController: UIViewController, animated: Bool) {
        guard let navController = presentedViewController as? UINavigationController else {
            return
        }
        
        // If the ViewController to be dismissed is top VC the it can be popped
        guard navController.topViewController != viewController else {
            navController.popViewController(animated: animated)
            return
        }
        
        // If it is not topViewcontroller then it has to removed from the array manually using index
        if let index = navController.viewControllers.lastIndex(of: viewController) {
            navController.viewControllers.remove(at: index)
        }
    }
    
    /// Presents the passed viewController
    /// - Parameters:
    ///   - viewController: the viewController to remove
    ///   - animated: when animation is required
    func present(_ viewController: UIViewController, animated: Bool) {
        viewController.modalPresentationStyle = .fullScreen
        presentedViewController?.dismiss(animated: false, completion: nil)
        presentingViewController.present(viewController, animated: animated)
        presentedViewController = viewController
    }
    
    /// Dismisses the presentedViewController
    /// - Parameters:
    ///   - animated: when animation is required
    func dismiss(animated: Bool) {
        presentedViewController?.dismiss(animated: animated, completion: nil)
        presentedViewController = nil
    }
}
