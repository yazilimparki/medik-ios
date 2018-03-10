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

import Haneke

struct Constants {
    struct API {
        static let dateFormatString = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        static let ClientID = "YOUR CLIENT ID"
        static let ClientSecret = "YOUR CLIENT SECRET"
        static let BaseURL = "https://api.example.com"
        static let TokenURL = "oauth2/token"
        static let PasswordResetURL = "users/self/reset-password"
        static let SignupURL = "users"
        static let UsersURL = "users"
        static let CurrentUserURL = "users/self"
        static let UserFeedURL = "users/self/feed"
        static let UserFollowURL = "users/self/following"
        static let SettingsURL = "users/self/settings"
        static let AvatarURL = "users/self/picture"
        static let MediaURL = "media"
        static let MediaFilesURL = "media/files"
        static let CommentURL = "comments"
        static let CategoriesURL = "categories"
        static let ProfessionsURL = "professions"
        static let UserSpecialtiesURL = "users/self/specialities"
        static let CitiesURL = "cities"
        static let NotificationsURL = "users/self/notifications"
        static let VerificationURL = "users/self/verify"
        static let TermsURL = "http://example.com/terms-of-service"
        static let UsernameMinLength = 4
        static let PasswordMinLength = 6
    }

    struct ParseSDK {
        static let AppId = "YOUR PARSE APPLICATION ID"
        static let ClientKey = "YOUR PARSE CLIENT KEY"
    }

    struct Notification {
        static let Login = "MLoggedIn"
        static let Logout = "MLoggedOut"
        static let GotCurrentUser = "MGotCurrentUser"
        static let ScrollToTop = "MScrollToTop"
        static let MediaRemoved = "MMediaRemoved"
        static let UploadingSucceed = "MUploadingSucceed"
        static let AvatarChanged = "MAvatarChanged"
        static let UserProfileChanged = "MUserProfileChanged"
    }

    struct Keychain {
        static let ServiceName = "com.example"
    }

    struct UserDefaults {
        static let UserKey = "example.user"
    }

    static let MErrorDomain = "MErrorDomain"
}
