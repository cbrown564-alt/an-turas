import SwiftUI
import UIKit

struct TNAInterrogatoryFolio: View {
    let highlightName: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image("SP63170F201")
                .resizable()
                .scaledToFit()
                .overlay {
                    GeometryReader { geometry in
                        if highlightName {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Theme.rust, lineWidth: 3)
                                .background(Theme.rust.opacity(0.10))
                                .frame(
                                    width: geometry.size.width * 0.58,
                                    height: geometry.size.height * 0.065
                                )
                                .offset(
                                    x: geometry.size.width * 0.33,
                                    y: geometry.size.height * 0.025
                                )
                                .transition(.opacity)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .background(Color.black.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(
                    "Original manuscript page. The first page of the July 1593 interrogatory, The National Archives, SP 63/170, folio 201."
                )
            Text("The National Archives, SP 63/170, f. 201 · Crown copyright · educational use")
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

/// Loads loose illustration files from the bundled `art` folder. SwiftUI's
/// asset-name initializer only searches asset catalogs and otherwise logs a
/// misleading missing-image warning for folder resources.
struct StoryArtImage: View {
    let name: String

    var body: some View {
        if let image = load() {
            Image(uiImage: image).resizable()
        } else {
            ZStack {
                Theme.sunk
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.inkFaint)
            }
            .accessibilityLabel("Illustration unavailable")
        }
    }

    private func load() -> UIImage? {
        for fileExtension in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(
                forResource: name,
                withExtension: fileExtension,
                subdirectory: "art"
            ),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        // Atmosphere stills for chapter openings also live in the asset catalog.
        return UIImage(named: name)
    }
}
