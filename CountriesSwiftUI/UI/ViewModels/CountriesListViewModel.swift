//
//  ViewModel.swift
//  CountriesSwiftUI
//
//  Created by Hiba Hassan on 1/17/22.
//  Copyright © 2022 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

class CountriesListViewModel: ObservableObject {
    
    private(set) var appStatePublisher: Store<AppState>
    
    var routingBinding: Binding<Routing.CountriesList> {
        Binding {
            self.viewRoutingState // view reads this value; we want the appState to update this local copy before aking the view react to chnages and navigate
        } set: {
            self.appStatePublisher.value.routing.countriesList = $0
        }
    }
    
    @Published var viewRoutingState: Routing.CountriesList
    
    var cancellables = [AnyCancellable]()
    
    init(_ appState: Store<AppState>) {
        print("............CountriesList \(appState.value)")
        appStatePublisher = appState
        viewRoutingState = appState.value.routing.countriesList
        appStatePublisher
            .map(\.routing.countriesList)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.viewRoutingState, on: self)
          /*  .sink {[weak self] globalRoute in
                print("SINKSINKSINK list: \(globalRoute)")
                self?.viewRoutingState = globalRoute
            } */
            .store(in: &cancellables)
    }
}
