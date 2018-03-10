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

protocol FeedCellDelegate {
    func profileTappedForMedia(media: MMedia)
    func commentsTappedForMedia(media: MMedia)
    func photoTappedForMedia(media: MMedia)
}

class FeedCell: UITableViewCell, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var imgMedia: UIImageView!
    @IBOutlet weak var imgMediaFavorited: UIImageView!
    @IBOutlet weak var lblUserScreenName: UILabel!
    @IBOutlet weak var lblTimeAgo: UILabel!
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var lblCategoryTitle: UILabel!
    @IBOutlet weak var btnFavorite: UIButton!
    @IBOutlet weak var btnComment: UIButton!
    private var favoriting: Bool = false
    var delegate: FeedCellDelegate?

    var media: MMedia? {
        didSet {
            mediaDidSet()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imgUserAvatar.image = nil
        imgMedia.image = nil
        lblUserScreenName.text = nil
        lblTimeAgo.text = nil
        lblCaption.text = nil
        lblCategoryTitle.text = nil
    }

    func mediaDidSet() {
        if media == nil { return }

        if let avatarURL = media?.user?.avatarURL {
            if let url = NSURL(string: avatarURL) {
                imgUserAvatar.hnk_setImageFromURL(url)
            }
        }

        if let photoURL = media?.images?.first?.url {
            if let url = NSURL(string: photoURL) {
                imgMedia.hnk_setImageFromURL(url)

                var singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "photoTapped:")
                singleTapGestureRecognizer.delegate = self
                singleTapGestureRecognizer.numberOfTapsRequired = 1
                if let recognizers = imgMedia.gestureRecognizers {
                    for recognizer in recognizers {
                        imgMedia.removeGestureRecognizer(recognizer as! UIGestureRecognizer)
                    }
                }
                imgMedia.addGestureRecognizer(singleTapGestureRecognizer)

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
            }
        }

        lblUserScreenName.text = media?.user?.screenName
        lblTimeAgo.text = media?.createdAt?.shortTimeAgoSinceNow()
        lblCaption.text = media?.caption
        lblCategoryTitle.text = media?.categories?.first?.title
        updateCounters()
    }

    func profileTapped(sender: UITapGestureRecognizer) {
        delegate?.profileTappedForMedia(media!)
    }

    @IBAction func commentsTapped(sender: UIButton) {
        delegate?.commentsTappedForMedia(media!)
    }

    func photoTapped(sender: UITapGestureRecognizer) {
        delegate?.photoTappedForMedia(media!)
    }

    @IBAction func favoriteMedia(sender: AnyObject? = nil) {
        if media == nil { return }

        if media!.favorited && !favoriting {
            favoriting = true
            media!.favorited = false
            media!.favoriteCount -= 1
            updateCounters()

            APIClient.sharedClient.mediaUnfavorite(media!.mediaID!, completion: { (error) -> Void in
                self.favoriting = false
                if error != nil {
                    self.media!.favorited = true
                    self.media!.favoriteCount += 1
                    self.updateCounters()
                }
            })
        }
        else if !media!.favorited && !favoriting {
            favoriting = true
            media!.favorited = true
            media!.favoriteCount += 1
            updateCounters()

            APIClient.sharedClient.mediaFavorite(media!.mediaID!, completion: { (error) -> Void in
                self.favoriting = false
                if error != nil {
                    self.media!.favorited = false
                    self.media!.favoriteCount -= 1
                    self.updateCounters()
                }
            })
        }
    }
    
    @IBAction func shareMedia(sender: AnyObject? = nil) {
        if media == nil { return }
        
        var shareText = "Medik'te bu vakayı incelemelisiniz. @medikapp"
        var activityItems: [AnyObject] = [shareText]
            
            if let publicURL = media!.publicURL {
                var publicURLmodified = "\(publicURL)?utm_source=ios&utm_medium=feed&utm_campaign=share"
                if let shareURL = NSURL(string: publicURLmodified) {
                    activityItems.append(shareURL)
                }
            }
            
            var controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            controller.excludedActivityTypes = [
                UIActivityTypePostToWeibo,
                UIActivityTypePrint,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo,
                UIActivityTypeAirDrop
            ]
        
            vcShare = controller
            NSNotificationCenter.defaultCenter().postNotificationName("showSV", object: nil)
    }

    private func updateCounters() {
        if media == nil { return }

        btnFavorite.setTitle(media?.favoriteCount.humanReadableStringOfCounter(), forState: .Normal)
        btnComment.setTitle(media?.commentCount.humanReadableStringOfCounter(), forState: .Normal)

        if media!.favorited {
            btnFavorite.setImage(UIImage(named: "icon-star-filled"), forState: .Normal)
        }
        else {
            btnFavorite.setImage(UIImage(named: "icon-star-empty"), forState: .Normal)
        }
    }
}
