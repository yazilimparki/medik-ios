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
import Locksmith
import PermissionScope

class RootVC: UITabBarController, UITabBarControllerDelegate {
    let photoPermissions = PermissionScope()
    let notificationPermissions = PermissionScope()
    let tabBarHeight: CGFloat = 40.0
    var loadingView: UIView?
    var alert: SweetAlert = SweetAlert()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        // camera tab bar item background
        let itemIndex: CGFloat = 2
        let bgColor = UIColor(red: 165/255.0, green: 48/255.0, blue: 58/255.0, alpha: 1.0)
        let itemWidth = tabBar.frame.width / CGFloat(tabBar.items!.count)
        let bgView = UIView(frame: CGRectMake(itemWidth * itemIndex, 0, itemWidth, tabBar.frame.height))
        bgView.backgroundColor = bgColor
        tabBar.insertSubview(bgView, atIndex: 0)

        // Loading view
        loadingView = (UINib(nibName: "LaunchScreen", bundle: NSBundle.mainBundle()).instantiateWithOwner(nil, options: nil)[0] as! UIView)
        loadingView!.frame = view.frame
        view.addSubview(loadingView!)
        view.bringSubviewToFront(loadingView!)

        // Permission scope
        photoPermissions.headerLabel.text = "Selam"
        photoPermissions.bodyLabel.text = "Başlamadan önce bize birkaç konuda izin vermelisiniz."
        photoPermissions.closeButton.setTitle("Kapat", forState: .Normal)
        photoPermissions.addPermission(PermissionConfig(type: .Photos, demands: .Required, message: "Önceden çektiğiniz fotoğraflar için."))
        photoPermissions.addPermission(PermissionConfig(type: .Camera, demands: .Required, message: "Kamerayla fotoğraf çekebilmeniz için."))
        notificationPermissions.headerLabel.text = "Selam"
        notificationPermissions.bodyLabel.text = "Takipçi ve yorumlar için size bildirim göndermek istiyoruz."
        notificationPermissions.closeButton.setTitle("Kapat", forState: .Normal)
        notificationPermissions.addPermission(PermissionConfig(type: .Notifications, demands: .Required, message: "Bildirimler için izin vermelisiniz."))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if APIClient.sharedClient.accessTokenExists() {
            getCurrentUser()
        }
        else {
            if let username = NSUserDefaults.standardUserDefaults().objectForKey(Constants.UserDefaults.UserKey) as? String {
                let (dictionary, error) = Locksmith.loadDataForUserAccount(username, inService: Constants.Keychain.ServiceName)
                if error == nil {
                    if let password = dictionary?.objectForKey("password") as? String {
                        self.login(username, password: password)
                    }
                }
            }
            else {
                self.performSegueWithIdentifier("showLogin", sender: nil)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.loadingView?.removeFromSuperview()
                })
            }
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentLogin:", name: Constants.Notification.Logout, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loggedOut:", name: Constants.Notification.Logout, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setCurrentUser:", name: Constants.Notification.GotCurrentUser, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.Logout, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.GotCurrentUser, object: nil)
    }

    override func viewWillLayoutSubviews() {
        var tabFrame = self.tabBar.frame
        tabFrame.size.height = tabBarHeight
        tabFrame.origin.y = self.view.frame.size.height - tabBarHeight
        self.tabBar.frame = tabFrame
    }

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController.restorationIdentifier == "TabCameraPlaceholder" {
            if let user = APIClient.sharedClient.currentUser {
                if !user.canPost {
                    self.alert.showAlert("Uyarı", subTitle: "Sadece sağlık profesyonelleri vaka paylaşımında bulunabilir.", style: AlertStyle.Warning)
                    NSTimer.scheduledTimerWithTimeInterval(2.5, target: self.alert, selector: "closeAlert:", userInfo: nil, repeats: false)
                    return false
                }
            }
            
            if photoPermissions.statusCamera() == .Authorized && photoPermissions.statusPhotos() == .Authorized {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("CameraNavVC") as! UINavigationController
                presentViewController(vc, animated: true, completion: nil)
            }
            else {
                photoPermissions.show(authChange: { (finished, results) -> Void in
                    println("Request was finished with results \(results)")
                    }, cancelled: { (results) -> Void in
                        println("Request was cancelled with results \(results)")
                })
                photoPermissions.disabledOrDeniedClosure = { (results) -> Void in
                    println("Request was denied or disabled with results \(results)")
                }
            }
            return false
        }
        if tabBarController.selectedViewController == viewController {
            if let navController = viewController as? UINavigationController {
                if navController.visibleViewController == navController.topViewController {
                    // NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.ScrollToTop, object: nil)
                }
                else {
                    navController.popToRootViewControllerAnimated(true)
                }
            }
        }

        return true
    }

    func presentLogin(notification: NSNotification?) {
        performSegueWithIdentifier("showLogin", sender: nil)
    }

    func loggedOut(notification: NSNotification?) {
        selectedIndex = 0
    }

    func loggedInAndGotCurrentUser() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            if self.notificationPermissions.statusNotifications() != .Authorized {
                self.notificationPermissions.show()
            }
        })
    }

    @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {}

    func login(username: String, password: String) {
        APIClient.sharedClient.login(username, password: password) { (error) -> Void in
            if error != nil {
                self.performSegueWithIdentifier("showLogin", sender: nil)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.loadingView?.removeFromSuperview()
                })
            }
            else {
                self.getCurrentUser()
            }
        }
    }

    func getCurrentUser() {
        APIClient.sharedClient.getCurrentUser { (responseObject, error) -> () in
            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                self.loadingView?.removeFromSuperview()
                self.loggedInAndGotCurrentUser()
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.Login, object: nil)
            }
        }
    }

    func setCurrentUser(notification: NSNotification) {
        if let viewControllers = self.viewControllers {
            for vc in viewControllers {
                if vc.isKindOfClass(UINavigationController) {
                    if vc.topViewController!.isKindOfClass(ProfileVC) {
                        (vc.topViewController as! ProfileVC).user = APIClient.sharedClient.currentUser
                    }
                }
            }
        }
    }
}
