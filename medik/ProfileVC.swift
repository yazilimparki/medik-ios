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
import Haneke
import KVNProgress

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MedikSegmentedControlDelegate, FollowerCellDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var verifyViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnVerify: UIButton!
    let cellSpacingH: CGFloat = 8
    let cellPerRow: Int = 3
    var refreshControl = UIRefreshControl()
    var segmentedControl: MedikSegmentedControl?
    var shouldShowVerifyView: Bool = false
    var followInProgress: Bool = false
    var mediaLastFetchedPage = 1
    var followerLastFetchedPage = 1
    var followingLastFetchedPage = 1
    var mediaNothingToFetch = false
    var followerNothingToFetch = false
    var followingNothingToFetch = false
    var media: [MMedia] = []
    var followers: [MUser] = []
    var followings: [MUser] = []
    let mediaCellIdentifier = "MediaCell"
    let followerCellIdentifier = "FollowerCell"
    let infiniteSpinnerCellIdentifier = "InfiniteSpinnerCell"
    var user: MUser? {
        didSet {
            if didAppearOnce {
                if let user = user {
                    if let currentUser = APIClient.sharedClient.currentUser {
                        if user.userID == currentUser.userID {
                            refreshView()
                        }
                    }
                }
            }
        }
    }
    var didAppearOnce = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Refresh control
        refreshControl.addTarget(self, action: "refreshControlValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        // Notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mediaRemoved:", name: Constants.Notification.MediaRemoved, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "avatarChanged:", name: Constants.Notification.AvatarChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "currentUserChanged:", name: Constants.Notification.UserProfileChanged, object: nil)

        verifyViewHeightConstraint.constant = 0
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if isMovingToParentViewController() {
            let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
            navigationItem.leftBarButtonItem = backButton

            if let user = user {
                if let currentUser = APIClient.sharedClient.currentUser {
                    if user.userID != currentUser.userID {
                        let moreButton = UIBarButtonItem(image: UIImage(named: "btn-nav-more"), style: .Plain, target: self, action: "showMoreActionSheet:")
                        self.navigationItem.rightBarButtonItem = moreButton
                    }
                    refreshView()
                }
            }
        }

        if let user = user {
            if let currentUser = APIClient.sharedClient.currentUser {
                if user.userID == currentUser.userID {
                    if let rootVC = navigationController!.viewControllers.first as? UIViewController {
                        if rootVC.restorationIdentifier == "ProfileVC" {
                            let settingsButton = UIBarButtonItem(image: UIImage(named: "btn-nav-settings"), style: .Plain, target: self, action: "showSettings")
                            self.navigationItem.rightBarButtonItem = settingsButton

                            shouldShowVerifyView = true
                            updateVerifyView()
                        }
                    }
                }
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !didAppearOnce {
            if user != nil { refreshUser() }
            didAppearOnce = true
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "scrollToTop", name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if segmentedControl?.selectedIndex == 0 {
            media = []
            refreshMedia()
        }
        else if segmentedControl?.selectedIndex == 1 {
            followers = []
            refreshFollowers()
        }
        else if segmentedControl?.selectedIndex == 2 {
            followings = []
            refreshFollowings()
        }
    }

    // MARK: - Setup view

    func refreshView() {
        if user != nil {
            // Navigation bar setup
            refreshNavBarTitle()
            refreshMedia()
        }
    }

    func refreshNavBarTitle() {
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = user!.screenName
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle
    }

    func updateVerifyView() {
        if !shouldShowVerifyView { return }

        if user!.canVerify {
            var title = "Onaylı kullanıcı olun."
            
            if let professionId = user?.professionId {
                switch professionId {
                case 1, 2, 4: // hekim, asistan, dis hekimi
                    title = "Onaylı hekim olun."
                    break;
                case 3:
                    title = "Onaylı hemşire olun."
                    break;
                default:
                    title = "Onaylı kullanıcı olun."
                    break;
                }
            }
            
            btnVerify.setTitle(title, forState: .Normal)
            
            // var btnVerifySize = btnVerify.sizeThatFits(CGSizeMake(view.frame.size.width, CGFloat.max))
            verifyViewHeightConstraint.constant = 40
        }
        else {
            verifyViewHeightConstraint.constant = 0
        }
    }

    // MARK: - Segmented control delegate

    func medikSegmentedControlValueChanged(segmentedControl: MedikSegmentedControl) {
        if followers.count == 0 {
            refreshFollowers()
        }
        else if followings.count == 0 {
            refreshFollowings()
        }
        else {
            collectionView.reloadData()
        }
    }

    // MARK: - Follower cell delegate

    func profileTappedForFollower(follower: MUser) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ProfileVC") as! ProfileVC
        vc.user = follower
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func followingStatusChanged() {
        if let user = user {
            if let currentUser = APIClient.sharedClient.currentUser {
                if user.userID == currentUser.userID {
                    refreshUser()
                }
            }
        }
    }

    // MARK: - Collectionview data source

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if segmentedControl?.selectedIndex == 0 {
            if mediaNothingToFetch {
                return media.count
            }
            else {
                return media.count + 1
            }
        }
        else if segmentedControl?.selectedIndex == 1 {
            if followerNothingToFetch {
                return followers.count
            }
            else {
                return followers.count + 1
            }
        }
        else if segmentedControl?.selectedIndex == 2 {
            if followingNothingToFetch {
                return followings.count
            }
            else {
                return followings.count + 1
            }
        }

        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!

        if segmentedControl?.selectedIndex == 0 {
            if indexPath.row < media.count {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(mediaCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
                let mediaObject = media[indexPath.row]

                if let imgMedia = cell.viewWithTag(1001) as? UIImageView {
                    if let images = mediaObject.images {
                        if let firstImage = images.first {
                            if let firstImageURL = firstImage.url {
                                if let url = NSURL(string: firstImageURL) {
                                    imgMedia.hnk_setImageFromURL(url)
                                }
                            }
                        }
                    }
                }
            }
            else {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(infiniteSpinnerCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
            }
        }
        else if segmentedControl?.selectedIndex == 1 {
            if indexPath.row < followers.count {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(followerCellIdentifier, forIndexPath: indexPath) as! FollowerCell
            }
            else {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(infiniteSpinnerCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
            }
        }
        else if segmentedControl?.selectedIndex == 2 {
            if indexPath.row < followings.count {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(followerCellIdentifier, forIndexPath: indexPath) as! FollowerCell
            }
            else {
                cell = collectionView.dequeueReusableCellWithReuseIdentifier(infiniteSpinnerCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
            }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: UICollectionReusableView!

        if kind == UICollectionElementKindSectionHeader {
            reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "ProfileHeaderCell", forIndexPath: indexPath) as! UICollectionReusableView
        }

        return reusableView
    }

    // MARK: - Collection view delegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if segmentedControl?.selectedIndex == 0 {
            if indexPath.row == media.count {
                return CGSizeMake(collectionView.bounds.width, 79)
            }
            else {
                let totalSpacing = CGFloat(cellPerRow + 1) * cellSpacingH
                let calculatedWidth = (view.frame.size.width - totalSpacing) / CGFloat(cellPerRow)
                return CGSizeMake(calculatedWidth, calculatedWidth)
            }
        }
        else {
            return CGSizeMake(collectionView.bounds.width, 79)
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell.reuseIdentifier == infiniteSpinnerCellIdentifier {
            if segmentedControl?.selectedIndex == 0 {
                getNextPageOfMedia()
            }
            else if segmentedControl?.selectedIndex == 1 {
                getNextPageOfFollowers()
            }
            else if segmentedControl?.selectedIndex == 2 {
                getNextPageOfFollowings()
            }
        }
        else {
            if segmentedControl?.selectedIndex == 1 {
                if indexPath.row < followers.count {
                    if let cell = cell as? FollowerCell {
                        let followerObject = followers[indexPath.row]
                        cell.user = followerObject
                        cell.delegate = self
                    }
                }
            }
            else if segmentedControl?.selectedIndex == 2 {
                if let cell = cell as? FollowerCell {
                    let followingObject = followings[indexPath.row]
                    cell.user = followingObject
                    cell.delegate = self
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
        if elementKind == UICollectionElementKindSectionHeader {
            if let segmentedControl = view.viewWithTag(2001) as? MedikSegmentedControl {
                segmentedControl.delegate = self
                segmentedControl.thumbWidthRatio = 1
                segmentedControl.inactiveTextColor = UIColor(white: 1.0, alpha: 0.5)
                segmentedControl.activeTextFont = UIFont(name: "Roboto-Regular", size: 12)!
                segmentedControl.inactiveTextFont = UIFont(name: "Roboto-Regular", size: 12)!

                if let user = user {
                    segmentedControl.items = [
                        "\(user.mediaCount.humanReadableStringOfCounter()) Gönderi",
                        "\(user.followerCount.humanReadableStringOfCounter()) Takipçi",
                        "\(user.followingCount.humanReadableStringOfCounter()) Takip edilen"
                    ]
                }
                self.segmentedControl = segmentedControl
            }
            if let imgAvatar = view.viewWithTag(1001) as? UIImageView {
                imgAvatar.layer.borderColor = UIColor.whiteColor().CGColor
                imgAvatar.hidden = false

                if let user = user {
                    if let avatarURL = user.avatarURL {
                        if let url = NSURL(string: avatarURL) {
                            imgAvatar.hnk_setImageFromURL(url)
                        }
                    }
                }
            }
            if let viewVerified = view.viewWithTag(1002) {
                viewVerified.layer.borderColor = UIColor.whiteColor().CGColor

                if let user = user {
                    if user.verified {
                        viewVerified.hidden = false
                    }
                    else {
                        viewVerified.hidden = true
                    }
                }
            }
            if let btnEdit = view.viewWithTag(1003) as? UIButton {
                btnEdit.layer.borderColor = UIColor.whiteColor().CGColor

                if let user = user {
                    if let currentUser = APIClient.sharedClient.currentUser {
                        btnEdit.removeTarget(nil, action: nil, forControlEvents: .AllEvents)

                        if user.userID != currentUser.userID {
                            if user.following {
                                btnEdit.setTitle("Takibi bırak", forState: .Normal)
                                btnEdit.addTarget(self, action: "unfollowUser:", forControlEvents: .TouchUpInside)
                            }
                            else {
                                btnEdit.setTitle("Takip et", forState: .Normal)
                                btnEdit.addTarget(self, action: "followUser:", forControlEvents: .TouchUpInside)
                            }
                        }
                        else {
                            btnEdit.setTitle("Düzenle", forState: .Normal)
                            btnEdit.addTarget(self, action: "showEditProfile:", forControlEvents: .TouchUpInside)
                        }
                    }
                }
            }
            if let lblSpecialty = view.viewWithTag(1004) as? UILabel {
                if let user = user {
                    if let specialty = user.screenSpecialty {
                        lblSpecialty.text = specialty
                    }
                    else {
                        if let profession = user.professionTitle {
                            lblSpecialty.text = profession
                        }
                    }
                    lblSpecialty.hidden = false
                }
            }
            if let lblBio = view.viewWithTag(1005) as? UILabel {
                if let user = user {
                    lblBio.text = user.bio
                    lblBio.hidden = false
                }
            }
            if let lblWeb = view.viewWithTag(1006) as? UILabel {
                if let user = user {
                    lblWeb.text = user.web
                    lblWeb.hidden = false
                }
            }
            if let lblInstitution = view.viewWithTag(1007) as? UILabel {
                if let user = user {
                    lblInstitution.text = user.institution
                    lblInstitution.hidden = false
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        if segmentedControl?.selectedIndex == 0 {
            return UIEdgeInsetsMake(cellSpacingH, cellSpacingH, cellSpacingH, cellSpacingH)
        }
        else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        if segmentedControl?.selectedIndex == 0 {
            return cellSpacingH
        }
        else {
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if segmentedControl?.selectedIndex == 0 {
            performSegueWithIdentifier("showMediaDetail", sender: self)
        }

        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }

    // MARK: - Notification handlers

    func mediaRemoved(notification: NSNotification) {
        if let mediaID = notification.userInfo?["mediaID"] as? Int {
            for (index, medium) in enumerate(media) {
                if medium.mediaID! == mediaID {
                    media.removeAtIndex(index)
                }
            }

            if let user = user {
                if let currentUser = APIClient.sharedClient.currentUser {
                    if user.userID == currentUser.userID {
                        currentUser.mediaCount -= 1
                        user.mediaCount -= 1
                    }
                }
            }

            collectionView.reloadData()
        }
    }

    func avatarChanged(notification: NSNotification) {
        if let user = user {
            if let currentUser = APIClient.sharedClient.currentUser {
                if user.userID == currentUser.userID {
                    refreshUser()
                }
            }
        }
    }

    func currentUserChanged(notification: NSNotification) {
        if let user = user {
            if let currentUser = APIClient.sharedClient.currentUser {
                if user.userID == currentUser.userID {
                    refreshUser()
                }
            }
        }
    }

    // MARK: - Scroll view delegate

    func scrollToTop() {
        collectionView.setContentOffset(CGPointZero, animated: true)
    }

    // MARK: - Refresh control

    func refreshControlValueChanged(refreshControl: UIRefreshControl) {
        if segmentedControl?.selectedIndex == 0 {
            refreshMedia()
        }
        else if segmentedControl?.selectedIndex == 1 {
            refreshFollowers()
        }
        else if segmentedControl?.selectedIndex == 2 {
            refreshFollowings()
        }
    }

    // MARK: - Button actions

    func showSettings() {
        performSegueWithIdentifier("showSettings", sender: self)
    }

    func showEditProfile(sender: UIButton) {
        performSegueWithIdentifier("showEditProfile", sender: self)
    }

    @IBAction func verifyProfile(sender: UIButton) {
        KVNProgress.show()
        APIClient.sharedClient.requestVerification { (error) -> Void in
            KVNProgress.dismiss()

            if error != nil {
                KVNProgress.showErrorWithStatus("Bir sorun oluştu.")
            }
            else {
                self.refreshUser()
            }
        }
    }

    func followUser(sender: UIButton) {
        if followInProgress { return }

        followInProgress = true
        user!.following = true
        sender.setTitle("Takibi bırak", forState: .Normal)
        APIClient.sharedClient.userFollow(user!.userID!, completion: { (error) -> Void in
            self.followInProgress = false
            if error != nil {
                self.user!.following = false
                sender.setTitle("Takip et", forState: .Normal)
            }
            else {
                self.refreshUser()
            }
        })
    }

    func unfollowUser(sender: UIButton) {
        if followInProgress { return }

        followInProgress = true
        user!.following = false
        sender.setTitle("Takip et", forState: .Normal)
        APIClient.sharedClient.userUnfollow(user!.userID!, completion: { (error) -> Void in
            self.followInProgress = false
            if error != nil {
                self.user!.following = true
                sender.setTitle("Takibi bırak", forState: .Normal)
            }
            else {
                self.refreshUser()
            }
        })
    }

    func showMoreActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let reportAction = UIAlertAction(title: "Raporla", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.performSegueWithIdentifier("reportUser", sender: sender)
        })
        let cancelAction = UIAlertAction(title: "Vazgeç", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            optionMenu.dismissViewControllerAnimated(true, completion: nil)
        })

        optionMenu.addAction(reportAction)
        optionMenu.addAction(cancelAction)
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "reportUser" {
            if let destVC = segue.destinationViewController as? ReportVC {
                destVC.user = user
            }
        }
        else if (segue.identifier == "showMediaDetail") {
            if let destVC = segue.destinationViewController as? MediaDetailVC {
                let indexPath: NSIndexPath = collectionView!.indexPathsForSelectedItems()[0] as! NSIndexPath

                destVC.media = media[indexPath.row]
            }
        }
    }

    // MARK: - Network operations

    func refreshUser() {
        APIClient.sharedClient.getUser(user!.userID!, completion: { (responseObject, error) -> Void in
            if error == nil {
                self.user = responseObject
                self.refreshNavBarTitle()
                self.collectionView.reloadData()
                self.updateVerifyView()
            }
        })
    }

    func refreshMedia() { getMedia(page: 1) }
    func refreshFollowers() { getFollowers(page: 1) }
    func refreshFollowings() { getFollowings(page: 1) }

    func getNextPageOfMedia() { getMedia(page: mediaLastFetchedPage + 1) }
    func getNextPageOfFollowers() { getFollowers(page: followerLastFetchedPage + 1) }
    func getNextPageOfFollowings() { getFollowings(page: followingLastFetchedPage + 1) }

    func getMedia(#page: Int) {
        APIClient.sharedClient.userMedia(user!.userID!, page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    if page == 1 {
                        self.mediaNothingToFetch = false
                        self.media.removeAll(keepCapacity: false)
                    }
                    self.media.extend(response)
                    self.mediaLastFetchedPage = page
                }
                else {
                    self.mediaNothingToFetch = true
                }

                self.collectionView.reloadData()
            }
        }
    }

    func getFollowers(#page: Int) {
        APIClient.sharedClient.userFollowers(user!.userID!, page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    if page == 1 {
                        self.followerNothingToFetch = false
                        self.followers.removeAll(keepCapacity: false)
                    }
                    self.followers.extend(response)
                    self.followerLastFetchedPage = page
                }
                else {
                    self.followerNothingToFetch = true
                }

                self.collectionView.reloadData()
            }
        }
    }

    func getFollowings(#page: Int) {
        APIClient.sharedClient.userFollowings(user!.userID!, page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    if page == 1 {
                        self.followingNothingToFetch = false
                        self.followings.removeAll(keepCapacity: false)
                    }
                    self.followings.extend(response)
                    self.followingLastFetchedPage = page
                }
                else {
                    self.followingNothingToFetch = true
                }

                self.collectionView.reloadData()
            }
        }
    }
}
