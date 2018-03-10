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

class MediaDetailVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, FeedCellDelegate, CommentCellDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var keyboardAccessoryView: UIView!
    @IBOutlet weak var commentCurtainView: UIView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var keyboardAccessoryViewHeight: NSLayoutConstraint!
    let keyboardAccessoryViewHeightMin: CGFloat = 40
    let keyboardAccessoryViewHeightMax: CGFloat = 240
    let infiniteSpinnerCellIdentifier = "InfiniteSpinnerCell"
    let feedCellIdentifier = "FeedCell"
    let commentCellIdentifier = "CommentCell"
    var lastFetchedPage = 1
    var nothingToFetch = false
    var comments: [MMediaComment] = []
    var refreshControl = UIRefreshControl()
    var media: MMedia!
    var mediaID: Int?
    var didAppearOnce: Bool = false
    var alert: SweetAlert = SweetAlert()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Refresh control
        refreshControl.addTarget(self, action: "refreshComments:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        // Navigation item buttons
        let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
        navigationItem.leftBarButtonItem = backButton
        let moreButton = UIBarButtonItem(image: UIImage(named: "btn-nav-more"), style: .Plain, target: self, action: "showMoreActionSheet:")
        self.navigationItem.rightBarButtonItem = moreButton

        // Navigation item title
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Gönderi"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle

        // Table view setup
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if !didAppearOnce {
            navigationController?.setNavigationBarHidden(false, animated: true)
            fixTableViewFooter()

            if media == nil {
                if let mediaID = mediaID {
                    APIClient.sharedClient.getMedia(mediaID, completion: { (responseObject, error) -> Void in
                        self.media = responseObject
                        self.fetchInitialComments()
                    })
                }
            }
            else {
                fetchInitialComments()
            }

            didAppearOnce = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        comments = []
        fetchInitialComments()
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count + 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(feedCellIdentifier) as! FeedCell
            (cell as! FeedCell).media = media
            (cell as! FeedCell).delegate = self
        }
        else if indexPath.row == (comments.count + 1) {
            cell = tableView.dequeueReusableCellWithIdentifier(infiniteSpinnerCellIdentifier) as! UITableViewCell
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(commentCellIdentifier) as! CommentCell
            (cell as! CommentCell).comment = comments[indexPath.row - 1]
            (cell as! CommentCell).delegate = self
        }

        return cell
    }

    // MARK: - Table view delegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.reuseIdentifier == infiniteSpinnerCellIdentifier {
            if nothingToFetch {
                for view in cell.contentView.subviews {
                    (view as! UIView).hidden = true
                }
            }
            else {
                getNextPage()
            }
        }
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }

        return true
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        if indexPath.row > 0 {
            var actions = [AnyObject]()
            if let currentUser = APIClient.sharedClient.currentUser {
                let comment = comments[indexPath.row - 1]
                if comment.user!.userID == currentUser.userID {
                    var deleteAction = UITableViewRowAction(style: .Default, title: "Sil", handler: { (action, indexPath) -> Void in
                        self.tableView(tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
                        self.tableView.setEditing(false, animated: true)
                    })
                    deleteAction.backgroundColor = UIColor.redColor()
                    actions.append(deleteAction)
                }
                else {
                    var reportAction = UITableViewRowAction(style: .Normal, title: "Raporla", handler: { (action, indexPath) -> Void in
                        self.performSegueWithIdentifier("reportComment", sender: self.comments[indexPath.row - 1])
                        self.tableView.setEditing(false, animated: true)
                    })
                    actions.append(reportAction)
                }
            }
            return actions
        }

        return nil
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let comment = comments[indexPath.row - 1]
            if let commentID = comment.commentID {
                KVNProgress.show()
                APIClient.sharedClient.deleteComment(commentID, completion: { (error) -> Void in
                    if error == nil {
                        KVNProgress.dismiss()
                        self.comments.removeAtIndex(indexPath.row - 1)
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                    else {
                        KVNProgress.showErrorWithStatus("Yorum silinemedi.")
                    }
                })
            }
        }
    }

    // MARK: - FeedCell delegate

    func profileTappedForMedia(media: MMedia) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ProfileVC") as! ProfileVC
        vc.user = media.user
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func commentsTappedForMedia(media: MMedia) {}

    func photoTappedForMedia(media: MMedia) {
        performSegueWithIdentifier("showMediaZoom", sender: self)
    }

    // MARK: - CommentCell delegate

    func profileTappedForComment(comment: MMediaComment) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ProfileVC") as! ProfileVC
        vc.user = comment.user
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UITextView delegate

    func textViewDidBeginEditing(textView: UITextView) {
        commentCurtainView.hidden = false
    }

    func textViewDidEndEditing(textView: UITextView) {
        commentCurtainView.hidden = true
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return false
        }

        return true
    }

    func textViewDidChange(textView: UITextView) {
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero

        if textView.countLines() <= 1 {
            keyboardAccessoryViewHeight.constant = keyboardAccessoryViewHeightMin
        }
        else {
            textView.textContainer.size.height = textView.contentSize.height + 30

            if textView.textContainer.size.height >= keyboardAccessoryViewHeightMax {
                keyboardAccessoryViewHeight.constant = keyboardAccessoryViewHeightMax
            }
            else {
                keyboardAccessoryViewHeight.constant = textView.textContainer.size.height
            }
        }

        let length = count(textView.text)
        let range = NSMakeRange(length, 1)
        textView.scrollRangeToVisible(range)
    }

    // MARK: - Send comment

    @IBAction func btnSendComment(sender: UIButton) {
        if count(commentTextView.text) < 10 {
            commentTextView.becomeFirstResponder()
            KVNProgress.showErrorWithStatus("Yorum çok kısa.")
        }
        else {
            commentTextView.resignFirstResponder()
            KVNProgress.show()

            APIClient.sharedClient.newComment(media.mediaID!, comment: commentTextView.text, completion: { (response, error) -> Void in
                KVNProgress.dismiss()

                if error == nil {
                    self.comments.append(response!)
                    self.commentTextView.text = nil
                    self.keyboardAccessoryViewHeight.constant = self.keyboardAccessoryViewHeightMin
                    self.tableView.reloadData()
                    self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentSize.height), animated: true)
                }
                else {
                    KVNProgress.showErrorWithStatus("Yorum gönderilemedi.")
                }
            })
        }
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "reportMedia" {
            if let destVC = segue.destinationViewController as? ReportVC {
                destVC.media = media
            }
        }
        else if segue.identifier == "reportComment" {
            if let destVC = segue.destinationViewController as? ReportVC {
                destVC.comment = (sender as! MMediaComment)
            }
        }
        else if segue.identifier == "showMediaZoom" {
            if let destVC = segue.destinationViewController as? MediaZoomVC {
                destVC.media = media
            }
        }
    }

    // MARK: - Navigation item buttons

    func showMoreActionSheet(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        /*
        let shareAction = UIAlertAction(title: "Paylaş", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            optionMenu.dismissViewControllerAnimated(true, completion: nil)
            self.shareMediaTapped()
        })
        optionMenu.addAction(shareAction)
        */
        
        if let currentUser = APIClient.sharedClient.currentUser {
            if media.user!.userID == currentUser.userID {
                let deleteAction = UIAlertAction(title: "Sil", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.deleteMedia()
                })
                optionMenu.addAction(deleteAction)
            }
            else {
                let reportAction = UIAlertAction(title: "Raporla", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.performSegueWithIdentifier("reportMedia", sender: sender)
                })
                optionMenu.addAction(reportAction)
            }
        }

        let cancelAction = UIAlertAction(title: "Vazgeç", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            optionMenu.dismissViewControllerAnimated(true, completion: nil)
        })

        optionMenu.addAction(cancelAction)

        self.presentViewController(optionMenu, animated: true, completion: nil)
    }

    func shareMediaTapped() {
        var shareText = "Medik'te bu vakayı incelemelisiniz. @medikapp"
        var activityItems: [AnyObject] = [shareText]

        if let publicURL = media.publicURL {
            var publicURLmodified = "\(publicURL)?utm_source=ios&utm_medium=detail&utm_campaign=share"
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

        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func shareMedia(sender: AnyObject? = nil) {
        shareMediaTapped()
    }

    // MARK: - Network operations

    func fetchInitialComments() {
        getComments()
    }

    func getComments(page: Int = 1) {
        if media == nil {
            self.refreshControl.endRefreshing()
            return
        }

        APIClient.sharedClient.mediaComments(media.mediaID!, page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    if page == 1 {
                        self.nothingToFetch = false
                        self.comments.removeAll(keepCapacity: false)
                    }
                    self.comments.extend(response)
                    self.lastFetchedPage = page
                }
                else {
                    self.nothingToFetch = true
                }
            }

            self.tableView.reloadData()
        }
    }

    func refreshComments(sender: UIRefreshControl) {
        getComments(page: 1)
    }

    func getNextPage() {
        getComments(page: lastFetchedPage + 1)
    }

    func deleteMedia() {
        KVNProgress.show()
        APIClient.sharedClient.deleteMedia(media.mediaID!, completion: { (error) -> Void in
            if error == nil {
                KVNProgress.dismiss()
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.MediaRemoved, object: nil, userInfo: ["mediaID": self.media.mediaID!])
                self.navigationController?.popViewControllerAnimated(true)
            }
            else {
                KVNProgress.showErrorWithStatus("Gönderi silinemedi.")
            }
        })
    }

    // MARK: - Table view hacks

    private func fixTableViewFooter() {
        var frame = tableView.tableFooterView!.frame
        var frameHeight = frame.size.height
        frame.size.height = 0
        tableView.tableFooterView!.frame = frame
        var size = tableView.contentSize
        size.height -= frameHeight
        tableView.contentSize = size
    }
}
