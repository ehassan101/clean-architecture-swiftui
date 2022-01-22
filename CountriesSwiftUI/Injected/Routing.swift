//
//  Routing.swift
//  CountriesSwiftUI
//
//  Created by Hiba Hassan on 1/18/22.
//  Copyright © 2022 Alexey Naumov. All rights reserved.
//

import Foundation

enum Routing {
    
    struct CountriesList: Equatable {
        var countryDetails: Country.Code?
    }
    
    struct CountryDetails: Equatable {
        var flag: Bool = false
    }
}
