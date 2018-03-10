//
// Medik (r) Photo Sharing Platform for Health Professionals (http://medik.com)
// Copyright (c) Yazılım Parkı Bilişim Teknolojileri D.O.R.P. Ltd. Sti. (http://yazilimparki.com.tr)
//
// Licensed under The MIT License (https://opensource.org/licenses/mit-license.php)
// For full copyright and license information, please see the LICENSE file.
// Redistributions of files must retain the above copyright notice.
//
// Medik (r) is registered trademark of Yazılım Parkı Bilişim Teknolojileri D.O.R.P. Ltd. Sti.
//

import UIKit
import Haneke

class ExploreVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    var refreshControl = UIRefreshControl()
    let specialtyCellIdentifier = "SpecialtyCell"
    var specialtyCategories: [MMediaCategory] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar setup
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = "Keşfet"
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle

        // Refresh control
        refreshControl.addTarget(self, action: "getCategories:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        getCategories(nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "scrollToTop", name: Constants.Notification.ScrollToTop, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        // NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notification.ScrollToTop, object: nil)
    }

    // MARK: - Segmented control delegate

    func medikSegmentedControlValueChanged(segmentedControl: MedikSegmentedControl) {
        collectionView.reloadData()
    }

    // MARK: - Collection view data source

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return specialtyCategories.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell

        cell = collectionView.dequeueReusableCellWithReuseIdentifier(specialtyCellIdentifier, forIndexPath: indexPath) as! SpecialtyCell
        (cell as! SpecialtyCell).category = specialtyCategories[indexPath.row]

        return cell
    }

    // MARK: - Collection view delegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.width, 200)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
            return 0
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showCategoryMedia", sender: self)
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }

    // MARK: - Scroll view delegate

    func scrollToTop() {
        collectionView.setContentOffset(CGPointZero, animated: true)
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showCategoryMedia") {
            if let destVC = segue.destinationViewController as? CategoryMediaListVC {
                let indexPath: NSIndexPath = collectionView!.indexPathsForSelectedItems()[0] as! NSIndexPath
                destVC.category = specialtyCategories[indexPath.row]
            }
        }
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
                self.collectionView.reloadData()
            }
        }
    }

}
