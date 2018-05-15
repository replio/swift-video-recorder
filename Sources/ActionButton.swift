//
// Created by Максим Ефимов on 27.02.2018.
// Copyright (c) 2018 Platforma. All rights reserved.
//

import UIKit

class ActionButton: UIButton {
    init(){
        super.init(frame: CGRect())
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        makeCircle()
    }

    func setupViews(){
        tintColor = .color1
        titleLabel?.font = .demiBold16
        titleLabel?.textColor = .color1
        setTitleColor(.color1, for: .normal)
        layer.borderColor = UIColor.color1.cgColor
        layer.borderWidth = 2
    }
}

class ActionButton2: UIButton {
    init(){
        super.init(frame: CGRect())
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        makeCircle()
    }

    func setupViews(){
        tintColor = .white
        backgroundColor = .color1
        titleLabel?.font = .demiBold16
        setTitleColor(.white, for: .normal)
    }
}
/*
class ActionButtonImage: UIButton {

    init(image: UIImage){
        super.init(frame: CGRect())
        setImage(image, for: .normal)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        makeCircle()
    }

    func setupViews(){
        backgroundColor = .color1
        titleLabel?.font = .demiBold16
        setTitleColor(.white, for: .normal)
    }
}
*/
