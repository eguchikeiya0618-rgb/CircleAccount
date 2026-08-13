import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let activity: Activity

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private var qrText: String {
        "SIRIUS_ACTIVITY:\(activity.id)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors:[
                        .black,
                        Color(red:0.03,green:0.05,blue:0.16),
                        Color(red:0.12,green:0.04,blue:0.22)
                    ],
                    startPoint:.topLeading,
                    endPoint:.bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing:24){

                    VStack(spacing:8){
                        Text("SiRiUS")
                            .font(.system(size:42,weight:.black,design:.rounded))
                            .foregroundStyle(.white)

                        Text("ACTIVITY CHECK-IN")
                            .font(.caption)
                            .tracking(2)
                            .foregroundStyle(.cyan)

                        Text(activity.title)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack(spacing:18){
                        Image(uiImage: generateQRCode(from: qrText))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width:260,height:260)
                            .padding(18)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius:24))

                        Text("このQRコードを読み取ると参加登録できます")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))

                        Text("活動ID：\(activity.id)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius:30))
                }
                .padding()
            }
            .navigationTitle("QR CODE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for:.navigationBar)
            .toolbarColorScheme(.dark, for:.navigationBar)
        }
    }

    func generateQRCode(from string:String)->UIImage{
        filter.message=Data(string.utf8)
        guard let output=filter.outputImage else{
            return UIImage(systemName:"xmark.circle") ?? UIImage()
        }
        let transformed=output.transformed(by:CGAffineTransform(scaleX:10,y:10))
        guard let cg=context.createCGImage(transformed, from: transformed.extent) else{
            return UIImage(systemName:"xmark.circle") ?? UIImage()
        }
        return UIImage(cgImage:cg)
    }
}
