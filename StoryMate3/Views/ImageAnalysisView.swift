import SwiftUI
import PhotosUI

struct ImageAnalysisView: View {
    @StateObject private var viewModel = ImageAnalysisViewModel()
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.12, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button(action: onBack) {
                        Image("x_icon")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    
                    Text("IMAGE ANALYSIS")
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color(red: 0.16, green: 0.16, blue: 0.16))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Selection Area
                        Button(action: { showImagePicker = true }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(8)
                            } else {
                                VStack(spacing: 12) {
                                    Image("add_image_button")
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(.gray)
                                    
                                    Text("Tap to select an image")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(Color(red: 0.16, green: 0.16, blue: 0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Analyze Button
                        Button(action: {
                            if let image = selectedImage {
                                Task {
                                    await viewModel.analyzeImage(image)
                                }
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("ANALYZE IMAGE")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.3, green: 0.8, blue: 0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .disabled(selectedImage == nil || viewModel.isLoading)
                        
                        // Error Message
                        if let error = viewModel.error {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(nil)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(red: 0.8, green: 0.18, blue: 0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Loading State
                        if viewModel.isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.3, green: 0.8, blue: 0.3)))
                                
                                Text("Analyzing image...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Analysis Results
                        if let result = viewModel.analysisResult {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analysis Results")
                                    .font(.custom("PressStart2P-Regular", size: 16))
                                    .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.3))
                                
                                Text(result)
                                    .font(.custom("PressStart2P-Regular", size: 12))
                                    .foregroundColor(.white)
                                  
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(red: 0.16, green: 0.16, blue: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
            }
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: Binding(
                get: { nil as PhotosPickerItem? },
                set: { item in
                    if let item = item {
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                                viewModel.clearResult()
                            }
                        }
                    }
                }
            ),
            matching: .images
        )
    }
}

#Preview {
    ImageAnalysisView(onBack: {})
}
