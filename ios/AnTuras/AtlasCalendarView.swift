import SwiftUI
import UIKit

struct AtlasCalendarRitual {
    let month: Int
    let context: String
    let title: String
    let ga: String
    let en: String
    let sound: String
    let invitation: String

    static func current(date: Date = Date(), calendar: Calendar = .current) -> AtlasCalendarRitual {
        let month = calendar.component(.month, from: date)
        return all.first(where: { $0.month == month }) ?? all[0]
    }

    static let all: [AtlasCalendarRitual] = [
        .init(month: 1, context: "January · the turning year", title: "A word carried onward", ga: "Is buaine focal ná toice an tsaoil.", en: "A word outlasts the wealth of the world.", sound: "iss boo-in-eh fuk-ul naw tuk-eh un tay-il", invitation: "Return to one word whose story you still remember."),
        .init(month: 2, context: "February · first signs of spring", title: "Make shelter together", ga: "Ar scáth a chéile a mhaireann na daoine.", en: "People live in one another’s shelter.", sound: "er skaw a khay-leh a wir-en na dee-neh", invitation: "Carry the line to a person or place that helped your Irish."),
        .init(month: 3, context: "March · Irish in public", title: "Strength is shared", ga: "Ní neart go cur le chéile.", en: "There is no strength without joining together.", sound: "nee nyart guh kur leh khay-leh", invitation: "Use one familiar Irish line beyond the lesson today."),
        .init(month: 4, context: "April · longer light", title: "A word returns", ga: "Is buaine focal ná toice an tsaoil.", en: "A word outlasts the wealth of the world.", sound: "iss boo-in-eh fuk-ul naw tuk-eh un tay-il", invitation: "Open an evidence record and notice the word it made memorable."),
        .init(month: 5, context: "May · Bealtaine", title: "Meet the road together", ga: "Ní neart go cur le chéile.", en: "There is no strength without joining together.", sound: "nee nyart guh kur leh khay-leh", invitation: "Return to a county and say one place word aloud."),
        .init(month: 6, context: "June · midsummer light", title: "Shelter is something we do", ga: "Ar scáth a chéile a mhaireann na daoine.", en: "People live in one another’s shelter.", sound: "er skaw a khay-leh a wir-en na dee-neh", invitation: "Think of who made language feel possible rather than performative."),
        .init(month: 7, context: "July · the road between stories", title: "Let one word last", ga: "Is buaine focal ná toice an tsaoil.", en: "A word outlasts the wealth of the world.", sound: "iss boo-in-eh fuk-ul naw tuk-eh un tay-il", invitation: "Choose one county word and use it somewhere new."),
        .init(month: 8, context: "August · Lúnasa", title: "Work becomes shared memory", ga: "Ní neart go cur le chéile.", en: "There is no strength without joining together.", sound: "nee nyart guh kur leh khay-leh", invitation: "Return to a word for work, making or exchange."),
        .init(month: 9, context: "September · gathering in", title: "Carry what another person gave", ga: "Ar scáth a chéile a mhaireann na daoine.", en: "People live in one another’s shelter.", sound: "er skaw a khay-leh a wir-en na dee-neh", invitation: "Name one person, source or place behind what you learned."),
        .init(month: 10, context: "October · Samhain approaches", title: "Words cross the dark", ga: "Is buaine focal ná toice an tsaoil.", en: "A word outlasts the wealth of the world.", sound: "iss boo-in-eh fuk-ul naw tuk-eh un tay-il", invitation: "Return to a surviving inscription, name or document."),
        .init(month: 11, context: "November · the darker road", title: "Nobody carries the language alone", ga: "Ní neart go cur le chéile.", en: "There is no strength without joining together.", sound: "nee nyart guh kur leh khay-leh", invitation: "Let a familiar phrase return without turning it into debt."),
        .init(month: 12, context: "December · shortest light", title: "Stay in one another’s shelter", ga: "Ar scáth a chéile a mhaireann na daoine.", en: "People live in one another’s shelter.", sound: "er skaw a khay-leh a wir-en na dee-neh", invitation: "Close the year with one story you want to carry forward."),
    ]
}

struct AtlasCalendarView: View {
    @EnvironmentObject private var atlas: AtlasPrototypeModel
    @State private var now = Date()

    private var ritual: AtlasCalendarRitual { .current(date: now) }
    private var dayKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EditorialLayout.sectionGap) {
                EditorialScreenHeader(
                    context: "An Féilire · the real calendar",
                    title: ritual.title,
                    detail: "A gentle reason to return, drawn from season, language and the stories already in hand—not a streak.",
                    accent: Theme.lichen
                )

                VStack(alignment: .leading, spacing: 14) {
                    EditorialContextLabel(text: ritual.context, color: Theme.lichen)
                    AtlasAudioLine(ga: ritual.ga, en: ritual.en, sound: ritual.sound)
                    Text(ritual.invitation)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(4)
                    Button {
                        atlas.markCalendarDayVisited(dayKey)
                        Haptics.chisel()
                    } label: {
                        Label(
                            atlas.hasVisitedCalendarDay(dayKey) ? "Carried today" : "Carry this today",
                            systemImage: atlas.hasVisitedCalendarDay(dayKey) ? "checkmark" : "leaf"
                        )
                        .font(.headline)
                        .foregroundStyle(Theme.moss)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(CarvePress())
                    .disabled(atlas.hasVisitedCalendarDay(dayKey))
                }
                .padding(18)
                .background(Theme.raised)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                EditorialSectionHeader(
                    context: "The year ahead",
                    title: "Moments the product can meet honestly",
                    detail: "Calendar stories appear only when the county material has a real connection. The date never manufactures urgency."
                )

                calendarMoment(month: "March", title: "Seachtain na Gaeilge", detail: "Bring reviewed Irish into public, ordinary use.")
                EditorialRule()
                calendarMoment(month: "17 March", title: "Lá Fhéile Pádraig", detail: "Offer a diaspora return without patriotic performance.")
                EditorialRule()
                calendarMoment(month: "31 October", title: "Samhain", detail: "Use source-led seasonal material when the relevant county story is ready.")

                VStack(alignment: .leading, spacing: 8) {
                    EditorialContextLabel(text: "No missed days", color: Theme.moss)
                    Text("The calendar opens again whenever you do.")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("There is no chain to protect, no penalty to repair and no backlog waiting behind the date.")
                        .font(.body)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(EditorialLayout.pageInset)
            .padding(.bottom, 34)
            .frame(maxWidth: EditorialLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            now = Date()
        }
    }

    private func calendarMoment(month: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(month)
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(Theme.lichen)
                .frame(width: 72, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(detail).font(.subheadline).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
