//
//  ContentView 2.swift
//  StoryMates
//
//  Created by mac on 11/21/25.
//


import SwiftUI

struct Track: View {
    var body: some View {
        NavigationView {
            VStack {
                // Search Screen
                SearchScreen()
                    .padding()
                
                Spacer()
                
                // Mission List Screen
                MissionListScreen()
                    .padding()
            }
            .navigationTitle("Game Progress Tracker")
        }
    }
}

struct SearchScreen: View {
    @State private var gameName: String = ""
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                TextField("Search for a game", text: $gameName)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button(action: {
                    // Trigger search action here
                }) {
                    Text("Search")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.leading, 10)
            }
            .padding(.top, 30)
            
            // Loading Indicator (optional)
            if gameName.isEmpty == false {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding(.top, 20)
            }
        }
    }
}

struct MissionListScreen: View {
    var body: some View {
        VStack {
            // Game Title
            Text("Assassin's Creed Mirage")
                .font(.custom("PressStart2P-Regular", size: 24))
                .foregroundColor(.black)
            
            // Progress Bar
            ProgressBar(progress: 0.7)
                .frame(height: 20)
                .padding(.top, 10)
            
            // Mission List
            List {
                ForEach(0..<5, id: \.self) { index in
                    MissionRow(missionName: "Mission \(index + 1): Complete the Quest", isCompleted: index % 2 == 0)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct MissionRow: View {
    var missionName: String
    var isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .red)
            
            Text(missionName)
                .font(.custom("PressStart2P-Regular", size: 14))
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct ProgressBar: View {
    var progress: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .frame(height: 10)
                .foregroundColor(Color.gray.opacity(0.3))
            Capsule()
                .frame(width: progress * 300, height: 10)
                .foregroundColor(Color.green)
        }
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
