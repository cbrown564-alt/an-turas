import SwiftUI

/// Simplified county geometry for the atlas. The source has been reduced for a
/// phone-sized map: coastlines and meaningful islands remain, while survey-level
/// detail that would render as visual noise has been removed.
struct CountyBoundary: Decodable {
    let en: String
    let rings: [[[Double]]]
}

enum CountyBoundaryAtlas {
    private struct Document: Decodable { let counties: [CountyBoundary] }

    static let counties: [CountyBoundary] = {
        guard let url = Bundle.main.url(forResource: "county-boundaries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(Document.self, from: data)
        else {
            fatalError("county-boundaries.json missing or malformed — the atlas cannot lose its counties.")
        }
        return document.counties
    }()

    static func path(for county: County, in rect: CGRect) -> Path? {
        let name = county.en == "Laois" ? "Laoighis" : county.en
        guard let boundary = counties.first(where: { $0.en == name }) else { return nil }

        let box = Ireland.fit(in: rect)
        func place(_ coordinate: [Double]) -> CGPoint {
            // The 26-county source keeps geographic coordinates. The six
            // northern regions are already normalized to Ireland's atlas box.
            let normalized: CGPoint
            if abs(coordinate[0]) <= 1, abs(coordinate[1]) <= 1 {
                normalized = CGPoint(x: coordinate[0], y: coordinate[1])
            } else {
                normalized = Ireland.point(lat: coordinate[1], lon: coordinate[0])
            }
            return CGPoint(x: box.minX + normalized.x * box.height,
                           y: box.minY + normalized.y * box.height)
        }

        var path = Path()
        for ring in boundary.rings where ring.count >= 3 {
            path.move(to: place(ring[0]))
            for coordinate in ring.dropFirst() { path.addLine(to: place(coordinate)) }
            path.closeSubpath()
        }
        return path
    }
}
