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

class MediaZoomVC: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var media: MMedia!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        loadMedia()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        imageView.image = nil
        loadMedia()
    }

    // MARK: - Scroll view delegate

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // MARK: - Button actions

    @IBAction func dismiss(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Network operations

    func loadMedia() {
        if let photoURL = media?.images?.first?.fullUrl {
            if let url = NSURL(string: photoURL) {
                imageView.hnk_setImageFromURL(url)
            }
        }
    }
}
