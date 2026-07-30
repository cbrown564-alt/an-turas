import SwiftUI

struct InteractionStudyDestination: View {
    let study: InteractionStudyID

    var body: some View {
        switch study {
        case .soundMatch:
            SoundMatchInteractionStudy()
        case .sentenceFlow:
            SentenceFlowInteractionStudy()
        case .coastPlacement:
            CoastPlacementInteractionStudy()
        }
    }
}
