//
//  UIView.swift
//  xprojects-without-storyboard
//
//  Created by Максим Ефимов on 03.02.2018.
//  Copyright © 2018 Platforma. All rights reserved.
//

import UIKit

private var AssociatedObjectHandle: UInt8 = 0

extension UIView {
    var hasGradient: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? Bool ?? false
        }

        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func addShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowOffset = CGSize(width:1, height:1)
        self.layer.shadowRadius = 2
    }

    func addGradient(_ colors: [CGColor], _ locations: [NSNumber], _ startPoint: CGPoint, _ endPoint: CGPoint) {
        if self.bounds.width > 0 && !hasGradient {
            let gradient = CAGradientLayer()
            gradient.frame = self.bounds
            //gradient.cornerRadius = self.layer.cornerRadius
            gradient.colors = colors
            gradient.startPoint = startPoint
            gradient.endPoint = endPoint
            gradient.locations = locations
            self.layer.insertSublayer(gradient, at: 0)
            hasGradient = true
        }
    }

    func makeCircle(){
        layer.cornerRadius = self.frame.height / 2
        clipsToBounds = true
        contentMode = .scaleAspectFill
    }
    
    func rotate(_ angle:CGFloat) {
        let radians = angle / 180.0 * CGFloat(Double.pi)
        let rotation = CGAffineTransform.init(rotationAngle:radians)
        self.transform = rotation
    }
    
    func shadow(elevation:Int) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowPath = UIBezierPath(roundedRect:self.bounds, cornerRadius:self.layer.cornerRadius).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        switch elevation {
        // 1pt elevation
        case 1:
            layer.shadowOffset = CGSize(width:0, height:0.92)
            layer.shadowRadius = 1
            
        // 2pt elevation
        case 2:
            layer.shadowOffset = CGSize(width:0, height:1.83)
            layer.shadowRadius = 2
            
        // 3pt elevation
        case 3:
            layer.shadowOffset = CGSize(width:0, height:2.75)
            layer.shadowRadius = 3
            
        // 4pt elevation
        case 4:
            layer.shadowOffset = CGSize(width:0, height:3.67)
            layer.shadowRadius = 4
            
        // 6pt elevation
        case 5:
            layer.shadowOffset = CGSize(width:0, height:5.5)
            layer.shadowRadius = 5
            
        // 8pt elevation
        case 6:
            layer.shadowOffset = CGSize(width:0, height:7.33)
            layer.shadowRadius = 6
            
        // 9pt elevation
        case 7:
            layer.shadowOffset = CGSize(width:0, height:8.25)
            layer.shadowRadius = 7
            
        // 12pt elevation
        case 8:
            layer.shadowOffset = CGSize(width:0, height:11)
            layer.shadowRadius = 8
            
        // 16pt elevation
        case 9:
            layer.shadowOffset = CGSize(width:0, height:14.67)
            layer.shadowRadius = 9
            
        // 24pt elevation
        case 10:
            layer.shadowOffset = CGSize(width:0, height:22)
            layer.shadowRadius = 10
            
        // 0pt delevation
        default:
            break
        }
    }
}
