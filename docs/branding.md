# Branding

Tidy Skill project mark.

## Mark

`assets/readme/logo.svg` — 512px icon: a **vacuum nozzle** (upper half) swallowing a **debris stream** (lower half) up into its suction slot; the dot at the stream's tip entering the slot turns sage-green = "just got cleaned".

The mark is project-native, not stock iconography: an agent tidy-up is literally "suck the noise out of the repo" — so we drew that. The nozzle is the `tidy_doctor → tidy_repair` tool; the converging debris is the litter being pulled (Classes **A** misfiled docs, **C** temp in `.agent_tmp/`, **E** tool state); the sage dot is the `tidy_doctor` exit-clean signal on whatever just passed through.

- **Style**: solid silhouette, minimal. No line-art (lossy at favicon size) — flat masses only.
- **Palette**: paper `#f7f8f9` (air), nozzle slate `#2b3a47` (the tool), debris `#5a6b78` opacity 0.92 (the mess, desaturated), sage `#3f9d7a` (the cleaned signal — the only saturated color). One accent = tidy.
- **16px fidelity**: the trapezoid nozzle + tapering stream survive as one solid silhouette at favicon size; the sage dot drops below 1px at 16 and is intentionally allowed to vanish — favicon reads "a vacuum swallowing something" without needing the accent. Full detail (sage moment, mouth slot) recovers at ≥32px.

### Exported sizes

`assets/readme/logo-{16,32,48,64,128,192,256,512,1024,2048}.png` plus `favicon-32.png`. Regenerate with:

```bash
node tools/svg_to_png.js assets/readme/logo.svg assets/readme/
```

`@resvg/resvg-js` is a WASM renderer — no native cairo/resvg install needed.

## In the README

- **Hero**: the logo mark alone (160px), centered above the title. No motion GIF — the static pose already carries the "swallow → cleaned" beat; a loop would compete with the badge and cheapen it.
- **Mechanism banner** (`docs/screenshots/banner.png`) sits inline in the *Three-Layer Hygiene Model* section as supporting evidence.

## Concepts and iteration

Four rounds were explored.
- **Round 1** (`concept-1` to `concept-4`): line-art folder-box + clean-check on white — rejected as too icon-pack-flat, no "cleaning" gesture.
- **Round 2** (`concept-6a / 6b / 6c`): re-anchored on the BondLens dark-voxel hex-prism + amber-peak skeleton — rejected: dark badge felt heavy and "stacked load" rather than "clean, tidy".
- **Round 3** (`concept-7a / 7b / 7c`): light-first Notion/Linear family. `concept-7c` (three dots on a cradle, third sage) was selected but on review read as too abstract / no cleaning semantics.
- **Round 4** (`concept-8a / 8b / 8c`): the literal brief — "vacuum sucking debris", light line-art. 8a was pure line-art (thin strokes, died at 16px); 8b went blocky with many small dust dots (noisy, dots dropped at favicon); **`concept-8c`** consolidated to one strong nozzle silhouette + one converging debris wedge + a sage "just swallowed" dot.
- `logos/iterations/iteration-4.svg` is the final export source: widest nozzle silhouette that still survives 16px, sage focal repositioned to the stream tip just below the slot so it does not squeeze the mouth. `logos/preview.html` is the side-by-side concept/iteration gallery.

## Philosophy

Light palette and silhouette-first because the project's promise is literally "clean, tidy" — a dark decorated badge contradicts the product. No container shapes, no rocket, no motion loops — the mark has to read at 16px and survive being a favicon, and the gesture (vacuuming the mess) has to be obvious enough that a viewer who knows nothing about agent hygiene can still tell what the project is for.
