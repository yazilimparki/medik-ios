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

class CategoryMediaListVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    let mediaCellIdentifier = "CategoryMediaCell"
    let infiniteSpinnerCellIdentifier = "InfiniteSpinnerCell"
    var refreshControl = UIRefreshControl()
    var lastFetchedPage = 1
    var nothingToFetch = false
    var media: [MMedia] = []
    var category: MMediaCategory!
    var cellWidth: CGFloat = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar setup
        var lblNavTitle = UILabel(frame: CGRectZero)
        lblNavTitle.text = category.title
        lblNavTitle.font = UIFont(name: "Roboto-Regular", size: 18)
        lblNavTitle.textColor = UIColor.whiteColor()
        lblNavTitle.sizeToFit()
        navigationItem.titleView = lblNavTitle

        // Refresh control
        refreshControl.addTarget(self, action: "refreshMedia", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.addSubview(refreshControl)
        refreshControl.beginRefreshing()

        // Back button
        let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
        navigationItem.leftBarButtonItem = backButton

        refreshMedia()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        cellWidth = (view.frame.size.width - 40) / 3
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        media = []
        refreshMedia()
    }

    // MARK: - Collection view data source

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if nothingToFetch {
            return media.count
        }
        else {
            return media.count + 1
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!

        if indexPath.row < media.count {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(mediaCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        }
        else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(infiniteSpinnerCellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        }

        return cell
    }

    // MARK: - Collection view delegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.row == media.count {
            return CGSizeMake(view.frame.size.width, 80)
        }
        else {
            return CGSizeMake(cellWidth, cellWidth)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 10, 10, 10)
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell.reuseIdentifier == infiniteSpinnerCellIdentifier {
            getNextPageOfMedia()
        }
        else {
            let mediaObject = media[indexPath.row]

            if let imgMedia = cell.viewWithTag(1001) as? UIImageView {
                if let url = NSURL(string: mediaObject.images!.first!.url!) {
                    imgMedia.hnk_setImageFromURL(url)
                }
            }
        }
    }

    // MARK: - Storyboard segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showMediaDetail") {
            if let destVC = segue.destinationViewController as? MediaDetailVC {
                let indexPath: NSIndexPath = collectionView!.indexPathsForSelectedItems()[0] as! NSIndexPath

                destVC.media = media[indexPath.row]
            }
        }
    }

    // MARK: - Network operations

    func refreshMedia() { getMedia(page: 1) }
    func getNextPageOfMedia() { getMedia(page: lastFetchedPage + 1) }

    func getMedia(#page: Int) {
        APIClient.sharedClient.categoryMedia(category.categoryID!, page: page) { (response, error) -> Void in
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

                self.collectionView.reloadData()
            }
        }
    }
}
