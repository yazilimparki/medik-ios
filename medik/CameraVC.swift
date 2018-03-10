//
// Medik (r) Photo Sharing Platform for Health Professionals (http://medik.com)
// Copyright (c) Yazılım Parkı Bilişim Teknolojileri D.O.R.P. Ltd. Şti. (http://yazilimparki.com.tr)
//
// Licensed under The MIT License (https://opensource.org/licenses/mit-license.php)
// For full copyright and license information, please see the LICENSE.txt file.
// Redistributions of files must retain the above copyright notice.
//
// Medik (r) is registered trademark of Yazılım Parkı Bilişim Teknolojileri D.O.R.P. Ltd. Şti.
//

import UIKit
import Photos
import FastttCamera

class CameraVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FastttCameraDelegate {
    @IBOutlet weak var cameraPlaceholderView: UIView!
    @IBOutlet weak var btnImagePicker: UIButton!
    @IBOutlet weak var btnCamera: UIButton!
    @IBOutlet weak var btnFlash: UIButton!
    var fastttCamera = FastttCamera()

    override func viewDidLoad() {
        super.viewDidLoad()
        fastttCamera.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        fastttAddChildViewController(fastttCamera)
        fastttCamera.view.frame = cameraPlaceholderView.frame
        loadLatestImageFromLibrary()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    }

    // MARK: - FastttCamera delegate

    func cameraController(cameraController: FastttCameraInterface!, didFinishNormalizingCapturedImage capturedImage: FastttCapturedImage!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("EditPhotoVC") as! EditPhotoVC
        vc.imageCaptured = capturedImage.fullImage
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UIImagePickerController delegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("EditPhotoVC") as! EditPhotoVC
        vc.imageCaptured = image
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }

    // MARK: - UINavigationController delegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)

        if viewController != navigationController.viewControllers.first as! UIViewController {
            let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: navigationController, action: "popViewControllerAnimated:")
            navigationController.topViewController.navigationItem.leftBarButtonItem = backButton
        }
    }

    // MARK: - Button actions

    @IBAction func showImagePicker() {
        var imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .PhotoLibrary
        imagePickerVC.delegate = self
        imagePickerVC.allowsEditing = true
        presentViewController(imagePickerVC, animated: true, completion: nil)
    }

    @IBAction func changeFlashPreference() {
        if FastttCamera.isFlashAvailableForCameraDevice(fastttCamera.cameraDevice) {
            if fastttCamera.cameraFlashMode == .On {
                fastttCamera.cameraFlashMode = .Auto
            }
            else if fastttCamera.cameraFlashMode == .Auto {
                fastttCamera.cameraFlashMode = .Off
            }
            else if fastttCamera.cameraFlashMode == .Off {
                fastttCamera.cameraFlashMode = .On
            }
            updateFlashButtonImage()
        }
    }

    @IBAction func changeCameraPreference() {
        if FastttCamera.isCameraDeviceAvailable(fastttCamera.cameraDevice) {
            if fastttCamera.cameraDevice == .Front {
                fastttCamera.cameraDevice = .Rear
            }
            else if fastttCamera.cameraDevice == .Rear {
                fastttCamera.cameraDevice = .Front
            }
        }
    }

    @IBAction func takePhoto() {
        fastttCamera.takePicture()
    }

    @IBAction func dismissThis() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Button visual updates

    private func updateFlashButtonImage() {
        if fastttCamera.cameraFlashMode == .On {
            btnFlash.setImage(UIImage(named: "btn-flash-on"), forState: .Normal)
        }
        else if fastttCamera.cameraFlashMode == .Auto {
            btnFlash.setImage(UIImage(named: "btn-flash-auto"), forState: .Normal)
        }
        else if fastttCamera.cameraFlashMode == .Off {
            btnFlash.setImage(UIImage(named: "btn-flash-off"), forState: .Normal)
        }
    }

    private func loadLatestImageFromLibrary() {
        var fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions)
        if let lastAsset = fetchResult.lastObject as? PHAsset {
            var imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.version = .Current
            imageRequestOptions.deliveryMode = .FastFormat
            imageRequestOptions.resizeMode = .Fast
            imageRequestOptions.synchronous = true

            PHImageManager.defaultManager().requestImageForAsset(lastAsset, targetSize: btnImagePicker.bounds.size, contentMode: .AspectFill, options: imageRequestOptions, resultHandler: { (image, _) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.btnImagePicker.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                    self.btnImagePicker.layer.masksToBounds = true
                    self.btnImagePicker.layer.cornerRadius = 6
                    self.btnImagePicker.setImage(image, forState: .Normal)
                })
            })
        }
    }
}
