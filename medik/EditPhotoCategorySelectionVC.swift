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

protocol EditPhotoCategorySelectionDelegate {
    func categorySelected(category: MMediaCategory)
}

class EditPhotoCategorySelectionVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var delegate: EditPhotoCategorySelectionDelegate?
    var refreshControl = UIRefreshControl()
    var specialtyCategories: [MMediaCategory] = []
    let categorySelectionCellIdentifier = "CategorySelectionCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar setup
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Kategori seç"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "modal-dismiss"), style: .Plain, target: self, action: "dismissThis")

        // Refresh control
        refreshControl.addTarget(self, action: "getCategories:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        getCategories(nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fixTableViewFooter()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segmented control delegate

    func medikSegmentedControlValueChanged(segmentedControl: MedikSegmentedControl) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return specialtyCategories.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(categorySelectionCellIdentifier) as! UITableViewCell

        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let category = specialtyCategories[indexPath.row]
        if let lblTitle = cell.viewWithTag(1001) as? UILabel {
            lblTitle.text = category.title
        }
    }

    // MARK: - Table view delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var category: MMediaCategory!

        category = specialtyCategories[indexPath.row]

        delegate?.categorySelected(category)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func dismissThis() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Network operations

    func getCategories(sender: AnyObject?) {
        APIClient.sharedClient.getCategories { (response, error) -> Void in
            self.refreshControl.endRefreshing()

            if error != nil {
                println(error?.localizedDescription)
            }
            else {
                self.specialtyCategories.removeAll(keepCapacity: false)

                for category in response {
                    if category.categoryType != "anatomy" {
                        self.specialtyCategories.append(category)
                    }
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
