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

class MMedia: Mappable {
    var mediaID: Int?
    var type: String?
    var caption: String?
    var publicURL: String?
    var favorited: Bool = false
    var user: MUser?
    var images: [MMediaImage]?
    var categories: [MMediaCategory]?
    var favoriteCount: Int = 0
    var commentCount: Int = 0
    var createdAt: NSDate?
    var _uploadingImage: UIImage?
    var _uploadingCategoryID: Int?
    var _uploadProgress: Float = 0.0
    var _uploadStarted = false

    init() {}

    required init?(_ map: Map) {
        mapping(map)
    }

    func mapping(map: Map) {
        mediaID <- map["id"]
        type <- map["type"]
        caption <- map["caption"]
        publicURL <- map["public_url"]
        favorited <- map["favorited"]
        user <- map["user"]
        images <- map["images"]
        categories <- map["categories"]
        favoriteCount <- map["counts.favorites"]
        commentCount <- map["counts.comments"]
        createdAt <- (map["created_at"], MedikDateTransform())
    }
}
