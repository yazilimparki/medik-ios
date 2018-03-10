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

import Foundation
import Alamofire
import ObjectMapper
import AlamofireObjectMapper
import Haneke
import Locksmith
import Parse

private let _sharedClient = APIClient()

class APIClient {
    var currentUser: MUser? = nil

    // MARK: - Singleton

    class var sharedClient: APIClient {
        return _sharedClient
    }

    // MARK: - Access Token

    func getAccessTokenOfApp(completion: ((responseObject: NSDictionary?, error: NSError?) -> Void)? = nil) {
        let params = [
            "client_id": Constants.API.ClientID,
            "client_secret": Constants.API.ClientSecret,
            "grant_type": "client_credentials"
        ]

        Alamofire.request(Router.OAuthToken(params))
            .validate()
            .responseJSON { (request, response, data, error) in
                if let responseDict = data as? NSDictionary {
                    if let accessToken = responseDict.valueForKey("access_token") as? String {
                        self.storeAccessToken(accessToken)
                    }

                    completion?(responseObject: responseDict, error: error)
                }
                else {
                    completion?(responseObject: nil, error: error)
                }
        }
    }

    // MARK: - Login

    func login(username: String, password: String, completion: ((error: NSError?) -> Void)?) {
        let params = [
            "client_id": Constants.API.ClientID,
            "client_secret": Constants.API.ClientSecret,
            "grant_type": "password",
            "username": username,
            "password": password
        ]

        Alamofire.request(Router.Login(params))
            .validate()
            .responseJSON { (request, response, data, error) in
                if let responseDict = data as? NSDictionary {
                    if let accessToken = responseDict.valueForKey("access_token") as? String {
                        self.storeAccessToken(accessToken)
                        Locksmith.saveData(["password": password], forUserAccount: username, inService: Constants.Keychain.ServiceName)
                    }
                    completion?(error: error)
                }
                else {
                    completion?(error: error)
                }
        }
    }

    // MARK: - Logout

    func logout(completion: (() -> Void)?) {
        // Router access token
        self.storeAccessToken(nil)

        // User defaults
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(Constants.UserDefaults.UserKey)
        userDefaults.synchronize()

        if let user = currentUser as MUser! {
            // Keychain data
            Locksmith.deleteDataForUserAccount(user.username!, inService: Constants.Keychain.ServiceName)
        }

        // Notify other controllers
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.Logout, object: nil, userInfo: nil)

