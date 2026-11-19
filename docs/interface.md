# Interface

Where the screens' geometry, typography and colours come from, so a change can be checked against a source rather than
against taste.

## Dopamine, measured from its source

The layout constants come from Dopamine's own source (MIT, see [NOTICE](../NOTICE.md)), not from guesses:

| Constant | Value | Used by |
|---|---|---|
| Side margin | 30 pt | `Metrics.sideMargin` |
| Action row height | 73 pt (65 pt with a home button, 52 pt on short screens) | `MainLayout.rowHeight` |
| Menu inner padding | 20 pt sides, 5 pt top and bottom | `Metrics.menuSidePadding`, `menuVerticalPadding` |
| Corner radius | 14 pt continuous, 16 pt for windows | `Metrics.cornerRadius`, `windowRadius` |
| Column height | 73% of the screen (78% with a home button) | `MainLayout` |
| Window height | 70% of the screen | `WindowHost` |
| Header | 40 pt wordmark slot, two 14 pt lines | `HeaderView` |
| Log line | 40 pt | `LyricsLog` |
| Separators | 1 pt, 30% grey | `Color.ssSeparator` |

The main column is centred on `screenHeight / 2 + max(15, safeTop - 20)`, with the header, menu and button spaced by two
equal gaps. That is `MainLayout`, and it is the reason the screens match the mockups at 390 x 844.

Dopamine's `Themes.plist` fields carry over directly: `image`, `actionMenuColor`, `windowColor` (both AARRGGBB), `blur`
and `titleShadow`. `Model/Theme.swift` is that table in Swift.

## Caz, measured from screenshots

The panel rows, header cells and button insets were calibrated against the Caz interface specification (build 1.0.15,
measured on this same iPhone 13 running iOS 17.0): 73 pt menu rows, a 330 pt column, 30 pt margins, 17 pt settings
text, 14 pt headers, 18 and 20 pt log lines, and a 330 x 60 pt main button. The rebuilt main screen landed within
0.4 pt of Caz's measured ink positions for the settings row, chevron, header lines and separators.

Two places where Dopamine and Caz disagree, and this app currently follows Dopamine:

| | Dopamine | Caz | Here |
|---|---|---|---|
| Header second line opacity | 60% | 80% | 60% |
| Log column | left-aligned inside 25 pt padding | centred | left-aligned |

Both are one-line changes in `HeaderView` and `LyricsLog` if the Caz behaviour is preferred.

## Typography

The app uses the system font through `Font.system`, so UIKit applies Apple's own tracking and optical sizing. The
mockups had to reproduce that by hand, using the tracking table read from `SFUI.ttf`'s own `trak` table:

| Size (pt) | Tracking (px) | | Size (pt) | Tracking (px) |
|---:|---:|---|---:|---:|
| 13 | −0.0762 | | 18 | −0.4395 |
| 14 | −0.1504 | | 20 | −0.4492 |
| 15 | −0.2344 | | 22 | −0.2578 |
| 16 | −0.3125 | | 24 | +0.0703 |
| 17 | −0.4316 | | 29 | +0.3894 |

Tracking turns positive at 24 pt and above; an earlier assumption that it stayed negative was wrong and was corrected
from the font's own table. SF's line box is `(ascender 1950 + descender 494) / 2048`, which is why `lineHeight()` asks
UIKit rather than multiplying by a constant.

The wordmark is **Fonarto Regular**, letter-spacing −0.65% em, capitals about 30.5 pt, drawn 7 pt above its 40 pt slot,
which is the recipe Caz uses. Fonarto's licence permits use but says nothing about redistribution, so the font file is
not in this repository: the wordmark and the WPA2/WPA3 tile labels ship as rendered PNGs at 1x, 2x and 3x
(`Wordmark.imageset`, `TileWPA2.imageset`, `TileWPA3.imageset`).

## Themes

Ten Morning Haze variants, all 1170 x 2532. Morning Haze itself is unchanged from the original; the other nine are
recolourings. Each entry's menu and window colours were tuned so white text holds at least 4:1 contrast on the card and
the button, which is why they are not simply the same tint over different images.

| Theme | Menu (AARRGGBB) | Window (AARRGGBB) | Blur | Title shadow |
|---|---|---|---:|---|
| Morning Haze | `942E475C` | `99090E12` | 38 | yes |
| Clear Dawn | `9E38393C` | `99101112` | 38 | yes |
| Cumulus Drift | `9E2E3A46` | `990C0F12` | 38 | yes |
| High Cirrus | `9E344352` | `990C0F13` | 38 | no |
| Golden Morning | `9E393837` | `99111010` | 38 | yes |
| Silver Overcast | `9E34393D` | `990E0F10` | 38 | yes |
| Rose Haze | `9E483F4C` | `99100E11` | 38 | yes |
| Deep Zenith | `7A283950` | `80080B10` | 38 | no |
| Sea Mist | `9E313F40` | `990D1011` | 38 | yes |
| Lilac Morning | `9E413B50` | `990F0D12` | 38 | yes |

Deep Zenith is the one entry with a lighter card (alpha `7A`) and window (`80`), because its background is dark enough
already; it and High Cirrus are the two without a title shadow.

The blur is 38 px of the 1170 x 2532 image, about 15.5 pt on screen, applied at runtime by `Support/Blur.swift` with a
clamped-edge Gaussian so the edges do not fade. Backgrounds are stored unblurred, extend 100 pt past both ends of the
screen, and dim to 40% while a window is open, all as Dopamine does.

## Icons and the app icon

SF Symbols are real here. The mockups used hand-drawn stand-ins scaled to SF's ink sizes, because the real
`CoreGlyphs.bundle` was not available in the mockup pipeline; the app uses `Image(systemName:)`, so any difference
between the two is the mockup being approximate, not the app.

The app icon is Lighthouse Beam, one icon for every theme, rendered at each iPhone slot size plus the 1024 pt marketing
icon. `IconPreview.imageset` is the same artwork at 288 px for the Theme and About pages.

### The icon: Night Keeper

The background **is** Morning Haze: a square cut from the top of the background image, 1170 x 1170 px from its top
edge, with the same Gaussian blur the app applies (38 px of the 1170 px width), scaled to 1024. Nothing is darkened or
recoloured. The top of that square is the image's slate band, the bottom its soft blue.

The lighthouse keeps the Lighthouse Beam geometry and is redrawn to read on a pale sky:

| Part | Colour |
|---|---|
| Tower, lamp room, roof, finial, base | `#141E28`, a near-black slate (the theme's window colour, lifted slightly) |
| The two stripes | `#BFDDF7` at 85%, the sky's own light blue |
| Lamp glass | white |
| Beams | white, fading from 85% at the lamp to nothing at the edges |

Measured along the lighthouse's outline against the sky just outside it, the median contrast is 4.2:1, and 69% of the
outline clears 3:1, the WCAG threshold for graphics. The rest is where the light stripes and lamp glass meet the edge,
by design. The dark tower reads best against the lighter lower sky; the white lamp and beams read against the darker
slate at the top.

Ten treatments were rendered on the same sky and compared at 180, 90 and 60 px on the in-app wallpaper. A white
lighthouse on the untouched sky manages about 2:1, which is why the original white glyph wasn't kept as it was. An
earlier version darkened the sky into a gradient to keep the glyph white; it was rejected because the background no
longer looked like Morning Haze.

The icon is one artwork for all ten themes. Per-theme icons would need iOS alternate icons, which are not implemented.
