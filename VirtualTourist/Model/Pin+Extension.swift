//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/19/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
