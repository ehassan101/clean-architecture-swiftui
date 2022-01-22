//
//  CountryDetails.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 25.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountryDetails: View {
    
    let country: Country
    
    @Environment(\.locale) var locale: Locale
    @Environment(\.injected) private var injected: DIContainer
    @State private var details: Loadable<Country.Details>
    @ObservedObject var viewModel: CountryDetailsViewModel
  /*  @State private var routingState: Routing.CountryDetails = .init()
    private var routingBinding: Binding<Routing.CountryDetails> {
      // return $routingState.dispatched(to: injected.appState, \.routing.countriesList)
        Binding {
            return routingState
        } set: {
            injected.appState[\.routing.countryDetails] = $0
            //routingState = $0
        }

    } */
    
    let inspection = Inspection<Self>()
    
    init(country: Country, details: Loadable<Country.Details> = .notRequested, viewModel: CountryDetailsViewModel) {
        self.country = country
        self.viewModel = viewModel
        self._details = .init(initialValue: details)
        print("........... View CountryDetails")
    }
    
    var body: some View {
        content
            .navigationBarTitle(country.name(locale: locale))
           /* .onReceive(routingUpdate) {
                guard self.routingState != $0 else { return }
                print(".onReceive(routingUpdate) new: \($0), self: \(self.routingState)")
                self.routingState = $0
            } */
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    private var content: AnyView {
        switch details {
        case .notRequested: return AnyView(notRequestedView)
        case .isLoading: return AnyView(loadingView)
        case let .loaded(countryDetails): return AnyView(loadedView(countryDetails))
        case let .failed(error): return AnyView(failedView(error))
        }
    }
}

// MARK: - Side Effects

private extension CountryDetails {
    func loadCountryDetails() {
        injected.interactors.countriesInteractor
            .load(countryDetails: $details, country: country)
    }
    
    func presentFlagSheet() {
        injected.appState[\.routing.countryDetails.flag] = true
        print("presentFlagSheet() \(injected.appState.value)")
    }
}

// MARK: - Loading Content

private extension CountryDetails {
    var notRequestedView: some View {
        Text("").onAppear {
            self.loadCountryDetails()
        }
    }
    
    var loadingView: some View {
        VStack {
            ActivityIndicatorView()
            Button(action: {
                self.details.cancelLoading()
            }, label: { Text("Cancel loading") })
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            self.loadCountryDetails()
        })
    }
}

// MARK: - Displaying Content

private extension CountryDetails {
    func loadedView(_ countryDetails: Country.Details) -> some View {
        List {
            country.flag.map { url in
                flagView(url: url)
            }
            basicInfoSectionView(countryDetails: countryDetails)
            if countryDetails.currencies.count > 0 {
                currenciesSectionView(currencies: countryDetails.currencies)
            }
            if countryDetails.neighbors.count > 0 {
                neighborsSectionView(neighbors: countryDetails.neighbors)
            }
        }
        .listStyle(GroupedListStyle())
        .sheet(isPresented: viewModel.routingBinding.flag) {
            injected.appState[\.routing.countryDetails.flag] = false
        } content: {
            flagDetailsView()
        }

    }
    
    func flagView(url: URL) -> some View {
        HStack {
            Spacer()
            SVGImageView(imageURL: url)
                .frame(width: 120, height: 80)
                .onTapGesture {
                    //self.presentFlagSheet()
                    viewModel.didRequestFlag = true
                }
            Spacer()
        }
    }
    
    func basicInfoSectionView(countryDetails: Country.Details) -> some View {
        Section(header: Text("Basic Info")) {
            DetailRow(leftLabel: Text(country.alpha3Code), rightLabel: "Code")
            DetailRow(leftLabel: Text("\(country.population)"), rightLabel: "Population")
            DetailRow(leftLabel: Text("\(countryDetails.capital)"), rightLabel: "Capital")
        }
    }
    
    func currenciesSectionView(currencies: [Country.Currency]) -> some View {
        Section(header: Text("Currencies")) {
            ForEach(currencies) { currency in
                DetailRow(leftLabel: Text(currency.title), rightLabel: Text(currency.code))
            }
        }
    }
    
    func neighborsSectionView(neighbors: [Country]) -> some View {
        Section(header: Text("Neighboring countries")) {
            ForEach(neighbors) { country in
                NavigationLink(destination: LazyView { self.neighbourDetailsView(country: country) } ) {
                    DetailRow(leftLabel: Text(country.name(locale: self.locale)), rightLabel: "")
                }
            }
        }
    }
    
    func neighbourDetailsView(country: Country) -> some View {
        let model = CountryDetailsViewModel(viewModel.appStatePublisher)
        return CountryDetails(country: country, viewModel: model)
    }
    
  /*  func modalDetailsView() -> some View {
        ModalDetailsView(country: country,
                         isDisplayed: routingBinding.detailsSheet)
            .inject(injected)
    } */
    
    func flagDetailsView() -> some View {
        FlagDetailsView(country: country, isDisplayed: viewModel.routingBinding.flag)
            .inject(injected)
    }
}

// MARK: - Helpers

private extension Country.Currency {
    var title: String {
        return name + (symbol.map {" " + $0} ?? "")
    }
}

// MARK: - Routing

/*
extension CountryDetails {
    struct Routing: Equatable {
        //var detailsSheet: Bool = false
        var flag: Bool = false
    }
}
 */

// MARK: - State Updates

private extension CountryDetails {
    
    var routingUpdate: AnyPublisher<Routing.CountryDetails, Never> {
        let p = injected.appState.updates(for: \.routing.countryDetails)
        print(".onReceive routingUpdate: AnyPublisher, \(p)")
        
        return p
    }
}

/*

// MARK: - Preview

#if DEBUG
struct CountryDetails_Previews: PreviewProvider {
    static var previews: some View {
        CountryDetails(country: Country.mockedData[0])
            .inject(.preview)
    }
}
#endif
*/
