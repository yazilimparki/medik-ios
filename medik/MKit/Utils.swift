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
import UIKit
import Alamofire
import ObjectMapper
import Parse

extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
}

extension UITextView {
    func countLines() -> Int {
        let layoutManager = self.layoutManager
        var numberOfLines = 0
        var index = 0
        var lineRange = NSRange()
        var numberOfGlyphs = layoutManager.numberOfGlyphs
        for(numberOfLines, index; index < numberOfGlyphs; numberOfLines++){
            layoutManager.lineFragmentRectForGlyphAtIndex(index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange);
        }
        return numberOfLines
    }
}

extension NSMutableAttributedString {
    func setAsLink(textToFind: String, linkURL: String) -> Bool {
        let foundRange = self.mutableString.rangeOfString(textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(NSLinkAttributeName, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
}

extension Int {
    func humanReadableStringOfCounter() -> String {
        if self >= 1000000000 {
            return String(format: "%.0fb", (Double(self) / 1000.0 / 1000.0 / 1000.0))
        }
        else if self >= 1000000 {
            return String(format: "%.0fm", (Double(self) / 1000.0 / 1000.0))
        }
        else if self >= 1000 {
            return String(format: "%.0fk", (Double(self) / 1000.0))
        }
        else {
            return "\(self)"
        }
    }
}

extension UINavigationController {
    func setupStatusBarBackgroundForHiding() {
        var statusBarBackground = UIView(frame: CGRectMake(0, 0, UIApplication.sharedApplication().statusBarFrame.size.width, UIApplication.sharedApplication().statusBarFrame.size.height))
        statusBarBackground.backgroundColor = navigationBar.barTintColor
        view.addSubview(statusBarBackground)
    }
}

extension Alamofire.Request {
    class func imageResponseSerializer() -> Serializer {
        return { request, response, data in
            if data == nil {
                return (nil, nil)
            }

            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            return (image, nil)
        }
    }

    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.imageResponseSerializer(), completionHandler: { (request, response, image, error) in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}

public class MedikDateTransform: TransformType {
    public typealias Object = NSDate
    public typealias JSON = String

    public init() {}

    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let date = value as? String {
            var formatter = NSDateFormatter()
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            formatter.dateFormat = Constants.API.dateFormatString
            return formatter.dateFromString(date)
        }

        return nil
    }

    public func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            var formatter = NSDateFormatter()
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            formatter.dateFormat = Constants.API.dateFormatString
            return formatter.stringFromDate(date)
        }

        return nil
    }
}

func resetAppBadgeNumber() {
    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
}

func resetParseBadgeNumber() {
    let currentInstallation = PFInstallation.currentInstallation()
    currentInstallation.badge = 0
    currentInstallation.saveInBackgroundWithBlock({ (succeeded, error) -> Void in
        if error != nil {
            currentInstallation.saveEventually()
        }
    })
}
