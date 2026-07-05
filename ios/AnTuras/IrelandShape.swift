import SwiftUI

// MARK: - Éire, the island itself.
// The whole island — the app's cultural ground (D1) — traced from Natural
// Earth 1:50m land polygons and simplified to 241 points. Slightly angular
// on purpose: a coastline cut with a chisel, not drawn with a pen.
//
// Points are normalized to a 0…1 box whose height is the island's full
// north–south extent; the island is 0.752 as wide as it is tall.
// Projection: equirectangular about 53.5°N (x = lon·cos 53.5°, y = −lat),
// then shifted/scaled by the constants below. `point(lat:lon:)` projects
// any coordinate into the same box so waypoints land where they should.

enum Ireland {
    /// Width of the island in the normalized box (height is 1).
    static let aspect: CGFloat = 0.7519

    private static let cosLat = 0.594823
    private static let minX = -6.180348
    private static let minY = -55.365820
    private static let span = 3.892090

    /// Project a geographic coordinate into the normalized outline box.
    static func point(lat: Double, lon: Double) -> CGPoint {
        CGPoint(x: (lon * cosLat - minX) / span,
                y: (-lat - minY) / span)
    }

    /// Fit the normalized box inside `rect`, centred.
    static func fit(in rect: CGRect) -> CGRect {
        let scale = min(rect.width / aspect, rect.height)
        let w = aspect * scale
        let h = scale
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }

