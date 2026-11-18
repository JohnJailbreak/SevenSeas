import SwiftUI

/// One entry per row of Themes.plist in Dopamine's format: background image, menu colour,
/// window colour (AARRGGBB), blur radius in image pixels and the title shadow flag.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let thumbName: String
    let menu: Color
    let window: Color
    let blur: CGFloat
    let titleShadow: Bool

    static let all: [Theme] = [
        Theme(id: "morninghaze", name: "Morning Haze", imageName: "Background_MorningHaze", thumbName: "Thumb_MorningHaze",
              menu: Color(argb: 0x942E475C), window: Color(argb: 0x99090E12), blur: 38, titleShadow: true),
        Theme(id: "cleardawn", name: "Clear Dawn", imageName: "Background_ClearDawn", thumbName: "Thumb_ClearDawn",
              menu: Color(argb: 0x9E38393C), window: Color(argb: 0x99101112), blur: 38, titleShadow: true),
        Theme(id: "cumulusdrift", name: "Cumulus Drift", imageName: "Background_CumulusDrift", thumbName: "Thumb_CumulusDrift",
              menu: Color(argb: 0x9E2E3A46), window: Color(argb: 0x990C0F12), blur: 38, titleShadow: true),
        Theme(id: "highcirrus", name: "High Cirrus", imageName: "Background_HighCirrus", thumbName: "Thumb_HighCirrus",
              menu: Color(argb: 0x9E344352), window: Color(argb: 0x990C0F13), blur: 38, titleShadow: false),
        Theme(id: "goldenmorning", name: "Golden Morning", imageName: "Background_GoldenMorning", thumbName: "Thumb_GoldenMorning",
              menu: Color(argb: 0x9E393837), window: Color(argb: 0x99111010), blur: 38, titleShadow: true),
        Theme(id: "silverovercast", name: "Silver Overcast", imageName: "Background_SilverOvercast", thumbName: "Thumb_SilverOvercast",
              menu: Color(argb: 0x9E34393D), window: Color(argb: 0x990E0F10), blur: 38, titleShadow: true),
        Theme(id: "rosehaze", name: "Rose Haze", imageName: "Background_RoseHaze", thumbName: "Thumb_RoseHaze",
              menu: Color(argb: 0x9E483F4C), window: Color(argb: 0x99100E11), blur: 38, titleShadow: true),
        Theme(id: "deepzenith", name: "Deep Zenith", imageName: "Background_DeepZenith", thumbName: "Thumb_DeepZenith",
              menu: Color(argb: 0x7A283950), window: Color(argb: 0x80080B10), blur: 38, titleShadow: false),
        Theme(id: "seamist", name: "Sea Mist", imageName: "Background_SeaMist", thumbName: "Thumb_SeaMist",
              menu: Color(argb: 0x9E313F40), window: Color(argb: 0x990D1011), blur: 38, titleShadow: true),
        Theme(id: "lilacmorning", name: "Lilac Morning", imageName: "Background_LilacMorning", thumbName: "Thumb_LilacMorning",
              menu: Color(argb: 0x9E413B50), window: Color(argb: 0x990F0D12), blur: 38, titleShadow: true)
    ]
}
