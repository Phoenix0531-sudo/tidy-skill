# Branding

Tidy Skill project mark and motion GIF.

## Mark

`assets/readme/logo.svg` — 512px icon: **three dots riding a shallow cradle arc**, the third lit sage-green to mean "ready" while the first two hold slate-dark. Light, airy, tidy.

- **Style**: minimal geometric on a paper-white field — Notion/Linear family, *not* the BondLens dark-voxel badge (that one is BondLens' avatar/PWA icon; README-side it ships a white-background variant too). Tidy-skill goes light-first because the brief is "clean, tidy" — light palette and geometry-first, not decorated containers.
- **Palette**: paper `#f7f8f9`, cradle arc `#c0c8d2` (10px stroke so it survives at favicon), dots slate `#2b3a47` (repo / workspace layers), focal "ready" dot sage `#3f9d7a`. Neutral base + one accent = tidy.
- **16px fidelity**: the three dots survive at favicon size (slate r=38→1.19px at 16, sage r=52→1.63px at 16 — both stay visible); the cradle arc drops below 1px at 16 and is allowed to vanish. The two darker dots + one sage dot read as "a few things put in order" even cropped.

### Exported sizes

`logos/export/` holds `logo-{16,32,48,192,512,1024,2048}.png`. Use `tools/svg_to_png.js` to regenerate:

```bash
node tools/svg_to_png.js logos/export/logo.svg logos/export/
```

`@resvg/resvg-js` is a WASM renderer — no native cairo/resvg install needed.

## Motion GIF

`assets/readme/tidy-motion.gif` — 320px, ~2.5s loop: the cradle arc draws in → two slate dots drop onto it in order → the sage "ready" dot pops last, slightly bigger as the focal. Renders the *doctor → repair → clean* narrative the rest of the README describes.

Source timeline is `assets/readme/tidy-motion.svg` (SMIL, kept as the editable spec), but resvg does not run SMIL timelines, so the GIF is rendered frame-by-frame:

```bash
node tools/render_motion_frames.js .agent_tmp/_motion_frames
# then Pillow stitches the frames:
.venv/Scripts/python.exe .agent_tmp/_stitch_gif.py   # see script for paths
```

Final dot-lit frames hold ~140ms (vs 55ms mid-timeline) so the loop has a beat before restart and does not flash.

## In the README

- **Hero**: logo mark (128px) + motion GIF (320px), centered above the title.
- **Mechanism banner** (`docs/screenshots/banner.png`) was previously the top hero; it now sits inline in the *Three-Layer Hygiene Model* section as supporting evidence.

## Concepts and iteration

Three rounds were explored.
- **Round 1** (`concept-1` to `concept-4`): line-art folder-box + clean-check on white — rejected as too icon-pack-flat.
- **Round 2** (`concept-6a / 6b / 6c`): re-anchored on the BondLens dark-voxel hex-prism + amber-peak skeleton — rejected on review: the dark badge felt heavy and "stacked load" rather than "clean, tidy".
- **Round 3** (`concept-7a / 7b / 7c`): went light-first, Notion/Linear family. `concept-7c` (three dots on a cradle, third lit sage) was selected; `logos/iterations/iteration-3.svg` is the refined export source (opaque larger dots for 16px survival, cradle slightly heavier). `logos/preview.html` is the side-by-side concept/iteration gallery.

## Philosophy

The mark is project-native, not stock iconography. Three dots ride a shallow cradle arc — the three hygiene layers (Classes **A** formal docs at root, **C** temp in `.agent_tmp/`, **E** tool state outside the tree) held in order by one tidy line, the third lit sage because that's the layer `tidy_doctor` just exited clean. Light palette and geometry-first because the project's promise is literally "clean, tidy" — a dark decorated badge would contradict the product. No container shapes, no rocket — the mark has to read at 16px and survive being a favicon.
