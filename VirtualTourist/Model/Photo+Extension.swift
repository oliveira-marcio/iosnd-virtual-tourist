//
//  Photo+Extension.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/22/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
