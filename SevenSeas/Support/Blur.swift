import UIKit
import CoreImage

extension UIImage {
    /// Gaussian blur with the edges clamped, then cropped back to the original size.
    /// Same approach as Dopamine's themed backgrounds; `radius` is in image pixels.
    func sevenSeasBlurred(radius: CGFloat) -> UIImage? {
        guard let input = CIImage(image: self) else { return nil }
        let extent = input.extent
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(input.clampedToExtent(), forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage?.cropped(to: extent) else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
