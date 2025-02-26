//
//  placeStruct.swift
//  Weather
//
//  Created by sento kiryu on 2/8/25.
//

import UIKit

class Place: Codable{
    var city : String
    
    init(place: String){
        self.city = place
    }
}
