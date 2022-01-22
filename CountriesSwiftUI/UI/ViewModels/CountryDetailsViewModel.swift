//
//  CountryDetailsViewModel.swift
//  CountriesSwiftUI
//
//  Created by Hiba Hassan on 1/18/22.
//  Copyright © 2022 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

final class CountryDetailsViewModel: ObservableObject {
    
    private(set) var appStatePublisher: Store<AppState>
    
    private var cancellables = [AnyCancellable]()
    
    @Published var viewRoutingState: Routing.CountryDetails
    @Published var didRequestFlag: Bool = false {
        didSet {
            appStatePublisher[\.routing.countryDetails.flag] = didRequestFlag
        }
    }
    
    var routingBinding: Binding<Routing.CountryDetails> {
        Binding {
            self.viewRoutingState
        } set: {
            self.appStatePublisher.value.routing.countryDetails = $0
        }
    }
    
    init(_ appState: Store<AppState>) {
        print("............CountryDetails \(appState.value)")
        appStatePublisher = appState
        viewRoutingState = appState.value.routing.countryDetails
        appStatePublisher
            .map(\.routing.countryDetails)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.viewRoutingState, on: self)
          /*  .sink {[weak self] globalRoute in
                print("SINKSINKSINK in Details \(globalRoute)")
                self?.viewRoutingState = globalRoute
            }*/
            .store(in: &cancellables)
    }
    
}
