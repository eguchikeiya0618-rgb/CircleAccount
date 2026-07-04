import SwiftUI

struct ProfileImageView: View {
    let imageBase64: String
    let size: CGFloat

    var body: some View {
        Group {
            if let data = Data(base64Encoded: imageBase64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(.white)
                    .background(Color.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    ProfileImageView(imageBase64: "", size: 60)
}