        completion?()
    }
    
    // MARK: - Signup

    func signup(username: String, email: String, password: String, specialtyID: Int, completion: ((fieldErrors: NSArray?, error: NSError?) -> Void)?) {
        let params = [
            "username": username,
            "password": password,
            "email": email,
            "speciality_id": specialtyID
        ]

        Alamofire.request(Router.Signup(params as! [String : AnyObject]))
            .validate()
            .responseJSON { (request, response, data, error) -> Void in
                if let errors = data as? NSArray {
                    completion?(fieldErrors: errors, error: error)
                }
                else {
                    completion?(fieldErrors: nil, error: error)
                }
        }
    }

    // MARK: - Password reset

    func passwordReset(email: String, completion: ((error: NSError?) -> Void)?) {
        let params = [
            "email": email
        ]

        Alamofire.request(Router.PasswordReset(params))
            .validate()
            .responseJSON { (request, response, data, err) -> Void in
                if err != nil {
                    completion?(error: err)
                }
                else {
                    completion?(error: nil)
                }
            }
    }

    // MARK: - User verification

    func requestVerification(completion: ((error: NSError?) -> Void)?) {
        Alamofire.request(Router.VerifyUser)
            .validate()
            .responseJSON { (_, _, _, error) -> Void in
                completion?(error: error)
        }
    }

    // MARK: - Current user

    func getCurrentUser(completion: ((responseObject: MUser?, error: NSError?) -> Void)?) {
        Alamofire.request(Router.CurrentUser)
            .validate()
            .responseObject { (response: MUser?, error: NSError?) in
                if error != nil {
                    completion?(responseObject: nil, error: error)
                }
                else {
                    self.currentUser = response

                    var userDefaults = NSUserDefaults.standardUserDefaults()
                    userDefaults.setObject(response!.username, forKey:Constants.UserDefaults.UserKey)
                    userDefaults.synchronize()

                    let installation = PFInstallation.currentInstallation()
                    installation.addUniqueObject("u\(response!.userID!)", forKey: "channels")
                    installation.saveInBackground()

                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.GotCurrentUser, object: nil)

                    completion?(responseObject: response, error: error)
                }
            }
    }

    // MARK: - Get user

    func getUser(userID: Int, completion: ((responseObject: MUser?, error: NSError?) -> Void)?) {
        Alamofire.request(Router.GetUser(userID))
            .validate()
            .responseObject { (response: MUser?, error: NSError?) in
                completion?(responseObject: response, error: error)
        }
    }

    // MARK: - Get media

    func getMedia(mediaID: Int, completion: ((responseObject: MMedia?, error: NSError?) -> Void)?) {
        Alamofire.request(Router.GetMedia(mediaID))
            .validate()
            .responseObject { (response: MMedia?, error: NSError?) in
                completion?(responseObject: response, error: error)
        }
    }

    // MARK: - User media

    func userMedia(userID: Int, page: Int = 0, completion: ((response: [MMedia], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.UserMedia(userID, params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var mediaList: [MMedia] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, media) in enumerate(jsonData) {
                                if let mediaObject = Mapper<MMedia>().map(media) {
                                    mediaList.append(mediaObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: mediaList, error: error)
        }
    }

    // MARK: - User followers

    func userFollowers(userID: Int, page: Int = 0, completion: ((response: [MUser], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.UserFollowers(userID, params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var userList: [MUser] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, user) in enumerate(jsonData) {
                                if let userObject = Mapper<MUser>().map(user) {
                                    userList.append(userObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: userList, error: error)
        }
    }

    // MARK: - User followings

    func userFollowings(userID: Int, page: Int = 0, completion: ((response: [MUser], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.UserFollowings(userID, params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var userList: [MUser] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, user) in enumerate(jsonData) {
                                if let userObject = Mapper<MUser>().map(user) {
                                    userList.append(userObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: userList, error: error)
        }
    }

    // MARK: - Follow or unfollow user

    func userFollow(userID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.UserFollow(userID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    func userUnfollow(userID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.UserUnfollow(userID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Feed

    func userFeed(page: Int = 0, completion: ((response: [MMedia], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.UserFeed(params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var mediaList: [MMedia] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, media) in enumerate(jsonData) {
                                if let mediaObject = Mapper<MMedia>().map(media) {
                                    mediaList.append(mediaObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: mediaList, error: error)
            }
    }

    // MARK: - Favorite media

    func mediaFavorite(mediaID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.MediaFavorite(mediaID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    func mediaUnfavorite(mediaID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.MediaUnfavorite(mediaID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Get categories

    func getCategories(completion: ((response: [MMediaCategory], error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.Categories)
            .validate()
            .responseJSON { (request, response, data, error) in
                var categoryList: [MMediaCategory] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, category) in enumerate(jsonData) {
                                if let categoryObject = Mapper<MMediaCategory>().map(category) {
                                    categoryList.append(categoryObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: categoryList, error: error)
        }
    }

    // MARK: - Get category media

    func categoryMedia(categoryID: Int, page: Int = 0, completion: ((response: [MMedia], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.GetCategoryMedia(categoryID, params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var mediaList: [MMedia] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, media) in enumerate(jsonData) {
                                if let mediaObject = Mapper<MMedia>().map(media) {
                                    mediaList.append(mediaObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: mediaList, error: error)
        }
    }

    // MARK: - Category subscription

    func subscribeCategory(categoryID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.CategorySubscribe(categoryID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    func unsubscribeCategory(categoryID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.CategoryUnsubscribe(categoryID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - User settings

    func changeBoolUserSettings(settingName: String, newValue: Bool, completion: ((error: NSError?) -> Void)? = nil) {
        let params = [
            settingName: newValue
        ]

        Alamofire.request(Router.UserSettings(params))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - User profile update

    func updateUserProfile(parameters: [String: AnyObject], completion: ((fieldErrors: NSArray?, error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.UpdateUserProfile(parameters))
            .validate()
            .responseJSON  { (request, response, data, error) in
                if let errors = data as? NSArray {
                    completion?(fieldErrors: errors, error: error)
                }
                else {
                    completion?(fieldErrors: nil, error: error)
                }
        }
    }

    // MARK: - Report user

    func reportUser(userID: Int, reason: String, completion: ((error: NSError?) -> Void)? = nil) {
        let params = [
            "text": reason
        ]

        Alamofire.request(Router.ReportUser(userID, params))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Report media

    func reportMedia(mediaID: Int, reason: String, completion: ((error: NSError?) -> Void)? = nil) {
        let params = [
            "text": reason
        ]

        Alamofire.request(Router.ReportMedia(mediaID, params))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Report comment

    func reportComment(commentID: Int, reason: String, completion: ((error: NSError?) -> Void)? = nil) {
        let params = [
            "text": reason
        ]

        Alamofire.request(Router.ReportComment(commentID, params))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Delete media

    func deleteMedia(mediaID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.DeleteMedia(mediaID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Create media

    func createMedia(parameters: [String: AnyObject], completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.CreateMedia(parameters))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Delete comment

    func deleteComment(commentID: Int, completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.DeleteComment(commentID))
            .validate()
            .responseJSON  { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - New Comment

    func newComment(mediaID: Int, comment: String, completion: ((response: MMediaComment?, error: NSError?) -> Void)? = nil) {
        let params = [
            "text": comment
        ]

        Alamofire.request(Router.NewComment(mediaID, params))
            .validate()
            .responseJSON  { (request, response, data, error) in
                var newCommentObject: MMediaComment?

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let newID = json["id"] as? Int {
                            newCommentObject = MMediaComment()
                            newCommentObject!.user = APIClient.sharedClient.currentUser
                            newCommentObject!.text = comment
                            newCommentObject!.createdAt = NSDate()
                        }
                    }
                }

                completion?(response: newCommentObject, error: error)
        }
    }

    // MARK: - Media comments

    func mediaComments(mediaID: Int, page: Int = 0, completion: ((response: [MMediaComment], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.MediaComments(mediaID, params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var commentList: [MMediaComment] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, comment) in enumerate(jsonData) {
                                if let commentObject = Mapper<MMediaComment>().map(comment) {
                                    commentList.append(commentObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: commentList, error: error)
        }
    }

    // MARK: - Notifications

    func userNotifications(page: Int = 0, completion: ((response: [MNotification], error: NSError?) -> Void)? = nil) {
        var params = [String: AnyObject]()
        if page > 0 { params["page"] = page }

        Alamofire.request(Router.UserNotifications(params))
            .validate()
            .responseJSON { (request, response, data, error) in
                var notificationList: [MNotification] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, notification) in enumerate(jsonData) {
                                if let notificationObject = Mapper<MNotification>().map(notification) {
                                    notificationList.append(notificationObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: notificationList, error: error)
        }
    }

    // MARK: - Notifications mark as read all

    func userNotificationsMarkAllRead(completion: ((error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.UserNotificationsReadAll)
            .validate()
            .responseJSON { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Get professions

    func getProfessions(completion: ((response: [MProfession], error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.Professions)
            .validate()
            .responseJSON { (request, response, data, error) in
                var professionList = [MProfession]()

                if error == nil {
                    if error == nil {
                        if let json = data as? [String: AnyObject] {
                            if let jsonData = json["data"] as? [AnyObject] {
                                for (_, profession) in enumerate(jsonData) {
                                    if let professionObject = Mapper<MProfession>().map(profession) {
                                        professionList.append(professionObject)
                                    }
                                }
                            }
                        }
                    }
                }

                completion?(response: professionList, error: error)
        }
    }

    // MARK: - User specialties

    func getUserSpecialties(completion: ((response: [MSpecialty], error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.UserSpecialties)
            .validate()
            .responseJSON { (request, response, data, error) in
                var specialtyList: [MSpecialty] = []

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, specialty) in enumerate(jsonData) {
                                if let specialtyObject = Mapper<MSpecialty>().map(specialty) {
                                    specialtyList.append(specialtyObject)
                                }
                            }
                        }
                    }
                }

                completion?(response: specialtyList, error: error)
        }
    }

    // MARK: - Get cities

    func getCities(completion: ((response: [AnyObject], error: NSError?) -> Void)? = nil) {
        Alamofire.request(Router.Cities)
            .validate()
            .responseJSON { (request, response, data, error) in
                var responseArray = [AnyObject]()

                if error == nil {
                    if let json = data as? [String: AnyObject] {
                        if let jsonData = json["data"] as? [AnyObject] {
                            for (_, city) in enumerate(jsonData) {
                                responseArray.append(city)
                            }
                        }
                    }
                }

                completion?(response: responseArray, error: error)
        }
    }

    // MARK: - Upload avatar

    func uploadAvatar(image: UIImage, completion: ((error: NSError?) -> Void)? = nil) {
        let imageData = UIImageJPEGRepresentation(image, 0.9)
        let urlString = "\(Constants.API.BaseURL)/\(Constants.API.AvatarURL)"
        let urlRequest = urlRequestWithComponents(urlString, imageData: imageData)

        Alamofire.upload(urlRequest.0, urlRequest.1)
            .responseJSON { (request, response, data, error) in
                completion?(error: error)
        }
    }

    // MARK: - Router
    func storeAccessToken(token: String?) {
        Router.accessToken = token;
    }

    func accessToken() -> String? {
        return Router.accessToken
    }

    func accessTokenExists() -> Bool {
        if Router.accessToken != nil { return true }
        return false
    }

    // MARK: - Trick for multipart upload

    func urlRequestWithComponents(urlString: String, imageData:NSData) -> (URLRequestConvertible, NSData) {
        // create url request to send
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Alamofire.Method.POST.rawValue
        if let token = Router.accessToken {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let boundaryConstant = "medik-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // create upload data to send
        let uploadData = NSMutableData()
        // add image
        uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"file.jpg\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Type: image/jpeg\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData(imageData)
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        // return URLRequestConvertible and NSData
        return (Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }

    // MARK: - Router
    enum Router: URLRequestConvertible {
        static let baseURL = Constants.API.BaseURL
        static var accessToken: String?

        case OAuthToken([String: AnyObject])
        case Login([String: AnyObject])
        case Signup([String: AnyObject])
        case PasswordReset([String: AnyObject])
        case CurrentUser
        case VerifyUser
        case UpdateUserProfile([String: AnyObject])
        case GetUser(Int)
        case ReportUser(Int, [String: AnyObject])
        case UserMedia(Int, [String: AnyObject])
        case UserFollowers(Int, [String: AnyObject])
        case UserFollowings(Int, [String: AnyObject])
        case UserFollow(Int)
        case UserUnfollow(Int)
        case UserFeed([String: AnyObject])
        case UserSettings([String: AnyObject])
        case UserNotifications([String: AnyObject])
        case UserNotificationsReadAll
        case UserSpecialties
        case GetMedia(Int)
        case GetCategoryMedia(Int, [String: AnyObject])
        case DeleteMedia(Int)
        case CreateMedia([String: AnyObject])
        case MediaFavorite(Int)
        case MediaUnfavorite(Int)
        case MediaComments(Int, [String: AnyObject])
        case NewComment(Int, [String: AnyObject])
        case ReportMedia(Int, [String: AnyObject])
        case ReportComment(Int, [String: AnyObject])
        case DeleteComment(Int)
        case Professions
        case Cities
        case Categories
        case CategorySubscribe(Int)
        case CategoryUnsubscribe(Int)

        var method: Alamofire.Method {
            switch self {
            case .OAuthToken:
                return .POST
            case .Login:
                return .POST
            case .Signup:
                return .POST
            case .PasswordReset:
                return .POST
            case .CurrentUser:
                return .GET
            case .VerifyUser:
                return .POST
            case .UpdateUserProfile:
                return .PATCH
            case .GetUser:
                return .GET
            case .ReportUser:
                return .POST
            case .UserMedia:
                return .GET
            case .UserFollowers:
                return .GET
            case .UserFollowings:
                return .GET
            case .UserFollow:
                return .POST
            case .UserUnfollow:
                return .DELETE
            case .UserFeed:
                return .GET
            case .UserSettings:
                return .PATCH
            case .UserNotifications:
                return .GET
            case .UserNotificationsReadAll:
                return .DELETE
            case .UserSpecialties:
                return .GET
            case .GetMedia:
                return .GET
            case .GetCategoryMedia:
                return .GET
            case .DeleteMedia:
                return .DELETE
            case .CreateMedia:
                return .POST
            case .MediaFavorite:
                return .POST
            case .MediaUnfavorite:
                return .DELETE
            case .MediaComments:
                return .GET
            case .ReportMedia:
                return .POST
            case .NewComment:
                return .POST
            case .ReportComment:
                return .POST
            case .DeleteComment:
                return .DELETE
            case .Professions:
                return .GET
            case .Cities:
                return .GET
            case .Categories:
                return .GET
            case .CategorySubscribe:
                return .POST
            case .CategoryUnsubscribe:
                return .DELETE
            }
        }

        // MARK: URLStringConvertible
        var path: String {
            switch self {
            case .OAuthToken:
                return Constants.API.TokenURL
            case .Login:
                return Constants.API.TokenURL
            case .Signup:
                return Constants.API.SignupURL
            case .PasswordReset:
                return Constants.API.PasswordResetURL
            case .CurrentUser:
                return Constants.API.CurrentUserURL
            case .VerifyUser:
                return Constants.API.VerificationURL
            case .UpdateUserProfile:
                return Constants.API.CurrentUserURL
            case .GetUser(let userID):
                return "\(Constants.API.UsersURL)/\(userID)"
            case .ReportUser(let userID, _):
                return "\(Constants.API.UsersURL)/\(userID)/report"
            case .UserMedia(let userID, _):
                return "\(Constants.API.UsersURL)/\(userID)/media"
            case .UserFollowers(let userID, _):
                return "\(Constants.API.UsersURL)/\(userID)/followers"
            case .UserFollowings(let userID, _):
                return "\(Constants.API.UsersURL)/\(userID)/following"
            case .UserFollow(let userID):
                return "\(Constants.API.UserFollowURL)/\(userID)"
            case .UserUnfollow(let userID):
                return "\(Constants.API.UserFollowURL)/\(userID)"
            case .UserFeed:
                return Constants.API.UserFeedURL
            case .UserSettings(_):
                return Constants.API.SettingsURL
            case .UserNotifications(_):
                return Constants.API.NotificationsURL
            case .UserNotificationsReadAll:
                return Constants.API.NotificationsURL
            case .UserSpecialties:
                return Constants.API.UserSpecialtiesURL
            case .GetMedia(let mediaID):
                return "\(Constants.API.MediaURL)/\(mediaID)"
            case .GetCategoryMedia(let categoryID, _):
                return "\(Constants.API.CategoriesURL)/\(categoryID)/\(Constants.API.MediaURL)"
            case .DeleteMedia(let mediaID):
                return "\(Constants.API.MediaURL)/\(mediaID)"
            case .CreateMedia(_):
                return Constants.API.MediaURL
            case .MediaFavorite(let mediaID):
                return "\(Constants.API.MediaURL)/\(mediaID)/favorites"
            case .MediaUnfavorite(let mediaID):
                return "\(Constants.API.MediaURL)/\(mediaID)/favorites"
            case .MediaComments(let mediaID, _):
                return "\(Constants.API.MediaURL)/\(mediaID)/comments"
            case .NewComment(let mediaID, _):
                return "\(Constants.API.MediaURL)/\(mediaID)/comments"
            case .ReportMedia(let mediaID, _):
                return "\(Constants.API.MediaURL)/\(mediaID)/report"
            case .ReportComment(let commentID, _):
                return "\(Constants.API.CommentURL)/\(commentID)/report"
            case .DeleteComment(let commentID):
                return "\(Constants.API.CommentURL)/\(commentID)"
            case .Professions:
                return Constants.API.ProfessionsURL
            case .Cities:
                return Constants.API.CitiesURL
            case .Categories:
                return Constants.API.CategoriesURL
            case .CategorySubscribe(let categoryID):
                return "\(Constants.API.CategoriesURL)/\(categoryID)/subscriptions"
            case .CategoryUnsubscribe(let categoryID):
                return "\(Constants.API.CategoriesURL)/\(categoryID)/subscriptions"
            }
        }

        // MARK: URLRequestConvertible
        var URLRequest: NSURLRequest {
            let URL = NSURL(string: Router.baseURL)!
            let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
            mutableURLRequest.HTTPMethod = method.rawValue

            if let token = Router.accessToken {
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            switch self {
            case .OAuthToken(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .Login(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .Signup(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .PasswordReset(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .UpdateUserProfile(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .ReportUser(_, let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .UserMedia(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .UserFollowers(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .UserFollowings(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .UserFeed(let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .UserNotifications(let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .UserSettings(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .GetCategoryMedia(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .CreateMedia(let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .MediaComments(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .NewComment(_, let parameters):
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            case .ReportMedia(_, let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            case .ReportComment(_, let parameters):
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            default:
                return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: nil).0
            }
        }
    }
}
