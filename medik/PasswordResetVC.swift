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

class PasswordResetVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var txtEmail: UITextField!

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        txtEmail.becomeFirstResponder()
    }

    // MARK: - TextField delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if txtEmail.text.isValidEmail() {
            sendPressed(nil)
            return true
        }
        else {
            return false
        }
    }

    // MARK: - Actions
    @IBAction func sendPressed(sender: AnyObject?) {
        KVNProgress.show()

        APIClient.sharedClient.passwordReset(txtEmail.text, completion: { (error) -> Void in
            if error == nil {
                KVNProgress.dismiss()
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            else {
                KVNProgress.showErrorWithStatus("E-posta adresinizi kontrol edin.")
            }
        })
    }

    @IBAction func dismiss(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
