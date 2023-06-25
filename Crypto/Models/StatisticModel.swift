//
//  StatisticsModel.swift
//  Crypto
//
//  Created by Rosa Meijers on 07/06/2023.
//

import Foundation

// identifiable beause we use it in a for each loop
struct StatisticModel: Identifiable {
    let id = UUID().uuidString
    let title: String
    let value: String
    let percentageChange: Double?
    
    init(title: String, value: String, percentageChange: Double? = nil){
        self.title = title
        self.value = value
        self.percentageChange = percentageChange
    }
}

