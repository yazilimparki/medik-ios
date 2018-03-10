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

class SpecialtyCell: UICollectionViewCell {
    @IBOutlet weak var imgCover: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnSubscribe: UIButton!
    var subscribing: Bool = false

    var category: MMediaCategory? {
        didSet {
            categoryDidSet()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imgCover.image = nil
        lblTitle.text = nil
    }

    func categoryDidSet() {
        if let coverURL = category?.cover?.url {
            if let url = NSURL(string: coverURL) {
                imgCover.hnk_setImageFromURL(url)
            }
        }

        lblTitle.text = category?.title
        updateButtons()
    }

    @IBAction func subscribeCategory(sender: UIButton) {
        if category!.subscribed && !subscribing {
            subscribing = true
            category!.subscribed = false
            updateButtons()

            APIClient.sharedClient.unsubscribeCategory(category!.categoryID!, completion: { (error) -> Void in
                self.subscribing = false
                if error != nil {
                    self.category!.subscribed = true
                    self.updateButtons()
                }
            })
        }
        else if !category!.subscribed && !subscribing {
            subscribing = true
            category!.subscribed = true
            updateButtons()

            APIClient.sharedClient.subscribeCategory(category!.categoryID!, completion: { (error) -> Void in
                self.subscribing = false
                if error != nil {
                    self.category!.subscribed = false
                    self.updateButtons()
                }
            })
        }
    }

    private func updateButtons() {
        if category!.subscribed {
            btnSubscribe.setTitle("Takibi bırak", forState: .Normal)
            btnSubscribe.layer.borderWidth = 0.0
            btnSubscribe.layer.borderColor = UIColor.clearColor().CGColor
            btnSubscribe.backgroundColor = UIColor.whiteColor()
            btnSubscribe.setTitleColor(UIColor.blackColor(), forState: .Normal)
        }
        else {
            btnSubscribe.setTitle("Takip et", forState: .Normal)
            btnSubscribe.layer.borderWidth = 1.0
            btnSubscribe.layer.borderColor = UIColor.whiteColor().CGColor
            btnSubscribe.backgroundColor = UIColor.clearColor()
            btnSubscribe.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        }
    }
}
