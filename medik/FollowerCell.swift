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

protocol FollowerCellDelegate {
    func profileTappedForFollower(follower: MUser)
    func followingStatusChanged()
}

class FollowerCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var lblUserScreenName: UILabel!
    @IBOutlet weak var lblSpecialty: UILabel!
    @IBOutlet weak var btnFollow: UIButton!
    private var following: Bool = false
    var delegate: FollowerCellDelegate?

    var user: MUser? {
        didSet {
            userDidSet()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imgUserAvatar.image = nil
        lblUserScreenName.text = nil
        lblSpecialty.text = nil
        btnFollow.hidden = false
    }

    func userDidSet() {
        if let avatarURL = user!.avatarURL {
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

        var usernameTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "profileTapped:")
        usernameTapGestureRecognizer.delegate = self
        usernameTapGestureRecognizer.numberOfTapsRequired = 1
        if let recognizers = lblUserScreenName.gestureRecognizers {
            for recognizer in recognizers {
                lblUserScreenName.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
            }
        }
        lblUserScreenName.addGestureRecognizer(usernameTapGestureRecognizer)

        var specialtyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "profileTapped:")
        specialtyTapGestureRecognizer.delegate = self
        specialtyTapGestureRecognizer.numberOfTapsRequired = 1
        if let recognizers = lblSpecialty.gestureRecognizers {
            for recognizer in recognizers {
                lblSpecialty.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
            }
        }
        lblSpecialty.addGestureRecognizer(specialtyTapGestureRecognizer)

        lblUserScreenName.text = user!.screenName
        lblSpecialty.text = user!.professionTitle
        updateButtonFollow()
    }

    func profileTapped(sender: UITapGestureRecognizer) {
        delegate?.profileTappedForFollower(user!)
    }

    @IBAction func followUser(sender: UIButton) {
        if following { return }

        following = true
        if user!.following {
            user!.following = false
            updateButtonFollow()
            APIClient.sharedClient.userUnfollow(user!.userID!, completion: { (error) -> Void in
                self.following = false
                if error != nil {
                    self.user!.following = true
                    self.updateButtonFollow()
                }
                self.delegate?.followingStatusChanged()
            })
        }
        else if !user!.following {
            user!.following = true
            updateButtonFollow()
            APIClient.sharedClient.userFollow(user!.userID!, completion: { (error) -> Void in
                self.following = false
                if error != nil {
                    self.user!.following = false
                    self.updateButtonFollow()
                }
                self.delegate?.followingStatusChanged()
            })
        }
    }

    func updateButtonFollow() {
        if let user = user {
            if let currentUser = APIClient.sharedClient.currentUser {
                if user.userID == currentUser.userID {
                    btnFollow.hidden = true
                }
            }
            if user.following {
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
}
