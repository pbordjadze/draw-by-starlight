import StarlightCore
import SwiftUI

/// The figure, whole: when it was drawn, its story quoted from Wikipedia and plainly marked as
/// Wikipedia's, with a link to the article, and a fact or two computed from the catalogue. The
/// drawing stays visible above the sheet.
struct FinishedFigureView: View {
    let model: DrawingModel
    let sky: Sky
    /// When this figure was first drawn; nil until it is recorded.
    let drawnAt: Date?
    let done: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    drawnLine
                    Text(verbatim: model.name)
                        .font(.display(.title))
                        .foregroundStyle(Theme.ink)
                    facts
                    if let story = model.story {
                        WikipediaCard(story: story, stories: sky.stories)
                    }
                    Button("Done", action: done)
                        .buttonStyle(.glassProminent)
                        .tint(Theme.signature)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                }
                .padding(20)
            }
            .background(Theme.paper)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.showsStory = false
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.paper)
        #if DEBUG
        .onAppear { DemoMode.markReady() }
        #endif
    }

    private var drawnLine: some View {
        HStack(spacing: 8) {
            SparkleShape()
                .fill(Theme.gold)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(drawnText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.lavender)
        }
        .padding(.top, 8)
    }

    private var drawnText: String {
        guard let drawnAt, Calendar.current.isDate(drawnAt, inSameDayAs: sky.now) == false else {
            return String(localized: "Drawn tonight.")
        }
        let day = drawnAt.formatted(Date.FormatStyle(date: .long, time: .omitted, timeZone: sky.timeZone))
        return String(localized: "figure.drawn-on", defaultValue: "First drawn \(day).",
                      comment: "On the finished figure, when it was drawn before; the argument is a date.")
    }

    /// Facts the catalogue and the sky give, never written by hand.
    private var facts: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let brightest = model.figure.min(by: { $0.star.magnitude < $1.star.magnitude }) {
                fact(String(localized: "Brightest star"),
                     String(localized: "figure.brightest", defaultValue: "\(brightest.star.label), magnitude \(brightest.star.magnitude.formatted(.number.precision(.fractionLength(1))))",
                            comment: "A fact on the finished figure; the arguments are a star's name and its magnitude."))
            }
            fact(String(localized: "Tonight"), standing)
            fact(String(localized: "Border"), String(localized: "The dotted line: its border, drawn by the IAU in 1930."))
        }
    }

    private var standing: String {
        guard let place = sky.place else { return String(localized: "Place unknown") }
        // Circumpolar: every star's declination keeps it above the horizon all day.
        let circumpolar = model.figure.allSatisfy { $0.star.j2000.declination > 90 - place.latitude + 1 }
        if circumpolar {
            return String(localized: "Never sets from here.")
        }
        guard let transit = model.scene.transit else { return SkyWords.listing(model.scene, place: place, time: sky.time) }
        let center = place.horizontal(of: FigureScene.middle(of: model.figure.map { $0.star.j2000 }) ?? Equatorial(rightAscension: 0, declination: 0), at: transit)
        return String(localized: "figure.highest", defaultValue: "Highest at \(sky.time(transit)), \(SkyWords.height(altitude: center.altitude)) in the \(SkyWords.direction(azimuth: center.azimuth)).",
                      comment: "A fact on the finished figure; the arguments are a clock time, a height word (high, halfway up, low) and a compass direction.")
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.lavender)
            Text(verbatim: value)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A constellation's story, quoted from Wikipedia and shown as Wikipedia's: the source named at
/// the top, the words set apart, the article a tap away, the terms at the bottom.
struct WikipediaCard: View {
    let story: Story
    let stories: Stories

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "text.book.closed")
                    .foregroundStyle(Theme.ink)
                    .accessibilityHidden(true)
                Text("From Wikipedia")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                Text("the free encyclopedia")
                    .font(.footnote)
                    .foregroundStyle(Theme.lavender)
            }
            if let first = story.paragraphs.first {
                Text(verbatim: first)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1).fill(Theme.lavender).frame(width: 2)
                    }
            }
            Link(destination: story.url) {
                Group {
                    if story.paragraphs.count > 1 {
                        Label("Keep reading on Wikipedia", systemImage: "arrow.up.right")
                    } else {
                        Label("Read the article on Wikipedia", systemImage: "arrow.up.right")
                    }
                }
                .font(.body.weight(.semibold))
            }
            .tint(Theme.gold)
            .accessibilityHint("Opens Wikipedia in Safari.")
            Text(terms)
                .font(.caption2)
                .foregroundStyle(Theme.lavender)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("From Wikipedia")
    }

    private var terms: String {
        let revised = story.revised.formatted(date: .long, time: .omitted)
        return String(localized: "wikipedia.terms", defaultValue: "Quoted word for word from the article “\(story.title)” as revised \(revised); text under \(stories.license).",
                      comment: "Under a quotation from Wikipedia; the arguments are the article's title, the date of its revision and the license's name.")
    }
}
