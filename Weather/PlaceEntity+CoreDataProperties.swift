//
//  PlaceEntity+CoreDataProperties.swift
//  Weather
//
//  Created by sento kiryu on 2/8/25.
//
//

import Foundation
import CoreData


extension PlaceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaceEntity> {
        return NSFetchRequest<PlaceEntity>(entityName: "PlaceEntity")
    }

    @NSManaged public var name: String?

}

extension PlaceEntity : Identifiable {

}
