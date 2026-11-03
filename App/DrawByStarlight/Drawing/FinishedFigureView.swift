import StarlightCore
import SwiftUI

/// The figure's story, on demand: its night, shown turning (or said, when it isn't up), then its story
/// quoted from Wikipedia and plainly marked as Wikipedia's, with a link to the article. Nothing
/// the sky above it already shows (that it's drawn, its border, its name twice). The drawing
/// stays visible above the sheet.
struct FinishedFigureView: View {
    let model: DrawingModel
    let sky: Sky
    /// Where the sheet first rests: low enough that the figure shows whole above it, undimmed.
    let firstDetent: PresentationDetent
    let done: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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
        .presentationDetents([firstDetent, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: firstDetent))
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.paper)
        #if DEBUG
        .onAppear { DemoMode.markReady() }
        #endif
    }

    /// Its night, the one thing the sky above doesn't show: shown turning from dusk to dawn
    /// (`FigureNightView`), or, when it isn't up tonight at all, said in a line.
    @ViewBuilder private var facts: some View {
        switch (sky.place, model.scene.timing) {
        case (let place?, .now), (let place?, .later), (let place?, .beforeDawn):
            FigureNightView(constellation: model.scene.constellation, sky: sky, place: place,
                            still: model.scene.moment, words: standing)
        default:
            Text(verbatim: standing)
                .font(.system(.title3, design: .serif).italic())
                .foregroundStyle(Theme.ink)
        }
    }

    private var standing: String {
        guard let place = sky.place else { return String(localized: "Place unknown") }
        switch model.scene.timing {
        case .unseen: return String(localized: "Never rises from here.")
        case .notTonight: return String(localized: "Not up tonight.")
        default: break
        }
        // Circumpolar: every star's declination keeps it above the horizon all day, at either pole.
        let pole: Double = place.latitude < 0 ? -1 : 1
        let circumpolar = model.figure.allSatisfy { $0.star.j2000.declination * pole > 90 - abs(place.latitude) + 1 }
        if circumpolar {
            return String(localized: "Never sets from here.")
        }
        guard let transit = model.scene.transit else { return SkyWords.listing(model.scene, place: place, time: sky.time) }
        let center = place.horizontal(of: FigureScene.middle(of: model.figure.map { $0.star.j2000 }) ?? Equatorial(rightAscension: 0, declination: 0), at: transit)
        return String(localized: "figure.highest", defaultValue: "Highest at \(sky.time(transit)), \(SkyWords.height(altitude: center.altitude)) in the \(SkyWords.direction(azimuth: center.azimuth)).",
                      comment: "A fact on the finished figure; the arguments are a clock time, a height word (high, halfway up, low) and a compass direction.")
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
            .accessibilityHint("Opens Wikipedia in Safari.")
            Text(terms)
                .font(.caption2)
                .foregroundStyle(Theme.lavender)
            Link(destination: stories.licenseURL) {
                Text(license)
                    .font(.caption2.weight(.semibold))
            }
            .accessibilityHint("Opens the license in Safari.")
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("From Wikipedia")
    }

    private var terms: String {
        let revised = story.revised.formatted(date: .long, time: .omitted)
        return String(localized: "wikipedia.terms", defaultValue: "Quoted from the article “\(story.title)” as revised \(revised), with its pronunciation notes left out.",
                      comment: "Under a quotation from Wikipedia; the arguments are the article's title and the date of its revision.")
    }

    private var license: String {
        String(localized: "wikipedia.license", defaultValue: "Text under the \(stories.license) license",
               comment: "A link under a quotation from Wikipedia, to its license; the argument is the license's name.")
    }
}
