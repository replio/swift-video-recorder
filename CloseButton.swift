//
// Created by Максим Ефимов on 27.02.2018.
// Copyright (c) 2018 Platforma. All rights reserved.
//

import UIKit

class CloseButton: UIButton {
    init() {
        super.init(frame: CGRect())
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupViews() {
        setImage(UIImage(named: "close"), for: .normal)
        tintColor = .white
        self.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
}
