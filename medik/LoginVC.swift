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
import KVNProgress
import TextFieldEffects

class LoginVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var txtUsername: HoshiTextField!
    @IBOutlet weak var txtPassword: HoshiTextField!
    var alert: SweetAlert = SweetAlert()

    override func viewDidLoad() {
        super.viewDidLoad()

        APIClient.sharedClient.getAccessTokenOfApp()
    }

    // MARK: - Textfield delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == txtUsername {
            txtPassword.becomeFirstResponder()
        }
        else if textField == txtPassword {
            loginPressed()
        }

        return true
    }

    // MARK: - Actions
    @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {}

    @IBAction func loginPressed(sender: AnyObject? = nil) {
        if (txtUsername.text == "" || count(txtUsername.text) < Constants.API.UsernameMinLength) {
            self.txtUsername.becomeFirstResponder()
        }
        else if (txtPassword.text == "" || count(txtPassword.text) < Constants.API.PasswordMinLength) {
            self.txtPassword.becomeFirstResponder()
        }
        else {
            txtUsername.resignFirstResponder()
            txtPassword.resignFirstResponder()
            login()
        }
    }

    // MARK: - Network operations
    func login() {
        KVNProgress.show()

        APIClient.sharedClient.login(txtUsername.text, password: txtPassword.text) { (error) -> Void in
            if error != nil {
                KVNProgress.dismissWithCompletion({ () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.alert.showAlert("Uyarı", subTitle: "Kullanıcı adı veya parola geçersiz.", style: AlertStyle.Warning)
                        NSTimer.scheduledTimerWithTimeInterval(2.5, target: self.alert, selector: "closeAlert:", userInfo: nil, repeats: false)
                    })
                })
            }
            else {
                KVNProgress.dismissWithCompletion({ () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.performSegueWithIdentifier("backToRoot", sender: nil)
                    })
                })
            }
        }
    }
}
