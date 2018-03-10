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

class MNotification: Mappable {
    var notificationID: Int?
    var notificationType: String?
    var objectID: Int?
    var objectType: String?
    var objectImageURL: String?
    var user: MUser?
    var message: String?
    var createdAt: NSDate?

    init() {}

    required init?(_ map: Map) {
        mapping(map)
    }

    func mapping(map: Map) {
        notificationID <- map["id"]
        notificationType <- map["type"]
        objectID <- map["object.id"]
        objectType <- map["object.type"]
        objectImageURL <- map["object.images.full.url"]
        user <- map["user"]
        message <- map["message"]
        createdAt <- (map["created_at"], MedikDateTransform())
    }
}
