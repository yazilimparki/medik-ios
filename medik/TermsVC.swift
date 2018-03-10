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

class TermsVC: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var isModal = true

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isModal {
            let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
            navigationItem.leftBarButtonItem = backButton
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "modal-dismiss"), style: .Plain, target: self, action: "dismissThis")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let url = NSURL(string: Constants.API.TermsURL) {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        }
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        spinner.stopAnimating()
    }

    func dismissThis() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
