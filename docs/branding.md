# Branding

Tidy Skill project mark and motion GIF.

## Mark

`assets/readme/logo.svg` — 512px icon: a tidy folder-box (artifacts always have a home) with a clean check mark, and an amber "lit-clean" dot on the check endpoint.

- **Style**: minimal geometric.
- **Palette**: slate `#0f172a` (structure / check), white `#ffffff` (folder interior), amber `#f59e0b` (workspace-slab accent, reused as the "clean lit" signal).
- **16px fidelity**: the folder outline + check stroke (28px in the 512 viewBox) survive at favicon size; the amber dot drops below 1px at 16px and is intentionally allowed to vanish — the check itself carries the "clean read".

### Exported sizes

`logos/export/` holds `logo-{16,32,48,192,512,1024,2048}.png`. Use `tools/svg_to_png.js` to regenerate:

```bash
node tools/svg_to_png.js logos/export/logo.svg logos/export/
```

`@resvg/resvg-js` is a WASM renderer — no native cairo/resvg install needed.

## Motion GIF

`assets/readme/tidy-motion.gif` — 320px, ~2.4s loop: folder-box draws in → clean check strokes in → amber dot pops. Renders the *doctor → repair → clean* narrative the rest of the README describes.

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

`logos/concepts/` holds four distinct directions explored before refinement (stacked slab, tidy-box+check, three-tier shield, folded-T+sweep). `logos/iterations/iteration-1.svg` is the refined tidy-box+check the final mark is exported from. `logos/preview.html` is the side-by-side concept/iteration gallery.

## Philosophy

The mark is project-native, not stock iconography: the folder-box is the same artifact-placement metaphor the skill teaches (Classes **A** formal docs at root, **C** temp in `.agent_tmp/`, **E** tool state outside the tree), and the clean check is the `tidy_doctor` exit-0 read. No decorative swirls, no generic rocket — the identity has to read at 16px and survive being a favicon.
