//
//  FlagDetailsView.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct FlagDetailsView: View {
    
    @Environment(\.injected) private var injected
  /*  @State private var routingState: Routing = .init()
    private var routingBinding: Binding<Routing> {
        $routingState.dispatched(to: injected.appState, \.routing.countryFlag)
    } */
    let country: Country
    @Binding var isDisplayed: Bool
    let inspection = Inspection<Self>()
    
    var body: some View {
        NavigationView {
            VStack {
                country.flag.map { url in
                    HStack {
                        Spacer()
                        SVGImageView(imageURL: url)
                            .frame(width: 300, height: 200)
                        Spacer()
                    }
                }
                closeButton.padding(.top, 40)
            }
            .navigationBarTitle(Text(country.name), displayMode: .inline)
        }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
        //.attachEnvironmentOverrides()
    }
    
    private var closeButton: some View {
        Button(action: {
            self.isDisplayed = false
        }, label: { Text("Close") })
    }
}

/*
extension ModalDetailsView {
    struct Routing: Equatable {
        var showFlag: Bool = false
    }
}

extension ModalDetailsView {
    var routingUpdate: AnyPublisher<Routing, Never> {
        injected.appState.updates(for: \.routing.countryFlag)
    }
}
 
 */

/*
#if DEBUG
struct ModalDetailsView_Previews: PreviewProvider {
    
    @State static var isDisplayed: Bool = true
    
    static var previews: some View {
        ModalDetailsView(country: Country.mockedData[0], isDisplayed: $isDisplayed)
            .inject(.preview)
    }
}
#endif
*/
