//
//  UIColor.swift
//  xprojects-without-storyboard
//
//  Created by Максим Ефимов on 03.02.2018.
//  Copyright © 2018 Platforma. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init (hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
        }
        else {
            var rgbValue: UInt32 = 0
            Scanner(string: cString).scanHexInt32(&rgbValue)
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: CGFloat(1.0))
        }
    }

    convenience init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }

    //Оставлено как было, т.к. не понятно какие цвета соответствуют
    static let harmony1 = UIColor(r: 230, g: 240, b: 250)
    static let harmony2 = UIColor(r: 200, g: 210, b: 220)
    static let harmony3 = UIColor(r: 160, g: 170, b: 180)
    static let harmony4 = UIColor(r: 110, g: 120, b: 130)
    static let harmony5 = UIColor(r: 90, g: 100, b: 110)
    static let harmony2_1 = UIColor(r: 179, g: 179, b: 179)
    static let harmony2_2 = UIColor(r: 128, g: 128, b: 128)

    static let color1 = UIColor(hex: "#EF026C")
    static let color1_1 = UIColor(r: 249, g: 90, b: 181) //for disabled color1
    static let color2 = UIColor(hex: "#00B8E6")

    //top gradient colors
    //TODO: Поменять. Оставлено как было, т.к. в файлах от аиты нет таких цветов
    static let grad1 = UIColor(red: 0.16, green: 0.72, blue: 0.90, alpha: 1.0)
    static let grad2 = UIColor(red: 0.52, green: 0.15, blue: 0.77, alpha: 1.0)
    //background gradient colors
    static let grad4 = UIColor(hex: "#DA3893")
    static let grad5 = UIColor(hex: "#6343C5")
    static let grad6 = UIColor(hex: "#00B7AD")

    static let nicknameColor = UIColor.color1
    static let urlColor = UIColor.color2
    static let background = UIColor(hex: "#f4f4f4")
    static let tipsText = UIColor(hex: "#0071BC")
    static let tipsBorder = UIColor(hex: "#E3F0FB")
    static let pagerDotBorder = UIColor(r: 230, g: 230, b: 230)
    static let noContent = UIColor(r: 224, g: 238, b: 247)
}
