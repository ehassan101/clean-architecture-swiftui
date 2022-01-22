//
//  CountriesList.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 24.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct CountriesList: View {
    
    @ObservedObject var viewModel: CountriesListViewModel
    @State private var countriesSearch = CountriesSearch()
    @State private(set) var countries: Loadable<LazyList<Country>>
   /* @State private var routingState: Routing = .init()
    private var routingBinding: Binding<Routing> {
       return $routingState.dispatched(to: injected.appState, \.routing.countriesList)
     /*   Binding {
            //return routingState
            return injected.appState.value.routing.countriesList //[\.routing.countriesList]
        } set: {
            print("bbbbbbbbbbb \($0)")
            injected.appState[\.routing.countriesList] = $0
            //routingState = $0
        } */

    }*/
    @State private var canRequestPushPermission: Bool = false
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.locale) private var locale: Locale
    private let localeContainer = LocaleReader.Container()
    
    let inspection = Inspection<Self>()
    
    init(countries: Loadable<LazyList<Country>> = .notRequested, viewModel: CountriesListViewModel) {
        self.viewModel = viewModel
        self._countries = .init(initialValue: countries)
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                self.content
                    .navigationBarItems(trailing: self.permissionsButton)
                    .navigationBarTitle("Countries")
                    .navigationBarHidden(self.countriesSearch.keyboardHeight > 0)
                    .animation(.easeOut(duration: 0.3))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(LocaleReader(container: localeContainer))
        .onReceive(keyboardHeightUpdate) { self.countriesSearch.keyboardHeight = $0 }
        .onReceive(canRequestPushPermissionUpdate) { self.canRequestPushPermission = $0 }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    private var content: AnyView {
        switch countries {
        case .notRequested: return AnyView(notRequestedView)
        case let .isLoading(last, _): return AnyView(loadingView(last))
        case let .loaded(countries): return AnyView(loadedView(countries, showSearch: true, showLoading: false))
        case let .failed(error): return AnyView(failedView(error))
        }
    }
    
    private var permissionsButton: some View {
        Group {
            if canRequestPushPermission {
                Button(action: requestPushPermission, label: { Text("Allow Push") })
            } else {
                EmptyView()
            }
        }
    }
}

private extension CountriesList {
    
    struct LocaleReader: EnvironmentalModifier {
        
        /**
         Retains the locale, provided by the Environment.
         Variable `@Environment(\.locale) var locale: Locale`
         from the view is not accessible when searching by name
         */
        class Container {
            var locale: Locale = .backendDefault
        }
        let container: Container
        
        func resolve(in environment: EnvironmentValues) -> some ViewModifier {
            container.locale = environment.locale
            return DummyViewModifier()
        }
        
        private struct DummyViewModifier: ViewModifier {
            func body(content: Content) -> some View {
                // Cannot return just `content` because SwiftUI
                // flattens modifiers that do nothing to the `content`
                content.onAppear()
            }
        }
    }
}

// MARK: - Side Effects

private extension CountriesList {
    func reloadCountries() {
        injected.interactors.countriesInteractor
            .load(countries: $countries,
                  search: countriesSearch.searchText,
                  locale: localeContainer.locale)
    }
    
    func requestPushPermission() {
        injected.interactors.userPermissionsInteractor
            .request(permission: .pushNotifications)
    }
}

// MARK: - Loading Content

private extension CountriesList {
    var notRequestedView: some View {
        Text("").onAppear(perform: reloadCountries)
    }
    
    func loadingView(_ previouslyLoaded: LazyList<Country>?) -> some View {
        if let countries = previouslyLoaded {
            return AnyView(loadedView(countries, showSearch: true, showLoading: true))
        } else {
            return AnyView(ActivityIndicatorView().padding())
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
            self.reloadCountries()
        })
    }
}

// MARK: - Displaying Content

private extension CountriesList {
    func loadedView(_ countries: LazyList<Country>, showSearch: Bool, showLoading: Bool) -> some View {
        VStack {
            if showSearch {
                SearchBar(text: $countriesSearch.searchText
                    .onSet { _ in
                        self.reloadCountries()
                    }
                )
            }
            if showLoading {
                ActivityIndicatorView().padding()
            }
            List(countries) { country in
                NavigationLink(
                    destination: LazyView { self.detailsView(country: country) },
                    tag: country.alpha3Code,
                    selection: viewModel.routingBinding.countryDetails) {
                        CountryCell(country: country)
                    }
                    .id(country.alpha3Code)
            }
            .id(countries.count)
        }.padding(.bottom, bottomInset)
    }
    
    func detailsView(country: Country) -> some View {
        let model = CountryDetailsViewModel(viewModel.appStatePublisher)
        return CountryDetails(country: country, viewModel: model)
    }
    
    var bottomInset: CGFloat {
        if #available(iOS 14, *) {
            return 0
        } else {
            return countriesSearch.keyboardHeight
        }
    }
}

struct LazyView<Content: View>: View {
    
    let content: () -> Content
    
    var body: some View {
        content()
    }
}

// MARK: - Search State

extension CountriesList {
    struct CountriesSearch {
        var searchText: String = ""
        var keyboardHeight: CGFloat = 0
    }
}

// MARK: - Routing


// MARK: - State Updates

private extension CountriesList {
    
    var keyboardHeightUpdate: AnyPublisher<CGFloat, Never> {
        injected.appState.updates(for: \.system.keyboardHeight)
    }
    
    var canRequestPushPermissionUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: AppState.permissionKeyPath(for: .pushNotifications))
            .map { $0 == .notRequested || $0 == .denied }
            .eraseToAnyPublisher()
    }
}

/*
#if DEBUG
struct CountriesList_Previews: PreviewProvider {
    static var previews: some View {
        CountriesList(countries: .loaded(Country.mockedData.lazyList))
            .inject(.preview)
    }
}
#endif
*/
