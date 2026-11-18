import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            RootContent(size: geo.size)
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(model.sheet == .closed ? .automatic : .hidden)
    }
}

struct RootContent: View {
    @EnvironmentObject var model: AppModel
    let size: CGSize

    var body: some View {
        let layout = MainLayout(size: size)
        let windowOpen = model.window != .closed
        ZStack(alignment: .topLeading) {
            Color.black
            BackgroundView(theme: model.theme, dimmed: windowOpen, size: size)
            MainScreen(layout: layout)
                .scaleEffect(windowOpen ? 0.9 : 1.0)
                .opacity(windowOpen ? 0.0 : 1.0)
                .allowsHitTesting(!windowOpen)
            if windowOpen {
                WindowHost(size: size)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(Anim.window, value: model.window)
    }
}

/// Dopamine's themed background: the image is blurred once, shown 100 pt taller than the
/// screen at both ends, and dims to 40% while a window is open.
struct BackgroundView: View {
    let theme: Theme
    let dimmed: Bool
    let size: CGSize
    @StateObject private var loader = BackgroundLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height + 200)
                    .clipped()
            }
        }
        .frame(width: size.width, height: size.height + 200)
        .opacity(dimmed ? 0.4 : 1.0)
        .offset(y: -100)
        .animation(.easeInOut(duration: 0.3), value: dimmed)
        .onAppear { loader.load(theme) }
        .onChange(of: theme.id) { _ in loader.load(theme) }
    }
}

final class BackgroundLoader: ObservableObject {
    @Published var image: UIImage?
    private static var cache: [String: UIImage] = [:]
    private var wantedID: String = ""

    func load(_ theme: Theme) {
        let id = theme.id
        wantedID = id
        if let hit = BackgroundLoader.cache[id] {
            image = hit
            return
        }
        let name = theme.imageName
        let radius = theme.blur
        DispatchQueue.global(qos: .userInitiated).async {
            guard let source = UIImage(named: name),
                  let blurred = source.sevenSeasBlurred(radius: radius) else { return }
            DispatchQueue.main.async {
                BackgroundLoader.cache[id] = blurred
                if self.wantedID == id {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.image = blurred
                    }
                }
            }
        }
    }
}