    static let outline: [CGPoint] = [
        CGPoint(x: 0.4908, y: 0.0794), CGPoint(x: 0.5027, y: 0.0816), CGPoint(x: 0.5134, y: 0.0733),
        CGPoint(x: 0.5262, y: 0.0471), CGPoint(x: 0.5642, y: 0.0443), CGPoint(x: 0.5984, y: 0.0321),
        CGPoint(x: 0.6512, y: 0.0381), CGPoint(x: 0.6655, y: 0.0569), CGPoint(x: 0.6731, y: 0.0864),
        CGPoint(x: 0.6909, y: 0.1155), CGPoint(x: 0.7142, y: 0.1409), CGPoint(x: 0.7152, y: 0.1564),
        CGPoint(x: 0.7068, y: 0.1647), CGPoint(x: 0.6894, y: 0.1751), CGPoint(x: 0.6895, y: 0.1861),
        CGPoint(x: 0.7109, y: 0.1780), CGPoint(x: 0.7348, y: 0.1805), CGPoint(x: 0.7431, y: 0.1917),
        CGPoint(x: 0.7519, y: 0.2224), CGPoint(x: 0.7498, y: 0.2374), CGPoint(x: 0.7434, y: 0.2327),
        CGPoint(x: 0.7369, y: 0.2192), CGPoint(x: 0.7212, y: 0.2097), CGPoint(x: 0.7250, y: 0.2281),
        CGPoint(x: 0.7235, y: 0.2528), CGPoint(x: 0.7385, y: 0.2556), CGPoint(x: 0.7310, y: 0.2809),
        CGPoint(x: 0.7156, y: 0.2878), CGPoint(x: 0.6975, y: 0.2903), CGPoint(x: 0.6899, y: 0.3108),
        CGPoint(x: 0.6805, y: 0.3280), CGPoint(x: 0.6680, y: 0.3377), CGPoint(x: 0.6527, y: 0.3358),
        CGPoint(x: 0.6376, y: 0.3281), CGPoint(x: 0.6441, y: 0.3372), CGPoint(x: 0.6470, y: 0.3465),
        CGPoint(x: 0.6357, y: 0.3500), CGPoint(x: 0.6239, y: 0.3481), CGPoint(x: 0.6182, y: 0.3542),
        CGPoint(x: 0.6178, y: 0.3660), CGPoint(x: 0.6218, y: 0.3812), CGPoint(x: 0.6297, y: 0.3920),
        CGPoint(x: 0.6412, y: 0.4432), CGPoint(x: 0.6493, y: 0.4595), CGPoint(x: 0.6512, y: 0.5074),
        CGPoint(x: 0.6478, y: 0.5137), CGPoint(x: 0.6641, y: 0.5844), CGPoint(x: 0.6668, y: 0.6266),
        CGPoint(x: 0.6510, y: 0.6574), CGPoint(x: 0.6451, y: 0.6751), CGPoint(x: 0.6405, y: 0.6943),
        CGPoint(x: 0.6378, y: 0.7252), CGPoint(x: 0.6182, y: 0.7615), CGPoint(x: 0.6002, y: 0.7761),
        CGPoint(x: 0.6213, y: 0.8014), CGPoint(x: 0.6040, y: 0.8127), CGPoint(x: 0.5852, y: 0.8163),
        CGPoint(x: 0.5644, y: 0.8099), CGPoint(x: 0.5514, y: 0.8107), CGPoint(x: 0.5349, y: 0.8239),
        CGPoint(x: 0.5312, y: 0.8215), CGPoint(x: 0.5234, y: 0.8007), CGPoint(x: 0.5176, y: 0.8222),
        CGPoint(x: 0.5056, y: 0.8290), CGPoint(x: 0.4851, y: 0.8275), CGPoint(x: 0.4507, y: 0.8333),
        CGPoint(x: 0.4375, y: 0.8394), CGPoint(x: 0.4280, y: 0.8600), CGPoint(x: 0.4226, y: 0.8666),
        CGPoint(x: 0.3848, y: 0.8814), CGPoint(x: 0.3726, y: 0.8993), CGPoint(x: 0.3565, y: 0.9096),
        CGPoint(x: 0.3431, y: 0.9127), CGPoint(x: 0.3209, y: 0.8929), CGPoint(x: 0.3028, y: 0.8934),
        CGPoint(x: 0.3085, y: 0.8966), CGPoint(x: 0.3122, y: 0.9039), CGPoint(x: 0.3140, y: 0.9180),
        CGPoint(x: 0.3119, y: 0.9318), CGPoint(x: 0.3030, y: 0.9388), CGPoint(x: 0.2923, y: 0.9401),
        CGPoint(x: 0.2754, y: 0.9544), CGPoint(x: 0.2530, y: 0.9583), CGPoint(x: 0.2410, y: 0.9714),
        CGPoint(x: 0.1672, y: 0.9937), CGPoint(x: 0.1417, y: 0.9858), CGPoint(x: 0.0998, y: 1.0000),
        CGPoint(x: 0.0848, y: 0.9975), CGPoint(x: 0.1039, y: 0.9666), CGPoint(x: 0.1296, y: 0.9510),
        CGPoint(x: 0.1322, y: 0.9467), CGPoint(x: 0.1239, y: 0.9446), CGPoint(x: 0.0751, y: 0.9555),
        CGPoint(x: 0.0581, y: 0.9647), CGPoint(x: 0.0412, y: 0.9674), CGPoint(x: 0.0490, y: 0.9533),
        CGPoint(x: 0.0898, y: 0.9213), CGPoint(x: 0.0979, y: 0.9099), CGPoint(x: 0.1209, y: 0.8971),
        CGPoint(x: 0.0468, y: 0.9236), CGPoint(x: 0.0273, y: 0.9204), CGPoint(x: 0.0227, y: 0.9130),
        CGPoint(x: 0.0075, y: 0.9164), CGPoint(x: 0.0018, y: 0.8985), CGPoint(x: 0.0242, y: 0.8713),
        CGPoint(x: 0.0373, y: 0.8596), CGPoint(x: 0.0679, y: 0.8443), CGPoint(x: 0.0734, y: 0.8332),
        CGPoint(x: 0.0664, y: 0.8297), CGPoint(x: 0.0215, y: 0.8325), CGPoint(x: 0.0000, y: 0.8301),
        CGPoint(x: 0.0051, y: 0.8116), CGPoint(x: 0.0274, y: 0.7950), CGPoint(x: 0.0395, y: 0.7923),
        CGPoint(x: 0.0502, y: 0.7939), CGPoint(x: 0.0692, y: 0.8037), CGPoint(x: 0.0945, y: 0.8005),
        CGPoint(x: 0.0839, y: 0.7899), CGPoint(x: 0.0821, y: 0.7683), CGPoint(x: 0.0740, y: 0.7611),
        CGPoint(x: 0.0843, y: 0.7510), CGPoint(x: 0.0961, y: 0.7450), CGPoint(x: 0.1158, y: 0.7243),
        CGPoint(x: 0.2039, y: 0.7052), CGPoint(x: 0.2456, y: 0.6902), CGPoint(x: 0.2242, y: 0.6818),
        CGPoint(x: 0.2140, y: 0.6707), CGPoint(x: 0.1975, y: 0.6931), CGPoint(x: 0.1857, y: 0.7017),
        CGPoint(x: 0.1522, y: 0.7062), CGPoint(x: 0.1267, y: 0.6968), CGPoint(x: 0.1178, y: 0.7048),
        CGPoint(x: 0.0957, y: 0.7158), CGPoint(x: 0.0724, y: 0.7184), CGPoint(x: 0.0994, y: 0.6982),
        CGPoint(x: 0.1338, y: 0.6641), CGPoint(x: 0.1414, y: 0.6533), CGPoint(x: 0.1523, y: 0.6345),
        CGPoint(x: 0.1489, y: 0.6262), CGPoint(x: 0.1419, y: 0.6214), CGPoint(x: 0.1667, y: 0.5828),
        CGPoint(x: 0.1755, y: 0.5758), CGPoint(x: 0.1914, y: 0.5746), CGPoint(x: 0.2129, y: 0.5662),
        CGPoint(x: 0.2231, y: 0.5546), CGPoint(x: 0.1910, y: 0.5435), CGPoint(x: 0.1339, y: 0.5466),
        CGPoint(x: 0.1236, y: 0.5380), CGPoint(x: 0.1205, y: 0.5249), CGPoint(x: 0.1168, y: 0.5219),
        CGPoint(x: 0.0863, y: 0.5255), CGPoint(x: 0.0786, y: 0.5198), CGPoint(x: 0.0909, y: 0.5064),
        CGPoint(x: 0.0751, y: 0.5032), CGPoint(x: 0.0590, y: 0.5058), CGPoint(x: 0.0457, y: 0.5018),
        CGPoint(x: 0.0453, y: 0.4934), CGPoint(x: 0.0513, y: 0.4850), CGPoint(x: 0.0434, y: 0.4770),
        CGPoint(x: 0.0418, y: 0.4669), CGPoint(x: 0.0502, y: 0.4620), CGPoint(x: 0.0594, y: 0.4636),
        CGPoint(x: 0.0782, y: 0.4562), CGPoint(x: 0.1023, y: 0.4525), CGPoint(x: 0.0817, y: 0.4452),
        CGPoint(x: 0.0734, y: 0.4389), CGPoint(x: 0.0747, y: 0.4210), CGPoint(x: 0.0986, y: 0.4071),
        CGPoint(x: 0.1241, y: 0.4009), CGPoint(x: 0.1222, y: 0.3917), CGPoint(x: 0.1240, y: 0.3818),
        CGPoint(x: 0.0982, y: 0.3789), CGPoint(x: 0.0728, y: 0.3859), CGPoint(x: 0.0755, y: 0.3670),
        CGPoint(x: 0.0816, y: 0.3498), CGPoint(x: 0.0816, y: 0.3264), CGPoint(x: 0.0697, y: 0.3316),
        CGPoint(x: 0.0683, y: 0.3145), CGPoint(x: 0.0631, y: 0.3028), CGPoint(x: 0.0455, y: 0.3109),
        CGPoint(x: 0.0459, y: 0.2955), CGPoint(x: 0.0510, y: 0.2847), CGPoint(x: 0.0603, y: 0.2800),
        CGPoint(x: 0.0865, y: 0.2818), CGPoint(x: 0.1029, y: 0.2737), CGPoint(x: 0.1265, y: 0.2716),
        CGPoint(x: 0.1642, y: 0.2742), CGPoint(x: 0.1902, y: 0.2971), CGPoint(x: 0.1969, y: 0.2930),
        CGPoint(x: 0.2072, y: 0.2785), CGPoint(x: 0.2121, y: 0.2769), CGPoint(x: 0.2512, y: 0.2832),
        CGPoint(x: 0.2754, y: 0.2915), CGPoint(x: 0.2819, y: 0.2889), CGPoint(x: 0.2784, y: 0.2729),
        CGPoint(x: 0.2701, y: 0.2618), CGPoint(x: 0.2806, y: 0.2472), CGPoint(x: 0.2933, y: 0.2374),
        CGPoint(x: 0.3301, y: 0.2206), CGPoint(x: 0.3358, y: 0.2019), CGPoint(x: 0.3449, y: 0.1863),
        CGPoint(x: 0.2955, y: 0.1944), CGPoint(x: 0.2485, y: 0.1759), CGPoint(x: 0.2560, y: 0.1628),
        CGPoint(x: 0.2659, y: 0.1554), CGPoint(x: 0.2830, y: 0.1498), CGPoint(x: 0.2847, y: 0.1429),
        CGPoint(x: 0.3076, y: 0.1224), CGPoint(x: 0.3024, y: 0.1030), CGPoint(x: 0.3052, y: 0.0887),
        CGPoint(x: 0.3155, y: 0.0795), CGPoint(x: 0.3233, y: 0.0564), CGPoint(x: 0.3443, y: 0.0529),
        CGPoint(x: 0.3644, y: 0.0438), CGPoint(x: 0.3954, y: 0.0426), CGPoint(x: 0.4034, y: 0.0463),
        CGPoint(x: 0.4016, y: 0.0302), CGPoint(x: 0.4162, y: 0.0281), CGPoint(x: 0.4219, y: 0.0313),
        CGPoint(x: 0.4244, y: 0.0427), CGPoint(x: 0.4310, y: 0.0500), CGPoint(x: 0.4331, y: 0.0626),
        CGPoint(x: 0.4286, y: 0.0723), CGPoint(x: 0.4212, y: 0.0799), CGPoint(x: 0.4280, y: 0.0876),
        CGPoint(x: 0.4175, y: 0.1015), CGPoint(x: 0.4450, y: 0.0819), CGPoint(x: 0.4414, y: 0.0568),
        CGPoint(x: 0.4369, y: 0.0442), CGPoint(x: 0.4390, y: 0.0303), CGPoint(x: 0.4481, y: 0.0216),
        CGPoint(x: 0.4720, y: 0.0172), CGPoint(x: 0.4622, y: 0.0014), CGPoint(x: 0.4709, y: 0.0000),
        CGPoint(x: 0.4804, y: 0.0033), CGPoint(x: 0.4944, y: 0.0156), CGPoint(x: 0.5240, y: 0.0329),
        CGPoint(x: 0.5095, y: 0.0482), CGPoint(x: 0.4917, y: 0.0588), CGPoint(x: 0.4847, y: 0.0704),
        CGPoint(x: 0.4908, y: 0.0794),
    ]
}

/// The island as a SwiftUI Shape, scaled to fit its rect.
struct IrelandOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let box = Ireland.fit(in: rect)
        var path = Path()
        let pts = Ireland.outline
        guard let first = pts.first else { return path }
        func place(_ p: CGPoint) -> CGPoint {
            CGPoint(x: box.minX + p.x * box.height, y: box.minY + p.y * box.height)
        }
        path.move(to: place(first))
        for p in pts.dropFirst() { path.addLine(to: place(p)) }
        path.closeSubpath()
        return path
    }
}
