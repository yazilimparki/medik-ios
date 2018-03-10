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

class SignupVC: UIViewController, UITextFieldDelegate, SignupSpecialtySelectionDelegate {
    @IBOutlet weak var txtUsername: HoshiTextField!
    @IBOutlet weak var txtEmail: HoshiTextField!
    @IBOutlet weak var txtPassword: HoshiTextField!
    @IBOutlet weak var btnSpecialty: UIButton!
    var alert: SweetAlert = SweetAlert()
    var selectedSpecialty: MSpecialty?

    override func viewDidLoad() {
        super.viewDidLoad()

        if APIClient.sharedClient.accessTokenExists() {
            APIClient.sharedClient.getAccessTokenOfApp()
        }
    }

    // MARK: - Textfield delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == txtUsername {
            txtEmail.becomeFirstResponder()
        }
        else if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }
        else if textField == txtPassword {
            textField.resignFirstResponder()
            performSegueWithIdentifier("showSpecialtySelection", sender: textField)
        }
        else {
            signupPressed()
        }

        return true
    }

    // MARK: - Actions

    @IBAction func signupPressed(sender: AnyObject? = nil) {
        if (txtUsername.text == "" || count(txtUsername.text) < Constants.API.UsernameMinLength) {
            self.txtUsername.becomeFirstResponder()
        }
        else if (txtEmail.text == "" || !txtEmail.text.isValidEmail()) {
            self.txtEmail.becomeFirstResponder()
        }
        else if (txtPassword.text == "" || count(txtPassword.text) < Constants.API.PasswordMinLength) {
            self.txtPassword.becomeFirstResponder()
        }
        else if selectedSpecialty == nil {
            performSegueWithIdentifier("showSpecialtySelection", sender: btnSpecialty)
        }
        else {
            txtUsername.resignFirstResponder()
            txtEmail.resignFirstResponder()
            txtPassword.resignFirstResponder()
            signup()
        }
    }

    @IBAction func specialtyPressed(sender: UIButton) {
        performSegueWithIdentifier("showSpecialtySelection", sender: sender)
    }

    // MARK: - Storyboard segues
    func backToLoginWithCredentials() {
        self.performSegueWithIdentifier("unwindToLoginWithCredentials", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "unwindToLoginWithCredentials" {
            if let destVC = segue.destinationViewController as? LoginVC {
                destVC.txtUsername.becomeFirstResponder()
                destVC.txtUsername.text = txtUsername.text
                destVC.txtUsername.resignFirstResponder()
                destVC.txtPassword.becomeFirstResponder()
                destVC.txtPassword.text = txtPassword.text
                destVC.txtPassword.resignFirstResponder()
                destVC.loginPressed()
            }

            txtUsername.text = ""
            txtEmail.text = ""
            txtPassword.text = ""
        }
        else if segue.identifier == "showSpecialtySelection" {
            if let destVC = segue.destinationViewController as? UINavigationController {
                if let specialtySelectVC = destVC.topViewController as? SignupSpecialtySelectVC {
                    specialtySelectVC.delegate = self
                }
            }
        }
    }

    // MARK: - Signup Specialty Selection Delegate

    func specialtySelected(specialty: MSpecialty) {
        selectedSpecialty = specialty
        btnSpecialty.setTitle(specialty.title, forState: .Normal)
    }

    // MARK: - Network operations

    func signup() {
        KVNProgress.show()

        APIClient.sharedClient.signup(txtUsername.text, email: txtEmail.text, password: txtPassword.text, specialtyID: selectedSpecialty!.specialtyID!) { (fieldErrors, error) -> Void in
            if fieldErrors != nil {
                var firstError = fieldErrors?.firstObject as! NSDictionary
                var errorMessage = ""

                switch firstError.valueForKey("field") as! String {
                case "username":
                    errorMessage = "Kullanıcı adı daha önce kullanılmış."
                case "email":
                    errorMessage = "E-posta adresi daha önce kullanılmış."
                default:
                    println("this shouldn't be called")
                }

                KVNProgress.dismissWithCompletion({ () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.alert.showAlert("Uyarı", subTitle: errorMessage, style: AlertStyle.Warning)
                        NSTimer.scheduledTimerWithTimeInterval(2.5, target: self.alert, selector: "closeAlert:", userInfo: nil, repeats: false)
                    })
                })
            }
            else if error != nil {
                KVNProgress.dismissWithCompletion({ () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.alert.showAlert("Uyarı", subTitle: "Medik'te sorun yaşıyoruz, kısa süre sonra tekrar deneyin.", style: AlertStyle.Warning)
                        NSTimer.scheduledTimerWithTimeInterval(2.5, target: self.alert, selector: "closeAlert:", userInfo: nil, repeats: false)
                    })
                })
            }
            else {
                KVNProgress.dismissWithCompletion({ () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.alert.showAlert("Tebrikler", subTitle: "Hesabınız oluşturuldu.", style: AlertStyle.Success)
                        NSTimer.scheduledTimerWithTimeInterval(2.5, target: self.alert, selector: "closeAlert:", userInfo: nil, repeats: false)
                        NSTimer.scheduledTimerWithTimeInterval(2.6, target: self, selector: "backToLoginWithCredentials", userInfo: nil, repeats: false)
                    })
                })
            }
        }
    }
}
