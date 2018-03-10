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

protocol CommentCellDelegate {
    func profileTappedForComment(comment: MMediaComment)
}

class CommentCell: UITableViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var lblUserScreenName: UILabel!
    @IBOutlet weak var lblTimeAgo: UILabel!
    @IBOutlet weak var lblSpecialty: UILabel!
    @IBOutlet weak var lblText: UILabel!
    var delegate: CommentCellDelegate?

    var comment: MMediaComment? {
        didSet {
            commentDidSet()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imgUserAvatar.image = nil
        lblUserScreenName.text = nil
        lblTimeAgo.text = nil
        lblSpecialty.text = nil
        lblText.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        lblText.preferredMaxLayoutWidth = contentView.frame.size.width - 60
    }

    func commentDidSet() {
        if let avatarURL = comment!.user?.avatarURL {
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

        lblUserScreenName.text = comment!.user?.screenName
        lblTimeAgo.text = comment!.createdAt?.shortTimeAgoSinceNow()
        lblSpecialty.text = comment!.user?.screenSpecialty
        lblText.text = comment!.text
    }

    func profileTapped(sender: UITapGestureRecognizer) {
        delegate?.profileTappedForComment(comment!)
    }
}
