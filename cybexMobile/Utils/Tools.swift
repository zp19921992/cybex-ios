//
//  Tools.swift
//  cybexMobile
//
//  Created by koofrank on 2018/3/21.
//  Copyright © 2018年 Cybex. All rights reserved.
//
import UIKit
import Foundation
import Alamofire
import SwiftyJSON
import SafariServices
import StoreKit
import SDCAlertView
import SwiftTheme
import Guitar

public struct Version: Equatable, Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let string: String?
    
    public init?(_ version: String) {
        
        let parts: Array<String> = version.split { $0 == "." }.map { String($0) }
        
        if let majorOptional = parts[optional: 0], let minorOptional = parts[optional: 1], let patchOptional = parts[optional: 2],
            let majorInt = Int(majorOptional), let minorInt = Int(minorOptional), let patchInt = Int(patchOptional) {
            self.major = majorInt
            self.minor = minorInt
            self.patch = patchInt
            string = version
        } else {
            return nil
        }
    }
    
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major < rhs.major {
            return true
        } else if lhs.major == rhs.major {
            if lhs.minor < rhs.minor {
                return true
            } else if lhs.minor == rhs.minor {
                if lhs.patch < rhs.patch {
                    return true
                }
                
            }
        }
        
        return false
    }
    
}

extension UIViewController {
    
    func openStoreProductWithiTunesItemIdentifier(_ identifier: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: identifier]
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, _) -> Void in
            if loaded {
                guard let self = self else { return }
                
                self.present(storeViewController, animated: true)
            }
        }
    }
    
    func openSafariViewController(_ urlString: String) {
        if let url = URL(string: urlString) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            vc.delegate = self
            
            self.present(vc, animated: true)
        }
    }
    
    func handlerUpdateVersion(_ completion: CommonCallback?, showNoUpdate: Bool = false ) {
        async {
            guard let result = try? await(SimpleHTTPService.checkVersion()) else {
                main {
                    if let completion = completion {
                        completion()
                    }
                }
                return
            }
            main {
                if let completion = completion {
                    completion()
                }
                if result.update {
                    
                    let contentView = StyleContentView(frame: .zero)
                    ShowToastManager.shared.setUp(title: R.string.localizable.update_version.key.localized(), contentView: contentView, animationType: ShowToastManager.ShowAnimationType.smallBig)
                    ShowToastManager.shared.showAnimationInView(self.view)
                    
                    let contentStyle = ThemeManager.currentThemeIndex == 0 ?  "content_dark" : "content_light"
                    if result.content.contains("\n") {
                        contentView.data = result.content.replacingOccurrences(of: "\n", with: "\\").components(separatedBy: "\\").map({ (string) in
                            "<\(contentStyle)>\(string)</\(contentStyle)>".set(style: "alertContent")!
                        })
                    } else {
                        contentView.data = ["<\(contentStyle)>\(result.content)</\(contentStyle)>".set(style: "alertContent")] as? [NSAttributedString]
                    }
                    
                    ShowToastManager.shared.isShowSingleBtn = result.force
                    ShowToastManager.shared.ensureClickBlock = {
                        if result.force {
                            UIApplication.shared.open(URL(string: result.url)!, options: [:], completionHandler: nil)
                            return
                        }
                        
                        self.openSafariViewController(result.url)
                    }
                } else if showNoUpdate {
                    let alert = AlertController(title: R.string.localizable.unupdata_title.key.localized(), message: R.string.localizable.unupdata_message.key.localized(), preferredStyle: .alert)
                    alert.addAction(AlertAction(title: R.string.localizable.unupdata_ok.key.localized(), style: .normal, handler: nil))
                    alert.present()
                }
            }
        }
    }
}

extension UIViewController: SKStoreProductViewControllerDelegate {
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        dismiss(animated: true)
    }
}

