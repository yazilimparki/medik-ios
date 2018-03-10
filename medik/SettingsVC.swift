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

class SettingsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    let items = [
        [
            "weekly",
            "monthly"
        ],
        [
            "followers",
            "comments",
            "favorites"
        ],
        [
            "terms",
            "logout"
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Ayarlar"
        let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
        navigationItem.leftBarButtonItem = backButton
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        fixTableViewFooter()
    }

    func fixTableViewFooter() {
        var frame = tableView.tableFooterView!.frame
        var frameHeight = frame.size.height
        frame.size.height = 0
        tableView.tableFooterView!.frame = frame
        var size = tableView.contentSize
        size.height -= frameHeight
        tableView.contentSize = size
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let key = items[indexPath.section][indexPath.row]

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCellWithIdentifier("BulletinWeeklyCell") as! UITableViewCell
            }
            else if indexPath.row == 1 {
                cell = tableView.dequeueReusableCellWithIdentifier("BulletinMonthlyCell") as! UITableViewCell
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCellWithIdentifier("NotificationFollowersCell") as! UITableViewCell
            }
            else if indexPath.row == 1 {
                cell = tableView.dequeueReusableCellWithIdentifier("NotificationCommentsCell") as! UITableViewCell
            }
            else if indexPath.row == 2 {
                cell = tableView.dequeueReusableCellWithIdentifier("NotificationFavoritesCell") as! UITableViewCell
            }
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("SettingsCell") as! UITableViewCell
        }

        return cell
    }

    // MARK: - Table view delegate

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsHeaderCell") as! UITableViewCell
        return cell.contentView
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Haftalık"
                }
                if let switchEnabled = cell.viewWithTag(1002) as? UISwitch {
                    if let user = APIClient.sharedClient.currentUser {
                        switchEnabled.on = user.subscriptionsWeekly
                    }
                }
            }
            else if indexPath.row == 1 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Aylık"
                }
                if let switchEnabled = cell.viewWithTag(1002) as? UISwitch {
                    if let user = APIClient.sharedClient.currentUser {
                        switchEnabled.on = user.subscriptionsMonthly
                    }
                }
            }

            cell.selectionStyle = .None
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Takipçiler"
                }
                if let switchEnabled = cell.viewWithTag(1002) as? UISwitch {
                    if let user = APIClient.sharedClient.currentUser {
                        switchEnabled.on = user.notificationsFollowers
                    }
                }
            }
            else if indexPath.row == 1 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Yorumlar"
                }
                if let switchEnabled = cell.viewWithTag(1002) as? UISwitch {
                    if let user = APIClient.sharedClient.currentUser {
                        switchEnabled.on = user.notificationsComments
                    }
                }
            }
            else if indexPath.row == 2 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Favoriler"
                }
                if let switchEnabled = cell.viewWithTag(1002) as? UISwitch {
                    if let user = APIClient.sharedClient.currentUser {
                        switchEnabled.on = user.notificationsFavorites
                    }
                }
            }

            cell.selectionStyle = .None
        }
        else {
            cell.selectionStyle = .Gray

            if indexPath.row == 0 {
                cell.accessoryType = .DisclosureIndicator
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Kullanım koşulları"
                }
            }
            else {
                cell.accessoryType = .None
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblTitle.text = "Çıkış"
                }
            }
        }
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let lblTitle = view.viewWithTag(1001) as? UILabel {
            if section == 0 {
                lblTitle.text = "Bülten"
            }
            else if section == 1 {
                lblTitle.text = "Bildirimler"
            }
            else if section == 2 {
                lblTitle.text = "Diğer"
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let key = items[indexPath.section][indexPath.row]

        if key == "terms" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("TermsVC") as! TermsVC
            vc.isModal = false
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if key == "logout" {
            APIClient.sharedClient.logout({ () -> Void in
                self.navigationController?.popToRootViewControllerAnimated(false)
            })
        }
    }

    // MARK: - Switches

    @IBAction func bulletinWeeklySwitchChanged(sender: UISwitch) {
        if let user = APIClient.sharedClient.currentUser {
            let oldValue = user.subscriptionsWeekly
            user.subscriptionsWeekly = !oldValue

            APIClient.sharedClient.changeBoolUserSettings("subscribe_weekly", newValue: !oldValue, completion: { (error) -> Void in
                if error != nil {
                    user.subscriptionsWeekly = oldValue
                }

                self.tableView.reloadData()
            })
        }
    }

    @IBAction func bulletinMonthlySwitchChanged(sender: UISwitch) {
        if let user = APIClient.sharedClient.currentUser {
            let oldValue = user.subscriptionsMonthly
            user.subscriptionsMonthly = !oldValue

            APIClient.sharedClient.changeBoolUserSettings("subscribe_monthly", newValue: !oldValue, completion: { (error) -> Void in
                if error != nil {
                    user.subscriptionsMonthly = oldValue
                }

                self.tableView.reloadData()
            })
        }
    }

    @IBAction func notificationFollowersSwitchChanged(sender: UISwitch) {
        if let user = APIClient.sharedClient.currentUser {
            let oldValue = user.notificationsFollowers
            user.notificationsFollowers = !oldValue

            APIClient.sharedClient.changeBoolUserSettings("notify_followers", newValue: !oldValue, completion: { (error) -> Void in
                if error != nil {
                    user.notificationsFollowers = oldValue
                }

                self.tableView.reloadData()
            })
        }

    }

    @IBAction func notificationCommentsSwitchChanged(sender: UISwitch) {
        if let user = APIClient.sharedClient.currentUser {
            let oldValue = user.notificationsComments
            user.notificationsComments = !oldValue

            APIClient.sharedClient.changeBoolUserSettings("notify_comments", newValue: !oldValue, completion: { (error) -> Void in
                if error != nil {
                    user.notificationsComments = oldValue
                }

                self.tableView.reloadData()
            })
        }

    }

    @IBAction func notificationFavoritesSwitchChanged(sender: UISwitch) {
        if let user = APIClient.sharedClient.currentUser {
            let oldValue = user.notificationsFavorites
            user.notificationsFavorites = !oldValue

            APIClient.sharedClient.changeBoolUserSettings("notify_favorites", newValue: !oldValue, completion: { (error) -> Void in
                if error != nil {
                    user.notificationsFavorites = oldValue
                }

                self.tableView.reloadData()
            })
        }

    }
}
