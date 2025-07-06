//  File: ContentView.swift
// This is tab view 

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Analytics")
                }
            
            SettingsView()  // Changed from SettingsPlaceholderView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}