extension UIViewController: SFSafariViewControllerDelegate {
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension Bundle {
    var version: String {
        guard let ver = infoDictionary?["CFBundleShortVersionString"] as? String else {
            return ""
        }
        return ver
    }
}

extension NSLayoutConstraint {
    func changeMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: firstItem as Any,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        newConstraint.priority = priority
        
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([newConstraint])
        
        return newConstraint
    }
    
}
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX") //不设置系统默认地区 为格式化后的语言
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // 默认为系统当前的时区
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension Decimal { // 解决double 计算精度丢失
    var stringValue: String {
        return NSDecimalNumber(decimal: self).stringValue
    }

    var int64Value: Int64 {
        return NSDecimalNumber(decimal: self).int64Value
    }

    var intValue: Int {
        return NSDecimalNumber(decimal: self).intValue
    }

    var floor: Decimal {
        return decimal(digits: 0, roundingMode: .down)
    }

    var ceil: Decimal {
        return decimal(digits: 0, roundingMode: .up)
    }

    func decimal(digits: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var decimal = self
        var drounded = Decimal()
        NSDecimalRound(&drounded, &decimal, digits, roundingMode)

        return drounded
    }

    func string(digits: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> String {
        return decimal(digits: digits, roundingMode: roundingMode).stringValue
    }

    func double(digits: Int = Int.max, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Double {
        if digits == Int.max {
            return Double(stringValue) ?? 0
        }
        return Double(string(digits: digits, roundingMode: roundingMode)) ?? 0
    }

    func cgfloat(digits: Int = Int.max, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> CGFloat {
        if digits == Int.max {
            return CGFloat(exactly: NSDecimalNumber(decimal: self)) ?? 0
        }
        return CGFloat(exactly: NSDecimalNumber(decimal: decimal(digits: digits, roundingMode: roundingMode))) ?? 0
    }
    

    func tradePrice(_ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> (price: String, pricision: Int) {
        var pricision = 0
        if self < Decimal(floatLiteral: 0.0001) {
            pricision = 8
        } else if self < Decimal(floatLiteral: 1) {
            pricision = 6
        } else {
            pricision = 4
        }
        
        return (self.string(digits: pricision, roundingMode: roundingMode), pricision)
    }

    func tradePriceAndAmountDecimal(_ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> (price: String, pricision: Int, amountPricision: Int) {
        var pricision = 0
        var amountPricision = 0
        if self < Decimal(floatLiteral: 0.0001) {
            pricision = 8
            amountPricision = 2
        } else if self < Decimal(floatLiteral: 1) {
            pricision = 6
            amountPricision = 4
        } else {
            pricision = 4
            amountPricision = 6
        }
        return (self.string(digits: pricision,roundingMode: roundingMode), pricision, amountPricision)
    }

    func suffixNumber(digitNum: Int = 5) -> String {
        var num = self
        let sign = ((num < 0) ? "-" : "")
        num = abs(num)
        if num / 1000 < 1 {
            return "\(sign)\(num.string(digits: digitNum, roundingMode: .down))"
        }
        num /= 1000
        if num / 1000 < 1  {
            return "\(sign)\(num.string(digits: 2, roundingMode: .down))" + "k"
        }
        num /= 1000
        if num / 1000 < 1 {
            return "\(sign)\(num.string(digits: 2, roundingMode: .down))" + "m"
        }
        num /= 1000
        return "\(sign)\(num.string(digits: 2, roundingMode: .down))" + "b"
    }
}

extension Double {
    var decimal: Decimal {
        return Decimal(self)
    }

    func string(digits: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> String {
        let decimal = Decimal(floatLiteral: self)
        
        return decimal.string(digits: digits, roundingMode: roundingMode)
    }

    func tradePriceAndAmountDecimal(_ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> (price: String, pricision: Int, amountPricision: Int) {
        return self.decimal.tradePriceAndAmountDecimal(roundingMode)
    }
}

extension Int {
    var decimal: Decimal {
        return Decimal(self)
    }
}

extension String {
    static var numberFormatters: [NumberFormatter] = []
    static var doubleFormat: NumberFormatter = NumberFormatter()
    
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self) // "Mar 22, 2017, 10:22 AM"
    }
    
    var filterJade: String {
        // 正式
        return self.replacingOccurrences(of: "JADE.", with: "")
    }
    
    var getID: Int32 {
        if self == "" {
            return 0
        }
        
        if let id = self.components(separatedBy: ".").last {
            return Int32(id)!
        }
        
        return 0
    }
    
    func tradePriceAndAmountDecimal(_ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> (price: String, pricision: Int, amountPricision: Int) {
        return self.decimal().tradePriceAndAmountDecimal(roundingMode)
    }

    public func decimal() -> Decimal {
        if self == "" {
            return Decimal(0)
        }
        var selfString = self
        if selfString.contains(",") {
            selfString = selfString.replacingOccurrences( of: "[^0-9.]", with: "", options: .regularExpression)
        }
        return Decimal(string: selfString) ?? Decimal(0)
    }

    func string(digits: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> String {
        return decimal().decimal(digits: digits, roundingMode: roundingMode).stringValue
    }

    func formatCurrency(digitNum: Int) -> String {
        return decimal().string(digits: digitNum, roundingMode: .down)
    }
    
    func suffixNumber(digitNum: Int = 5) -> String {
        return decimal().suffixNumber(digitNum: digitNum)
    }
}

func transferTimeType(_ time: Int, type: Bool = false) -> String {
    var result = ""
    var times = 0
    
    if time == 0 {
        result = "0"
        return result + R.string.localizable.transfer_unit_second.key.localized()
    }
    
    if time / (3600 * 24) != 0 {
        result = "\(time / (3600 * 24))" + R.string.localizable.transfer_unit_day.key.localized()
    }
    times = time % (3600 * 24)
    if times / 3600 != 0 {
        if type == true, result != "" {
            result += " \(times / 3600)" + R.string.localizable.transfer_unit_hour.key.localized()
            return result
        }
        result += " \(times / 3600)" + R.string.localizable.transfer_unit_hour.key.localized()
    }
    times = times % 3600
    if times / 60 != 0 {
        if type == true, result != "" {
            result += " \(times / 60)" + R.string.localizable.transfer_unit_minite.key.localized()
            return result
        }
        result += " \(times / 60)" + R.string.localizable.transfer_unit_minite.key.localized()
    }
    times = times % 60
    if times != 0 {
        result += " \(times)" + R.string.localizable.transfer_unit_second.key.localized()
    }
    return result
}

func timeHandle(_ time: Double, isHiddenSecond: Bool = true) -> String {
    var result = ""
    var intTime = time.int
    
    if isHiddenSecond == true, intTime < 60 {
        return R.string.localizable.eto_time_less_minite.key.localized()
    }
    result += "\(intTime / (3600 * 24))" + R.string.localizable.transfer_unit_day.key.localized() + " "
    intTime = intTime % (3600 * 24)
    result += "\(intTime / 3600)" + R.string.localizable.transfer_unit_hour.key.localized() + " "
    intTime = intTime % 3600
    result += "\(intTime / 60)" + R.string.localizable.transfer_unit_minite.key.localized()
    if isHiddenSecond == false {
        intTime = intTime % 60
        result += " \(intTime)" + R.string.localizable.transfer_unit_second.key.localized()
    }
    return result
}

func verifyPassword(_ password: String) -> (Bool) {
    if password.count < 12 {
        return false
    }
    
    let guiter = Guitar(pattern: "(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])(?=.*[^a-zA-Z0-9]).{12,}")
    if !guiter.test(string: password) {
        return false
    } else {
        return true
    }
}

extension Range where Bound == String.Index {
    var nsRange: NSRange {
        return NSRange(location: self.lowerBound.encodedOffset,
                       length: self.upperBound.encodedOffset -
                        self.lowerBound.encodedOffset)
    }
}
