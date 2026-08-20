//
//  ContentView.swift
//  BookMeUp
//

import SwiftUI

/// Hosts the shared stores and hands off to the role's navigation.
///
/// `BookMeUpStore` holds what happens — bookings, clients, passport records — and is
/// shared by every environment. `BusinessStore` holds how the business is set up:
/// locations, people, roles and rules. Neither duplicates the other.
struct ContentView: View {
    @State private var store = BookMeUpStore()
    @State private var business = BusinessStore()
    @AppStorage("bookmeup.devRole") private var storedRole: String = AppRole.client.rawValue

    private var roleBinding: Binding<AppRole> {
        Binding(
            get: { AppRole(rawValue: storedRole) ?? .client },
            set: { storedRole = $0.rawValue }
        )
    }

    var body: some View {
        RootView(role: roleBinding)
            .environment(store)
            .environment(business)
    }
}

#Preview {
    ContentView()
}
