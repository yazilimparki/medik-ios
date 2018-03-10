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
import ObjectMapper
import Haneke

var vcShare: UIActivityViewController = UIActivityViewController()

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FeedCellDelegate {
    @IBOutlet weak var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    var lastFetchedPage = 1
    var nothingToFetch = false
    var media: [MMedia] = []
    let feedCellIdentifier = "FeedCell"
    let infiniteSpinnerCellIdentifier = "InfiniteSpinnerCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar setup
        navigationController?.setupStatusBarBackgroundForHiding()
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Medik"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle

        // Refresh control
        refreshControl.addTarget(self, action: "refreshFeed:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        // Table view setup
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 320

        // Notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetchInitialFeed", name: Constants.Notification.GotCurrentUser, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetchInitialFeed", name: Constants.Notification.UserProfileChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mediaRemoved:", name: Constants.Notification.MediaRemoved, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "uploadSucceed:", name: Constants.Notification.UploadingSucceed, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showShareView:", name: "showSV", object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.hidesBarsOnSwipe = true
        
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "scrollToTop", name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.hidesBarsOnSwipe = false
        // NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.ScrollToTop, object: nil)
    }

    // MARK: - Memory warning handling

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Re-fetch initial feed
        media = []
        fetchInitialFeed()
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nothingToFetch {
            return media.count
        }
        else if media.count > 0 {
            return media.count + 1
        }

        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell

        if indexPath.row < media.count {
            cell = tableView.dequeueReusableCellWithIdentifier(feedCellIdentifier) as! FeedCell

            let mediaObject = media[indexPath.row]
            (cell as! FeedCell).media = mediaObject
            (cell as! FeedCell).delegate = self
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(infiniteSpinnerCellIdentifier) as! UITableViewCell
        }

        return cell
    }

    // MARK: - Table view delegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.reuseIdentifier == infiniteSpinnerCellIdentifier {
            getNextPage()
        }
    }

    func mediaRemoved(notification: NSNotification) {
        if let mediaID = notification.userInfo?["mediaID"] as? Int {
            for (index, medium) in enumerate(media) {
                if medium.mediaID! == mediaID {
                    media.removeAtIndex(index)
                }
            }
            reloadTableView()
        }
    }

    func uploadSucceed(notification: NSNotification) {
        getFeed()
    }
    
    func showShareView(notification: NSNotification) {
        self.presentViewController(vcShare, animated: true, completion: nil)
        vcShare = UIActivityViewController()
    }

    // MARK: - Scroll view delegate

    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 45 && navigationController!.navigationBarHidden {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func scrollToTop() {
        tableView.setContentOffset(CGPointZero, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - FeedCell delegate

    func profileTappedForMedia(media: MMedia) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ProfileVC") as! ProfileVC
        vc.user = media.user
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func commentsTappedForMedia(media: MMedia) {
        performSegueWithIdentifier("showMediaDetail", sender: media)
    }

    func photoTappedForMedia(media: MMedia) {
        performSegueWithIdentifier("showMediaDetail", sender: media)
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMediaDetail" {
            if let destVC = segue.destinationViewController as? MediaDetailVC {
                if let media = sender as? MMedia {
                    destVC.media = media
                }
            }
        }
    }

    // MARK: - Network operations

    func fetchInitialFeed() {
        getFeed()
    }

    func getFeed(page: Int = 1) {
        APIClient.sharedClient.userFeed(page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    if page == 1 {
                        self.nothingToFetch = false
                        self.media.removeAll(keepCapacity: false)
                    }
                    self.media.extend(response)
                    self.lastFetchedPage = page
                }
                else {
                    self.nothingToFetch = true
                }

                // There's a bug in UITableViewAutomaticDimension this is a workaround
                self.reloadTableView()
            }
        }
    }

    func refreshFeed(sender: UIRefreshControl) {
        getFeed(page: 1)
    }

    func getNextPage() {
        if nothingToFetch {
            return
        }
        
        getFeed(page: lastFetchedPage + 1)
    }

    // MARK: - Table view hacks

    private func reloadTableView() {
        tableView.reloadData()
        tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.tableView.numberOfSections())), withRowAnimation: .None)
    }
}
