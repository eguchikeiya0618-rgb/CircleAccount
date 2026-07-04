import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let activity: Activity

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var qrText: String {
        "SIRIUS_ACTIVITY:\(activity.id)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("SiRiUS")
                    .font(.system(size: 42, weight: .black, design: .serif))

                VStack(spacing: 6) {
                    Text("活動受付QR")
                        .font(.title3)
                        .bold()

                    Text(activity.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Image(uiImage: generateQRCode(from: qrText))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)

                VStack(spacing: 6) {
                    Text("このQRコードを読み取ると参加登録できます")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("活動ID：\(activity.id)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("QRコード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), from: outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)).extent) {
            return UIImage(cgImage: cgImage)
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

#Preview {
    QRCodeView(
        activity: Activity(
            id: "sampleActivityId",
            title: "SiRiUS 練習",
            date: Date(),
            startTime: Date(),
            endTime: Date(),
            place: "三苫小学校",
            fee: 600,
            capacity: 20,
            memo: "",
            createdBy: "",
            participants: [],
            waitingList: [],
            attendance: [],
            paidMembers: []
        )
    )
}
