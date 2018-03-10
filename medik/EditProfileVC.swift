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
import KVNProgress
import Locksmith

class EditProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ActionSheetCustomPickerDelegate {
    @IBOutlet weak var tableView: UITableView!
    var txtUsername: UITextField?
    var txtPassword: UITextField?
    var txtEmail: UITextField?
    var lblProfession: UILabel?
    var txtRealname: UITextField?
    var lblCity: UILabel?
    var txtBio: UITextField?
    var txtInstitution: UITextField?
    var txtWeb: UITextField?
    var professions = [MSpecialty]()
    var cities = []
    var selectedCity: [String: AnyObject]?
    var selectedProfession: MSpecialty?
    var professionPressedBeforeLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Profili Düzenle"
        let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: self.navigationController, action: "popViewControllerAnimated:")
        navigationItem.leftBarButtonItem = backButton

        getProfessionList()
        getCityList()
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

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("AvatarCell") as! UITableViewCell
        }
        else if indexPath.row == 1 {
            cell = tableView.dequeueReusableCellWithIdentifier("UsernameCell") as! UITableViewCell
        }
        else if indexPath.row == 2 {
            cell = tableView.dequeueReusableCellWithIdentifier("PasswordCell") as! UITableViewCell
        }
        else if indexPath.row == 3 {
            cell = tableView.dequeueReusableCellWithIdentifier("EmailCell") as! UITableViewCell
        }
        else if indexPath.row == 4 {
            cell = tableView.dequeueReusableCellWithIdentifier("ProfessionCell") as! UITableViewCell
        }
        else if indexPath.row == 5 {
            cell = tableView.dequeueReusableCellWithIdentifier("RealnameCell") as! UITableViewCell
        }
        else if indexPath.row == 6 {
            cell = tableView.dequeueReusableCellWithIdentifier("CityCell") as! UITableViewCell
        }
        else if indexPath.row == 7 {
            cell = tableView.dequeueReusableCellWithIdentifier("BioCell") as! UITableViewCell
        }
        else if indexPath.row == 8 {
            cell = tableView.dequeueReusableCellWithIdentifier("InstitutionCell") as! UITableViewCell
        }
        else if indexPath.row == 9 {
            cell = tableView.dequeueReusableCellWithIdentifier("WebCell") as! UITableViewCell
        }

        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let user = APIClient.sharedClient.currentUser {
            if indexPath.row == 0 {
                if let imgAvatar = cell.viewWithTag(1001) as? UIImageView {
                    if let url = NSURL(string: user.avatarURL!) {
                        imgAvatar.hnk_setImageFromURL(url)
                    }
                }
            }
            else if indexPath.row == 1 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtUsername = txtField
                    txtUsername!.text = user.username
                }
            }
            else if indexPath.row == 2 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtPassword = txtField

                    if let username = NSUserDefaults.standardUserDefaults().objectForKey(Constants.UserDefaults.UserKey) as? String {
                        let (dictionary, error) = Locksmith.loadDataForUserAccount(username, inService: Constants.Keychain.ServiceName)
                        if error == nil {
                            if let password = dictionary?.objectForKey("password") as? String {
                                txtPassword!.text = password
                            }
                        }
                    }
                }
            }
            else if indexPath.row == 3 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtEmail = txtField
                    txtEmail!.text = user.email
                }
            }
            else if indexPath.row == 4 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblProfession = lblTitle
                    lblProfession!.text = user.specialtyTitle
                }
            }
            else if indexPath.row == 5 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtRealname = txtField
                    txtRealname!.text = user.realName
                }
            }
            else if indexPath.row == 6 {
                if let lblTitle = cell.viewWithTag(1001) as? UILabel {
                    lblCity = lblTitle
                    lblCity!.text = user.cityTitle
                }
            }
            else if indexPath.row == 7 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtBio = txtField
                    txtBio!.text = user.bio
                }
            }
            else if indexPath.row == 8 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtInstitution = txtField
                    txtInstitution!.text = user.institution
                }
            }
            else if indexPath.row == 9 {
                if let txtField = cell.viewWithTag(1001) as? UITextField {
                    txtWeb = txtField
                    txtWeb!.text = user.web
                }
            }
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 75
        }
        else {
            return 44
        }
    }

    // MARK: - Tableview delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let photosAction = UIAlertAction(title: "Fotoğraf seç", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                var imagePickerVC = UIImagePickerController()
                imagePickerVC.sourceType = .PhotoLibrary
                imagePickerVC.delegate = self
                imagePickerVC.allowsEditing = true
                self.presentViewController(imagePickerVC, animated: true, completion: nil)
            })
            optionMenu.addAction(photosAction)
            let cameraAction = UIAlertAction(title: "Fotoğraf çek", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                var imagePickerVC = UIImagePickerController()
                imagePickerVC.sourceType = .Camera
                imagePickerVC.delegate = self
                self.presentViewController(imagePickerVC, animated: true, completion: nil)
            })
            optionMenu.addAction(cameraAction)

            let cancelAction = UIAlertAction(title: "Vazgeç", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                optionMenu.dismissViewControllerAnimated(true, completion: nil)
            })
            optionMenu.addAction(cancelAction)

            presentViewController(optionMenu, animated: true, completion: nil)
        }
        else if indexPath.row == 4 {
            showProfessionPickerView()
        }
        else if indexPath.row == 6 {
            showCityPickerView()
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    // MARK: - TextField delegate

    func textFieldDidBeginEditing(textField: UITextField) {
        if let contentView = textField.superview {
            if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                statusView.hidden = true
            }
        }
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if let contentView = textField.superview {
            if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                if textField == txtUsername {
                    if (txtUsername!.text == "" || count(txtUsername!.text) < Constants.API.UsernameMinLength) {
                        statusView.image = UIImage(named: "icon-textfield-error")
                        statusView.hidden = false
                    }
                    else {
                        updateUserName()
                    }
                }
                else if textField == txtPassword {
                    if (txtPassword!.text == "" || count(txtPassword!.text) < Constants.API.PasswordMinLength) {
                        statusView.image = UIImage(named: "icon-textfield-error")
                        statusView.hidden = false
                    }
                    else {
                        updatePassword()
                    }
                }
                else if textField == txtEmail {
                    if (txtEmail!.text == "" || !txtEmail!.text.isValidEmail()) {
                        statusView.image = UIImage(named: "icon-textfield-error")
                        statusView.hidden = false
                    }
                    else {
                        updateEmail()
                    }
                }
                else if textField == txtRealname {
                    updateRealName()
                }
                else if textField == txtBio {
                    updateBio()
                }
                else if textField == txtInstitution {
                    updateInstitution()
                }
                else if textField == txtWeb {
                    updateWeb()
                }
            }
        }
    }

    // MARK: - Show profession picker

    func showProfessionPickerView() {
        if professions.count == 0 {
            professionPressedBeforeLoaded = true
            return
        }

        var doneButton = UIBarButtonItem(title: "Tamam", style: .Plain, target: nil, action: nil)
        doneButton.tintColor = UIColor.blackColor()

        var cancelButton = UIBarButtonItem(title: "Vazgeç", style: .Plain, target: nil, action: nil)
        cancelButton.tintColor = UIColor.blackColor()

        var currentProfession: Int = 0
        if let user = APIClient.sharedClient.currentUser {
            let currentTitle = user.specialtyTitle

            for (index, profession) in enumerate(professions) {
                if profession.title == currentTitle {
                    currentProfession = index
                }
            }
        }

        let initialSelections = [currentProfession]
        var picker = ActionSheetCustomPicker(title: nil, delegate: self, showCancelButton: true, origin: self.view, initialSelections: initialSelections)
        picker.tag = 1001
        picker.setDoneButton(doneButton)
        picker.setCancelButton(cancelButton)
        picker.showActionSheetPicker()
    }

    // MARK: - Show city picker

    func showCityPickerView() {
        var doneButton = UIBarButtonItem(title: "Tamam", style: .Plain, target: nil, action: nil)
        doneButton.tintColor = UIColor.blackColor()

        var cancelButton = UIBarButtonItem(title: "Vazgeç", style: .Plain, target: nil, action: nil)
        cancelButton.tintColor = UIColor.blackColor()

        var currentCity: Int = 0
        if let user = APIClient.sharedClient.currentUser {
            let currentTitle = user.cityTitle

            for (index, city) in enumerate(cities) {
                if (city["title"] as! String) == currentTitle {
                    currentCity = index
                }
            }
        }

        let initialSelections = [currentCity]
        var picker = ActionSheetCustomPicker(title: nil, delegate: self, showCancelButton: true, origin: self.view, initialSelections: initialSelections)
        picker.tag = 1002
        picker.setDoneButton(doneButton)
        picker.setCancelButton(cancelButton)
        picker.showActionSheetPicker()
    }

    // MARK: - PickerView data source

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1001 {
            return professions.count
        }
        else {
            return cities.count
        }
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if pickerView.tag == 1001 {
            var profession = professions[row]
            return profession.title
        }
        else {
            var city = cities[row] as! [String: AnyObject]
            return city["title"] as! String
        }
    }

    // MARK: - PickerView delegate

    func actionSheetPicker(actionSheetPicker: AbstractActionSheetPicker!, configurePickerView pickerView: UIPickerView!) {
        pickerView.tag = actionSheetPicker.tag
    }

    func actionSheetPickerDidSucceed(actionSheetPicker: AbstractActionSheetPicker!, origin: AnyObject!) {
        if actionSheetPicker.tag == 1001 {
            let params = ["speciality_id": selectedProfession!.specialtyID!]
            APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
                if let contentView = self.lblProfession!.superview {
                    if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                        if error == nil {
                            self.lblProfession!.text = self.selectedProfession!.title
                            APIClient.sharedClient.currentUser?.specialtyTitle = self.lblProfession!.text
                            statusView.image = UIImage(named: "icon-textfield-success")
                            NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                        }
                        else {
                            statusView.image = UIImage(named: "icon-textfield-error")

                            var firstError = fieldErrors?.firstObject as! NSDictionary
                            if let message = firstError.valueForKey("message") as? String {
                                KVNProgress.showErrorWithStatus(message)
                            }
                        }
                        statusView.hidden = false
                    }
                }
            })
        }
        else {
            let params = ["city_id": selectedCity!["id"]!]
            APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
                if let contentView = self.lblCity!.superview {
                    if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                        if error == nil {
                            self.lblCity!.text = self.selectedCity!["title"] as? String
                            APIClient.sharedClient.currentUser?.cityTitle = self.lblCity!.text
                            statusView.image = UIImage(named: "icon-textfield-success")
                            NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                        }
                        else {
                            statusView.image = UIImage(named: "icon-textfield-error")

                            var firstError = fieldErrors?.firstObject as! NSDictionary
                            if let message = firstError.valueForKey("message") as? String {
                                KVNProgress.showErrorWithStatus(message)
                            }
                        }
                        statusView.hidden = false
                    }
                }
            })
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1001 {
            selectedProfession = professions[row]
        }
        else {
            selectedCity = cities[row] as? [String: AnyObject]
        }
    }

    // MARK: - UIImagePickerController delegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        APIClient.sharedClient.uploadAvatar(image, completion: { (error) -> Void in
            if error != nil {
                KVNProgress.showErrorWithStatus("Fotoğraf değiştirilemedi.")
            }
            else {
                self.refreshCurrentUser()
            }
        })
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            KVNProgress.show()
        })
    }

    // MARK: - UINavigationController delegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)

        if viewController != navigationController.viewControllers.first as! UIViewController {
            let backButton = UIBarButtonItem(image: UIImage(named: "btn-nav-back"), style: .Plain, target: navigationController, action: "popViewControllerAnimated:")
            navigationController.topViewController.navigationItem.leftBarButtonItem = backButton
        }
    }

    // MARK: - Network operations

    private func getProfessionList() {
        APIClient.sharedClient.getUserSpecialties { (response, error) -> Void in
            if error == nil {
                self.professions = response

                if self.professionPressedBeforeLoaded {
                    self.showProfessionPickerView()
                }
            }
        }
    }

    private func getCityList() {
        APIClient.sharedClient.getCities { (response, error) -> Void in
            if error == nil {
                self.cities = response
            }
        }
    }

    private func refreshCurrentUser() {
        APIClient.sharedClient.getCurrentUser { (responseObject, error) -> () in
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.AvatarChanged, object: nil)
            KVNProgress.dismiss()
            self.tableView.reloadData()
        }
    }

    private func updateUserName() {
        let params = ["username": txtUsername!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtUsername!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.username = self.txtUsername!.text
                        self.updateUsernameToLoginAtNextLaunch()
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updateUsernameToLoginAtNextLaunch() {
        if let username = NSUserDefaults.standardUserDefaults().objectForKey(Constants.UserDefaults.UserKey) as? String {
            let (dictionary, error) = Locksmith.loadDataForUserAccount(username, inService: Constants.Keychain.ServiceName)
            if error == nil {
                if let password = dictionary?.objectForKey("password") as? String {
                    var userDefaults = NSUserDefaults.standardUserDefaults()
                    userDefaults.setObject(txtUsername!.text, forKey:Constants.UserDefaults.UserKey)
                    userDefaults.synchronize()

                    Locksmith.deleteDataForUserAccount(username, inService: Constants.Keychain.ServiceName)
                    Locksmith.saveData(["password": password], forUserAccount: txtUsername!.text, inService: Constants.Keychain.ServiceName)
                }
            }
        }
    }

    private func updatePassword() {
        let params = ["password": txtPassword!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtPassword!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        self.updatePasswordToLoginAtNextLaunch()
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updatePasswordToLoginAtNextLaunch() {
        if let username = NSUserDefaults.standardUserDefaults().objectForKey(Constants.UserDefaults.UserKey) as? String {
            let (dictionary, error) = Locksmith.loadDataForUserAccount(username, inService: Constants.Keychain.ServiceName)
            if error == nil {
                if let password = dictionary?.objectForKey("password") as? String {
                    Locksmith.updateData(["password": self.txtPassword!.text], forUserAccount: username, inService: Constants.Keychain.ServiceName)
                }
            }
        }
    }

    private func updateEmail() {
        let params = ["email": txtEmail!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtEmail!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.email = self.txtEmail!.text
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updateRealName() {
        let params = ["real_name": txtRealname!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtRealname!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.realName = self.txtRealname!.text
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updateBio() {
        let params = ["bio": txtBio!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtBio!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.bio = self.txtBio!.text
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updateInstitution() {
        let params = ["institution": txtInstitution!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtInstitution!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.institution = self.txtInstitution!.text
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }

    private func updateWeb() {
        let params = ["web": txtWeb!.text]
        APIClient.sharedClient.updateUserProfile(params, completion: { (fieldErrors, error) -> Void in
            if let contentView = self.txtWeb!.superview {
                if let statusView = contentView.viewWithTag(1002) as? UIImageView {
                    if error == nil {
                        statusView.image = UIImage(named: "icon-textfield-success")
                        APIClient.sharedClient.currentUser!.web = self.txtWeb!.text
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UserProfileChanged, object: nil)
                    }
                    else {
                        statusView.image = UIImage(named: "icon-textfield-error")

                        var firstError = fieldErrors?.firstObject as! NSDictionary
                        if let message = firstError.valueForKey("message") as? String {
                            KVNProgress.showErrorWithStatus(message)
                        }
                    }
                    statusView.hidden = false
                }
            }
        })
    }
}
