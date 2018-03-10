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
import Parse

class NotificationsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, NotificationCellDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    let infiniteSpinnerCellIdentifier = "InfiniteSpinnerCell"
    let notificationCellIdentifier = "NotificationCell"
    var lastFetchedPage = 1
    var nothingToFetch = false
    var notifications: [MNotification] = []
    var refreshControl = UIRefreshControl()
    var didAppearOnce: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Refresh control
        refreshControl.addTarget(self, action: "refreshNotifications:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        // Navigation item title
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Bildirimler"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle

        // Table view setup
        tableView.estimatedRowHeight = 77
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if !didAppearOnce {
            navigationController?.setNavigationBarHidden(false, animated: true)
            fixTableViewFooter()
            fetchInitialNotifications()
            didAppearOnce = true
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "scrollToTop", name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        notifications = []
        fetchInitialNotifications()
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nothingToFetch {
            return notifications.count
        }
        else if notifications.count > 0 {
            return notifications.count + 1
        }

        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if indexPath.row < notifications.count {
            cell = tableView.dequeueReusableCellWithIdentifier(notificationCellIdentifier) as! NotificationCell

            let notificationObject = notifications[indexPath.row]
            (cell as! NotificationCell).notification = notificationObject
            (cell as! NotificationCell).delegate = self
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

    // MARK: - Scroll view delegate
    
    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func scrollToTop() {
        tableView.setContentOffset(CGPointZero, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Notification Cell delegate

    func profileTappedForNotification(notification: MNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ProfileVC") as! ProfileVC
        vc.user = notification.user
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func mediaTappedForNotification(notification: MNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MediaDetailVC") as! MediaDetailVC
        vc.mediaID = notification.objectID!
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Network operations

    func fetchInitialNotifications() {
        getNotifications()
    }

    func getNotifications(page: Int = 1) {
        resetAppBadgeNumber()
        resetParseBadgeNumber()
        
        APIClient.sharedClient.userNotifications(page: page) { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                if response.count > 0 {
                    self.emptyView.hidden = true

                    if page == 1 {
                        self.nothingToFetch = false
                        self.notifications.removeAll(keepCapacity: false)
                    }
                    self.notifications.extend(response)
                    self.lastFetchedPage = page
                }
                else {
                    if page == 1 {
                        self.emptyView.hidden = false
                    }

                    self.nothingToFetch = true
                }
            }

            self.reloadTableView()
        }
    }

    func refreshNotifications(sender: UIRefreshControl) {
        APIClient.sharedClient.userNotificationsMarkAllRead { (error) -> Void in
            self.getNotifications(page: 1)
        }
    }

    func getNextPage() {
        if nothingToFetch {
            return
        }
        
        getNotifications(page: lastFetchedPage + 1)
    }

    // MARK: - Table view hacks

    private func reloadTableView() {
        tableView.reloadData()
        tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.tableView.numberOfSections())), withRowAnimation: .None)
    }

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
