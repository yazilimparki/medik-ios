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

protocol MedikSegmentedControlDelegate {
    func medikSegmentedControlValueChanged(segmentedControl: MedikSegmentedControl)
}

@IBDesignable class MedikSegmentedControl: UIControl {
    var delegate: MedikSegmentedControlDelegate?
    private var labels = [UILabel]()
    private var thumbView = UIView()

    var items: [String] = [""] {
        didSet {
            setupLabels()
        }
    }

    var selectedIndex: Int = 0 {
        didSet {
            updateSelectedIndex(true)
        }
    }

    @IBInspectable var activeTextColor: UIColor = UIColor.whiteColor() {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var activeTextFont: UIFont = UIFont.systemFontOfSize(14) {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var inactiveTextColor: UIColor = UIColor.lightGrayColor() {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var inactiveTextFont: UIFont = UIFont.systemFontOfSize(14) {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var thumbHeight: CGFloat = 5 {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var thumbWidthRatio: CGFloat = 0.5 {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var thumbAnimationDuration: NSTimeInterval = 0.5 {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var thumbColor: UIColor = UIColor.whiteColor() {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool {
        let location = touch.locationInView(self)

        var calculatedIndex: Int?
        for (index, item) in enumerate(labels) {
            if item.frame.contains(location) {
                calculatedIndex = index
            }
        }

        if calculatedIndex != nil {
            selectedIndex = calculatedIndex!
            sendActionsForControlEvents(.ValueChanged)
        }

        return false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        thumbView.frame = frameForThumbView()

        let widthOfLabel = CGRectGetWidth(bounds) / CGFloat(items.count)
        for index in 0...labels.count - 1 {
            var label = labels[index]

            if label == labels[selectedIndex] {
                label.textColor = activeTextColor
                label.font = activeTextFont
            }
            else {
                label.textColor = inactiveTextColor
                label.font = inactiveTextFont
            }
            
            label.frame = CGRectMake(CGFloat(index) * widthOfLabel, 0, widthOfLabel, bounds.size.height)
        }
    }

    private func setupView() {
        thumbView.backgroundColor = thumbColor

        addSubview(thumbView)
        setupLabels()

        addTarget(self, action: "valueChanged:", forControlEvents: .ValueChanged)
    }

    private func setupLabels() {
        for label in labels {
            label.removeFromSuperview()
        }

        labels.removeAll(keepCapacity: false)

        for index in 0...items.count - 1 {
            let label = UILabel(frame: CGRectZero)
            label.text = items[index]
            label.textAlignment = .Center
            label.textColor = inactiveTextColor
            label.font = inactiveTextFont
            labels.append(label)
            addSubview(label)
        }

        updateSelectedIndex(false)
    }

    private func updateSelectedIndex(animated: Bool) {
        var selectedLabel = labels[selectedIndex]

        for label in labels {
            if label == selectedLabel {
                label.textColor = activeTextColor
                label.font = activeTextFont
            }
            else {
                label.textColor = inactiveTextColor
                label.font = inactiveTextFont
            }
        }

        if animated {
            UIView.animateWithDuration(thumbAnimationDuration, animations: { () -> Void in
                self.thumbView.frame = self.frameForThumbView()
            })
        }
    }

    private func frameForThumbView() -> CGRect {
        let widthOfLabel = CGRectGetWidth(bounds) / CGFloat(items.count)
        let widthOfThumb = widthOfLabel * thumbWidthRatio
        let xOfThumb = (CGFloat(selectedIndex) * widthOfLabel) + ((widthOfLabel - widthOfThumb) / 2.0)
        return CGRectMake(xOfThumb, (bounds.size.height - thumbHeight), widthOfThumb, thumbHeight)
    }

    func valueChanged(sender: MedikSegmentedControl) {
        delegate?.medikSegmentedControlValueChanged(sender)
    }

}
