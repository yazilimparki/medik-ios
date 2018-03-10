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

import ObjectMapper

class MUser: Mappable {
    var userID: Int?
    var bio: String?
    var email: String?
    var verified: Bool = false
    var canVerify: Bool = false
    var canPost: Bool = false
    var following: Bool = false
    var followerCount: Int = 0
    var followingCount: Int = 0
    var mediaCount: Int = 0
    var specialtyTitle: String?
    var professionId: Int?
    var professionTitle: String?
    var screenSpecialty: String?
    var cityTitle: String?
    var screenName: String?
    var username: String?
    var realName: String?
    var avatarURL: String?
    var institution: String?
    var web: String?
    var notificationsFollowers: Bool = false
    var notificationsComments: Bool = false
    var notificationsFavorites: Bool = false
    var subscriptionsWeekly: Bool = false
    var subscriptionsMonthly: Bool = false

    init() {}

    required init?(_ map: Map) {
        mapping(map)
    }

    func mapping(map: Map) {
        userID <- map["id"]
        username <- map["username"]
        bio <- map["bio"]
        email <- map["email"]
        verified <- map["verified"]
        canVerify <- map["can_verify"]
        canPost <- map["can_send_media"]
        followerCount <- map["counts.followers"]
        followingCount <- map["counts.following"]
        mediaCount <- map["counts.media"]
        following <- map["following"]
        specialtyTitle <- map["speciality.title"]
        professionId <- map["profession.id"]
        professionTitle <- map["profession.title"]
        screenSpecialty <- map["screen_speciality"]
        cityTitle <- map["city.title"]
        screenName <- map["screen_name"]
        realName <- map["real_name"]
        avatarURL <- map["picture.url"]
        institution <- map["institution"]
        web <- map["web"]
        notificationsFollowers <- map["notifications.followers"]
        notificationsComments <- map["notifications.comments"]
        notificationsFavorites <- map["notifications.favorites"]
        subscriptionsWeekly <- map["subscriptions.weekly"]
        subscriptionsMonthly <- map["subscriptions.monthly"]
    }
}
