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

class ReportVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var txtReason: UITextField!
    var user: MUser?
    var media: MMedia?
    var comment: MMediaComment?

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        txtReason.becomeFirstResponder()
    }

    // MARK: - TextField delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (count(txtReason.text) < 5) {
            KVNProgress.showErrorWithStatus("Belirttiğiniz sebep çok kısa.")
            return false
        }
        else {
            sendPressed(nil)
            return true
        }
    }

    // MARK: - Actions
    @IBAction func sendPressed(sender: AnyObject?) {
        KVNProgress.show()

        if let user = user {
            APIClient.sharedClient.reportUser(user.userID!, reason: txtReason.text, completion: { (error) -> Void in
                if error != nil {
                    KVNProgress.showErrorWithStatus("Gönderilemedi")
                }
                else {
                    KVNProgress.dismiss()
                    self.dismiss(nil)
                }
            })
        }
        else if let media = media {
            APIClient.sharedClient.reportMedia(media.mediaID!, reason: txtReason.text, completion: { (error) -> Void in
                if error != nil {
                    KVNProgress.showErrorWithStatus("Gönderilemedi")
                }
                else {
                    KVNProgress.dismiss()
                    self.dismiss(nil)
                }
            })
        }
        else if let comment = comment {
            APIClient.sharedClient.reportComment(comment.commentID!, reason: txtReason.text, completion: { (error) -> Void in
                if error != nil {
                    KVNProgress.showErrorWithStatus("Gönderilemedi")
                }
                else {
                    KVNProgress.dismiss()
                    self.dismiss(nil)
                }
            })
        }
    }

    @IBAction func dismiss(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
