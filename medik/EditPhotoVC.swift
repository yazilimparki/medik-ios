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
import ImageIO
import Haneke
import Alamofire
import KVNProgress

class EditPhotoVC: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, EditPhotoCategorySelectionDelegate {
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var txtCaption: UITextView!
    @IBOutlet weak var btnCategory: UIButton!
    @IBOutlet weak var btnFaceBlocking: UIButton!
    @IBOutlet weak var btnClearWhiteboard: UIButton!
    @IBOutlet weak var imgPencil: UIImageView!
    var imageCaptured: UIImage!
    // todo: Face blocking is buggy at the moment.
    // var faceBlockView = UIView()
    var whiteBoardView = UIImageView()
    var whiteBoardLastPoint = CGPointZero
    var whiteBoardSwiped = false
    var whiteBoardEmpty = true
    // var faceBlockingEnabled = true
    // var faceCount: Int = 0
    var selectedCategory: MMediaCategory?
    var didAppearOnce: Bool = false
    var drawingMode: Bool = false
    let captionPlaceholder = "Vaka hakkında açıklama."
    let captionPlaceholderColor = UIColor.lightGrayColor()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Düzenle"
        txtCaption.text = captionPlaceholder
        txtCaption.textColor = captionPlaceholderColor
        
        let imgPencilGC = UITapGestureRecognizer(target: self, action: "toggleDrawingMode:")
        imgPencilGC.delegate = self
        imgPencilGC.numberOfTapsRequired = 1
        
        if let recognizers = imgPencil.gestureRecognizers {
            for recognizer in recognizers {
                imgPencil.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
            }
        }
        
