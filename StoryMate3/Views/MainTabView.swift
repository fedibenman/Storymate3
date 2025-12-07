import SwiftUI

struct MainTabView: View {
    init() {
        // Customize Tab Bar appearance with pixelated theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "PressStart2P-Regular", size: 8) ?? UIFont.systemFont(ofSize: 8)
        ]
        
        // Unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray,
            .font: UIFont(name: "PressStart2P-Regular", size: 8) ?? UIFont.systemFont(ofSize: 8)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Story Projects Tab - Main Community Page
            NavigationView {
                ProjectsMainScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Projects", systemImage: "doc.text.fill")
            }
            
            NavigationView {
                MyCollectionView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Collection", systemImage: "square.grid.2x2.fill")
            }
            
            NavigationView {
                ChatView(userId: "default_user")
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("AI Chat", systemImage: "message.fill")
            }
            
            NavigationView {
                ImageAnalysisView(onBack: {})
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Analysis", systemImage: "photo.badge.checkmark.fill")
            }
            
            NavigationView {
                CommunityView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Community", systemImage: "person.3.fill")
            }
            
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .accentColor(.white)
    }
}
