# Polish rounds

A polish loop (painting-company row 128): each round takes the few changes that most improve how
the app feels, ships a SideStore build, and a fresh critic judges it from CI's screenshots. The
next round takes the weakest thing the critic names.

## Round 1

- **Build:** 16
- **Changed:** "Show me" and links were system blue: now lavender and parchment. Once the first
  line is drawn the words above the sky fade, and the "Pause, and the next star glimmers" line is
  gone (the glimmer teaches it). When a figure is whole, its story rises only halfway, undimmed,
  and the figure moves up to stay whole above it.
- **To see it:** open any constellation, draw a line, then finish it.
- **Critic:** "The drawing is a delight, but finishing a figure ends on a form instead of the sky he
  just drew." Weakest: the finished figure's sheet. Not yet showable without a caveat.
- **Spend so far:** about $10

## Round 2: less text, more wonder

The loop's main axis from here: show, don't tell. Words only on demand. This round also takes
round 1's weakest thing: a finished figure no longer ends on a sheet.

- **Build:** 18
- **Changed:** the drawing screen has no words but the title and star names: the instruction
  line, the "turned as it sits tonight" line and the feedback lines are gone. A first look
  glimmers where to begin after a breath, and "Show me" is a sparkle in the toolbar. Drawing the
  last line no longer pops up the story: light runs along the figure's lines and its border fades
  in; the story waits behind the book button. The home list lost its header and footer.
- **To see it:** open any constellation and wait a moment; draw it to the end.
- **Critic:** words per view: drawing 1 (fresh), 4 (two lines), 6 (whole); story sheet 42; home
  49. "Almost": he'd show the drawing proudly but close the story sheet first, because it says
  what he just saw ("Drawn tonight.", the border explained, the name twice).
- **Spend so far:** about $24

## Round 3

- **Build:** 20
- **Changed:** the story sheet stops repeating the sky: "Drawn tonight.", the Border row and its
  second "Cassiopeia" heading are gone; it opens on the brightest star and tonight's timing, then
  Wikipedia's story, attributed as before.
- **To see it:** finish a constellation, tap the book.
- **Critic:** words per view: home 49, drawing 1–6, story about 72. "No": the drawing and the
  come-alive moment are lovely, but the first screen is a plain text list with no sky.
- **Spend so far:** about $30

## Round 4

- **Build:** 22
- **Changed:** each row of the home list starts with its constellation's figure in small, turned
  as it sits tonight: gold stars, the lines only hinted until you draw them, then inked in.
- **To see it:** the first screen; draw a few lines of one and come back.
- **Critic:** words per view: home 44, drawing 1–6, story about 77. "No": drawing feels like
  wonder, but home still looks like a settings page (a grey card, chevrons, small figures).
- **Spend so far:** about $36

## Round 5

- **Build:** 25
- **Changed:** home is the night itself: no card, no chevrons, no separators, and each figure
  is twice the size.
- **To see it:** the first screen.
- **Critic:** words per view: home 28, drawing 1–6, story about 71. "Yes: drawing is wordless
  and lovely, and the wordy part only appears when you tap the book." Its next idea, not taken:
  drop the story sheet's "the free encyclopedia" tagline and the "Brightest star" and "Tonight"
  captions.
- **Spend so far:** about $42

The loop stopped here: the critic says he'd show it without a caveat.

# Polish loop 2: wonder over words

The second loop's axis: show the sky, not words about it. Spend starts again from zero.

## Round 6

- **Build:** 30
- **Changed:** home is tonight's whole sky, a planisphere (StarlightCore's `Dome`), wheeling
  through the last two hours into place; a figure is named only once drawn; the ones below the
  horizon wait under the rim. The story sheet lost its captions and Wikipedia's tagline.
- **To see it:** the first screen; touch a figure.
- **Critic:** words: home 5 (was 28), drawing 1–6, story about 79. "Almost": the finished
  figure ends in an encyclopedia card; "never sets" is told, not shown.
- **Spend so far:** about $10

## Round 7

- **Build:** 36
- **Changed:** the story sheet shows the figure's night instead of saying it: a small sky
  turning from sunset to sunrise (`FigureNightView`, `FigureScene.night`). Home shows a figure's
  lines only as they're drawn.
- **To see it:** finish a figure, tap the book.
- **Critic:** story as first shown about 22 words. "Almost": home is a still chart boxed in the
  middle of the screen.
- **Spend so far:** about $22

## Round 8

- **Build:** 40
- **Changed:** home goes edge to edge, the stars below the horizon faint beyond the rim; after
  the opening wheel the sky turns on at the real rate and its gold stars twinkle. The story sheet
  first shows its turning sky alone.
- **Critic:** story sheet 0 words of its own. "Almost": home is an even spray of gold.
- **Spend so far:** about $31

## Round 9

- **Build:** 44
- **Changed:** on home, figures not begun are ordinary stars until their turn: one at a time,
  each glows gold as a whole. The story's sky fills the sheet, a short wake behind the figure.
- **Critic:** "Almost": the fresh drawing screen is a dot-to-dot of gold beads apart from the
  sky.
- **Spend so far:** about $41

## Round 10

- **Build:** 46
- **Changed:** a figure zooms in from its place in the sky and back out; its stars start white,
  sized by brightness, and turn gold as a line reaches them.
- **Critic:** "Almost": a finished-figure screenshot came out black (a slow CI run; main's run
  of the same code was ready in a second).
- **Spend so far:** about $52

## Round 11

- **Build:** 48
- **Changed:** the zoom opens from plain anchors and VoiceOver's words are worked out once a
  night; home's brightest stars are drawn larger, so the Dipper and the W show by themselves.
- **Critic:** words per view: home 5, drawing 1–6, story sheet 0 of its own. "Almost: drawing
  and finishing a figure is pure delight, but the first screen still looks like a diagram of the
  sky rather than the sky." Its weakest thing: home's composition (dark bands above and below
  the disc; a figure begun and one aglow read alike; the strip of waiting figures like a
  toolbar).
- **Spend so far:** about $63

The loop stopped here on spend (≈ $70), one critic short of "without a caveat". Not taken, from
reviews: a figure that sets during the evening loses its gold stars at the rim; a touch beyond
the rim can find a figure's line there; tonight's start counts tomorrow's sunset when the Sun is
just below the horizon (`FigureScene.evening`); during the opening wheel a zoom starts from where
a figure stood two hours earlier.