        imgPencil.addGestureRecognizer(imgPencilGC)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
        navigationItem.leftBarButtonItem = backButton
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)

        if let user = APIClient.sharedClient.currentUser {
            if let url = NSURL(string: user.avatarURL!) {
                imgAvatar.hnk_setImageFromURL(url)
            }
        }

        imgPhoto.image = imageCaptured
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !didAppearOnce {
            // faceBlockView.frame = imgPhoto.frame
            whiteBoardView.frame = imgPhoto.frame
            // view.addSubview(faceBlockView)
            view.addSubview(whiteBoardView)
            // setupFaceBlockView()
            didAppearOnce = true
        }
    }

    // MARK: - UIResponder methods

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if drawingMode {
            whiteBoardSwiped = false
            if let touch = touches.first as? UITouch {
                whiteBoardLastPoint = touch.locationInView(whiteBoardView)
            }
        }
    }

    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(whiteBoardView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        whiteBoardView.image?.drawInRect(CGRect(x: 0, y: 0, width: whiteBoardView.frame.size.width, height: whiteBoardView.frame.size.height))
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        CGContextSetLineCap(context, kCGLineCapRound)
        CGContextSetLineWidth(context, 8.0)
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0)
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        CGContextStrokePath(context)
        whiteBoardView.image = UIGraphicsGetImageFromCurrentImageContext()
        whiteBoardView.alpha = 1.0
        UIGraphicsEndImageContext()
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if drawingMode {
            whiteBoardSwiped = true
            if let touch = touches.first as? UITouch {
                let currentPoint = touch.locationInView(whiteBoardView)
                drawLineFrom(whiteBoardLastPoint, toPoint: currentPoint)
                whiteBoardLastPoint = currentPoint
            }
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if drawingMode {
            btnClearWhiteboard.hidden = false

            if !whiteBoardSwiped {
                drawLineFrom(whiteBoardLastPoint, toPoint: whiteBoardLastPoint)
            }
        }
    }

    // MARK: - UITextView delegate

    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == captionPlaceholderColor {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }

    func textViewDidChange(textView: UITextView) {
        updateSendButton()
    }

    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = captionPlaceholder
            textView.textColor = captionPlaceholderColor
        }
        updateSendButton()
    }

    // MARK: - Category Selection delegate

    func categorySelected(category: MMediaCategory) {
        selectedCategory = category
        btnCategory.setTitle(category.title, forState: .Normal)
        btnCategory.setTitleColor(UIColor.blackColor(), forState: .Normal)
        updateSendButton()
    }

    // MARK: - Button actions

    @IBAction func blockFacesToggle(sender: UIButton) {
        /*
        if faceBlockingEnabled {
            faceBlockView.hidden = true
            btnFaceBlocking.setImage(UIImage(named: "btn-face-blocking-off"), forState: .Normal)
            faceBlockingEnabled = false
        }
        else {
            faceBlockView.hidden = false
            btnFaceBlocking.setImage(UIImage(named: "btn-face-blocking"), forState: .Normal)
            faceBlockingEnabled = true
        }
        */
    }
    
    func toggleDrawingMode(sender: UITapGestureRecognizer) {
        if drawingMode {
            drawingMode = false
            imgPencil.image = UIImage(named: "icon-draw-pencil-off")
        }
        else {
            drawingMode = true
            imgPencil.image = UIImage(named: "icon-draw-pencil")
        }
        
        println("tap")
        println(drawingMode)
    }

    @IBAction func clearWhiteBoard(sender: UIButton) {
        whiteBoardView.image = nil
        btnClearWhiteboard.hidden = true
        drawingMode = false
    }

    @IBAction func chooseCategory(sender: UIButton) {
        performSegueWithIdentifier("showCategorySelection", sender: sender)
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCategorySelection" {
            if let navVC = segue.destinationViewController as? UINavigationController {
                if let destVC = navVC.topViewController as? EditPhotoCategorySelectionVC {
                    destVC.delegate = self
                }
            }
        }
    }

    // MARK: - Send button

    func updateSendButton() {
        if (txtCaption.text != captionPlaceholder && selectedCategory != nil) {
            let sendButton = UIBarButtonItem(title: "Gönder", style: .Plain, target: self, action: "sendPost:")
            navigationItem.rightBarButtonItem = sendButton
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    func sendPost(sender: AnyObject?) {
        var origin: CGPoint!
        let imgSize = min(imageCaptured.size.width, imageCaptured.size.height)
        let imgRect = CGRectMake(0, 0, imgSize, imgSize)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imgSize, height: imgSize), false, 0)
        let context = UIGraphicsGetCurrentContext()

        if (imageCaptured.size.width > imageCaptured.size.height) {
            origin = CGPointMake(-(imageCaptured.size.width - imageCaptured.size.height) / 2.0, 0)
        }
        else {
            origin = CGPointMake(0, -(imageCaptured.size.height - imageCaptured.size.width) / 2.0)
        }

        imgPhoto.image?.drawAtPoint(origin)
        // faceBlockView.drawViewHierarchyInRect(imgRect, afterScreenUpdates: false)
        whiteBoardView.drawViewHierarchyInRect(imgRect, afterScreenUpdates: false)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let imageData = UIImageJPEGRepresentation(finalImage, 0.9)
        let urlString = "\(Constants.API.BaseURL)/\(Constants.API.MediaFilesURL)"
        let urlRequest = APIClient.sharedClient.urlRequestWithComponents(urlString, imageData: imageData)

        txtCaption.resignFirstResponder()
        KVNProgress.showProgress(0, status: "Gönderiliyor")
        Alamofire.upload(urlRequest.0, urlRequest.1)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                KVNProgress.updateProgress(CGFloat(totalBytesWritten)/CGFloat(totalBytesExpectedToWrite), animated: true)
                return
            }
            .responseJSON { (request, response, data, error) in
                if error == nil {
                    if let responseDict = data as? NSDictionary {
                        if let fileID = responseDict.valueForKey("id") as? Int {
                            self.createMedia(fileID)
                        }
                    }
                }
                else {
                    KVNProgress.showErrorWithStatus("Fotoğraf gönderilirken sorun oluştu")
                }
        }
    }
    
    func createMedia(fileID: Int) {
        let parameters: [String: AnyObject] = [
            "caption": txtCaption.text,
            "categories": [selectedCategory!.categoryID!],
            "images": [fileID]
        ]

        KVNProgress.showWithStatus("Gönderiliyor")
        APIClient.sharedClient.createMedia(parameters, completion: { (error) -> Void in
            if error == nil {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UploadingSucceed, object: nil)
                KVNProgress.dismissWithCompletion({ () -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
            else {
                KVNProgress.showErrorWithStatus("Fotoğraf gönderilirken sorun oluştu")
            }
        })
    }

    // MARK: - Face blocking
    /*
    private func setupFaceBlockView() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let image = CIImage(CGImage: self.imgPhoto.image!.CGImage) {
                // Core Image Detector
                var detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)
                // Features in image
                var features = detector.featuresInImage(image, options: nil) as! [CIFeature]
                // CoreImage to UIKit coordinates transformer
                var transform = CGAffineTransformMakeScale(1, -1)
                transform = CGAffineTransformTranslate(transform, 0, -self.imgPhoto.image!.size.height)
                // Image aspect ratio relative to UIImageView
                var xRatio = self.imgPhoto.frame.size.width / self.imgPhoto.image!.size.width
                var yRatio = self.imgPhoto.frame.size.height / self.imgPhoto.image!.size.height
                var aspectFitRatio = min(xRatio, yRatio)

                for feature in features {
                    if let feature = feature as? CIFaceFeature {
                        self.faceCount++

                        // Flipped coordinates of face
                        var rect = CGRectApplyAffineTransform(feature.bounds, transform)
                        // Aspect ratio applied coordinates of face
                        let scale = UIScreen.mainScreen().scale
                        let newX = rect.origin.x // * aspectFitRatio
                        let newY = rect.origin.y // * aspectFitRatio
                        let newW = rect.width * aspectFitRatio * scale
                        let newH = rect.height * aspectFitRatio * scale
                        // Blocking view
                        var view = UIView(frame: CGRectMake(newX, newY, newW, newH))
                        view.backgroundColor = UIColor.blackColor()
                        dispatch_async(dispatch_get_main_queue()) {
                            self.faceBlockView.addSubview(view)
                        }
                    }
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                if self.faceCount == 0 {
                    self.faceBlockView.hidden = true
                    self.btnFaceBlocking.hidden = true
                }
                else {
                    self.faceBlockView.hidden = false
                    self.btnFaceBlocking.hidden = false
                }
            }
        }
    }
    */

}
