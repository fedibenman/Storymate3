import SwiftUI

struct Base64Image: View {
    let base64String: String?
    let placeholder: String
    
    var body: some View {
        if let base64String = base64String, let uiImage = UIImage(base64: base64String) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: placeholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

extension UIImage {
    convenience init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        self.init(data: data)
    }
}

struct Base64Image_Previews: PreviewProvider {
    static var previews: some View {
        Base64Image(base64String: nil, placeholder: "photo")
    }
}
