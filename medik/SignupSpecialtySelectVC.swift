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

protocol SignupSpecialtySelectionDelegate {
    func specialtySelected(specialty: MSpecialty)
}

class SignupSpecialtySelectVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var delegate: SignupSpecialtySelectionDelegate?
    var refreshControl = UIRefreshControl()
    var professionList: [MProfession] = []
    let categorySelectionCellIdentifier = "SpecialtySelectionCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar setup
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Meslek seç"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "modal-dismiss"), style: .Plain, target: self, action: "dismissThis")

        // Refresh control
        refreshControl.addTarget(self, action: "getProfessions:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        getProfessions(nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fixTableViewFooter()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        professionList = []
        getProfessions(nil)
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return professionList.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let specialties = professionList[section].specialties {
            return specialties.count
        }
        else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(categorySelectionCellIdentifier) as! UITableViewCell
        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let profession = professionList[indexPath.section] as MProfession? {
            if let specialties = profession.specialties {
                if let specialty = specialties[indexPath.row] as MSpecialty? {
                    if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                        lblTitle.text = specialties[indexPath.row].title
                    }
                }
            }
        }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerView = UIView(frame: CGRectMake(0, 0, view.frame.size.width, 30))
        headerView.backgroundColor = UIColor(red: 165/255.0, green: 48/255.0, blue: 58/255.0, alpha: 1.0)
        var lblTitle = UILabel(frame: CGRectMake(10, 0, headerView.frame.size.width - 10, headerView.frame.size.height))
        lblTitle.text = professionList[section].title
        lblTitle.font = UIFont(name: "Roboto-Regular", size: 16)
        lblTitle.textColor = UIColor.whiteColor()
        lblTitle.textAlignment = .Left
        headerView.addSubview(lblTitle)
        return headerView
    }

    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    // MARK: - Table view delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var specialty: MSpecialty?

        if let profession = professionList[indexPath.section] as MProfession? {
            if let specialties = profession.specialties {
                specialty = specialties[indexPath.row]
            }
        }

        if specialty != nil {
            delegate?.specialtySelected(specialty!)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    func dismissThis() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Network operations

    func getProfessions(sender: AnyObject?) {
        APIClient.sharedClient.getProfessions { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                self.professionList.removeAll(keepCapacity: false)

                for profession in response {
                    self.professionList.append(profession)
                }
                self.tableView.reloadData()
            }
        }
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
