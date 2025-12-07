import SwiftUI

struct PreviewOverlay: View {
    let title: String
    let description: String
    let imageData: String?
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let imageData = imageData {
                Base64Image(base64String: imageData, placeholder: "photo")
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct PreviewOverlay_Previews: PreviewProvider {
    static var previews: some View {
        PreviewOverlay(
            title: "Preview Title",
            description: "This is a preview description",
            imageData: nil,
            onClose: {}
        )
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}
