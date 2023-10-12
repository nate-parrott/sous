//
//  Geometry.swift
//  Sous
//
//  Created by nate parrott on 10/10/23.
//

import Foundation

extension CGRect {
    var center: CGPoint {
        .init(x: midX, y: midY)
    }

    init(center: CGPoint, size: CGSize) {
        self = .init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}
