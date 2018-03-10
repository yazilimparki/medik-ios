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
import DateTools

protocol NotificationCellDelegate {
    func profileTappedForNotification(notification: MNotification)
    func mediaTappedForNotification(notification: MNotification)
}

class NotificationCell: UITableViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var imgMedia: UIImageView!
    @IBOutlet weak var btnFollow: UIButton!
    @IBOutlet weak var lblText: UILabel!
    var delegate: NotificationCellDelegate?
    private var following: Bool = false

    var notification: MNotification? {
        didSet {
            notificationDidSet()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imgUserAvatar.image = nil
        imgMedia.image = nil
        btnFollow.hidden = true
        lblText.text = nil
    }

    func notificationDidSet() {
        if let avatarURL = notification!.user?.avatarURL {
            if let url = NSURL(string: avatarURL) {
                imgUserAvatar.hnk_setImageFromURL(url)
            }
        }

        var avatarTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "profileTapped:")
        avatarTapGestureRecognizer.delegate = self
        avatarTapGestureRecognizer.numberOfTapsRequired = 1
        if let recognizers = imgUserAvatar.gestureRecognizers {
            for recognizer in recognizers {
                imgUserAvatar.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
            }
        }
        imgUserAvatar.addGestureRecognizer(avatarTapGestureRecognizer)

        if notification!.notificationType == "follow" {
            btnFollow.hidden = false
            imgMedia.hidden = true
        }
        else {
            btnFollow.hidden = true
            imgMedia.hidden = false

            if let imgURL = notification!.objectImageURL {
                if let url = NSURL(string: imgURL) {
                    imgMedia.hnk_setImageFromURL(url)
                }
            }

            var imgMediaGestureRecognizer = UITapGestureRecognizer(target: self, action: "mediaTapped:")
            imgMediaGestureRecognizer.delegate = self
            imgMediaGestureRecognizer.numberOfTapsRequired = 1
            if let recognizers = imgMedia.gestureRecognizers {
                for recognizer in recognizers {
                    imgMedia.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
                }
            }
            imgMedia.addGestureRecognizer(imgMediaGestureRecognizer)
        }

        var messageText = NSMutableAttributedString()
        messageText.appendAttributedString(NSAttributedString(string: notification!.user!.screenName!, attributes: [NSFontAttributeName: UIFont(name: "Roboto-Bold", size: 14)!]))

        if notification!.notificationType! == "favorite" {
            messageText.appendAttributedString(NSAttributedString(string: " gönderini favorilerine ekledi.", attributes: nil))
        }
        else if notification!.notificationType! == "comment" {
            messageText.appendAttributedString(NSAttributedString(string: " gönderine yorum yaptı.", attributes: nil))
        }
        else if notification!.notificationType! == "follow" {
            messageText.appendAttributedString(NSAttributedString(string: " seni takip etmeye başladı.", attributes: nil))
        }

        // messageText.appendAttributedString(NSAttributedString(string: notification!.createdAt!.shortTimeAgoSinceNow(), attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()]))

        lblText.attributedText = messageText
        updateButtonFollow()
    }

    func profileTapped(sender: UITapGestureRecognizer) {
        delegate?.profileTappedForNotification(notification!)
    }

    func mediaTapped(sender: UITapGestureRecognizer) {
        delegate?.mediaTappedForNotification(notification!)
    }

    @IBAction func followUser(sender: UIButton) {
        if following { return }

        following = true
        if notification!.user!.following {
            notification!.user!.following = false
            updateButtonFollow()
            APIClient.sharedClient.userUnfollow(notification!.user!.userID!, completion: { (error) -> Void in
                self.following = false
                if error != nil {
                    self.notification!.user!.following = true
                    self.updateButtonFollow()
                }
            })
        }
        else if !notification!.user!.following {
            notification!.user!.following = true
            updateButtonFollow()
            APIClient.sharedClient.userFollow(notification!.user!.userID!, completion: { (error) -> Void in
                self.following = false
                if error != nil {
                    self.notification!.user!.following = false
                    self.updateButtonFollow()
                }
            })
        }
    }

    private func updateButtonFollow() {
        if notification!.user!.following {
            btnFollow.setTitle("Takibi bırak", forState: .Normal)
            btnFollow.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            btnFollow.layer.borderWidth = 0.0
            btnFollow.layer.borderColor = UIColor.clearColor().CGColor
            btnFollow.backgroundColor = UIColor(red: 165/255.0, green: 48/255.0, blue: 58/255.0, alpha: 1.0)
        }
        else {
            btnFollow.setTitle("Takip et", forState: .Normal)
            btnFollow.setTitleColor(UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0), forState: .Normal)
            btnFollow.layer.borderWidth = 1.0
            btnFollow.layer.borderColor = UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0).CGColor
            btnFollow.backgroundColor = UIColor.clearColor()
        }
    }
}
