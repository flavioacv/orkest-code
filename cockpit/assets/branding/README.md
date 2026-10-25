# Orkest Code — ribbon brand

Approved direction: folded cyan/blue ribbon with violet accent and geometric
wordmark, based on the user's identity-board reference.

| File | Intended use |
|---|---|
| `orkest-symbol-ribbon-v1.png` | Standalone symbol, transparent PNG |
| `orkest-app-icon-ribbon-v1.png` | Opaque square icon master, no lettering |
| `orkest_logo.png` | Packaged shared UI icon, rounded tile |
| `orkest-wordmark-ribbon-v1.png` | Symbol + dark lettering, transparent background, light layouts |
| `orkest-wordmark-ribbon-dark-v1.png` | Symbol + white lettering on opaque navy background, dark layouts |

The symbol and lettering artwork were generated with the built-in imagegen
tool. These are raster masters, not vector exports or an installable typeface.
The wordmark follows the reference style; no exact font family is claimed.
The discarded geometric concept's SVG is archived under `concepts/`.

Run `python3 tool/generate_orkest_icons.py` from the Flutter project to package
the approved masters for macOS, Windows, Linux, Android, iOS and web. The script
only changes sizes, masks, adaptive-icon safe areas and encoding; it does not
redesign the artwork. iOS icons are opaque RGB; Android has separate foreground
and monochrome resources; Windows ICO contains seven sizes.

`OrkestBrandLogo` displays the correct wordmark in startup and welcome screens.
The shared icon continues to serve document/gallery icons. Existing manifests
and asset catalog filenames are retained, so the OS launcher references remain
valid. Restart/rebuild the app to refresh the native app icon.

Generation prompts for the first two masters: `ribbon-v1-prompts.md`.
Final additional prompts:

## App icon

Use case: logo-brand. Create the final square app icon master for Orkest Code. Use the attached approved blue/violet folded ribbon symbol EXACTLY as the mark. Center it on a clean uniform deep navy background #101827, filling a square canvas edge to edge, with the symbol height 72% of canvas height and comfortable equal margins. Preserve its cyan/cobalt upper ribbon, right vertical blue fold, blue lower-right return and violet lower-left folded triangle, rounded edges and triangular negative space; the negative space reveals the navy background. Perfect front-facing flat digital app icon. Sharp vector-like contours, precise smooth gradients. No text, no letters, no wordmark, no decorative border, no external shadows, no mockup, no perspective, no glow, no noise, no white flecks. The whole image should be an opaque square; operating-system icon masks are applied later.

## Dark artwork

Create the dark-background presentation version of this EXACT horizontal Orkest Code logo, same ribbon geometry, same layout and exact same typography. Background is completely OPAQUE uniform solid deep navy #101827. Render Orkest in solid clean white and the small spaced CODE letters in light slate gray, preserve blue/purple ribbon colors. Absolutely smooth clean solid letter edges and holes/counters that reveal dark navy. No transparency at all anywhere; opaque navy even inside letter holes and around the ribbon. No texture, flecks, noise, distress, halo, glow or shadow. Professional finished brand artwork, landscape, entire logo with generous balanced margins. Text exactly 'Orkest' and 'C O D E'.
