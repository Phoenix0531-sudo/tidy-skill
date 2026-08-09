# Branding

Tidy Skill project mark and motion GIF.

## Mark

`assets/readme/logo.svg` — 512px icon: a dark rounded **hex prism** containing three aligned teal tiers (`repo / workspace / machine`), with one amber "placed/checked" dot marking the tier the doctor just inspected.

- **Style**: voxel-badge, same design family as the BondLens project mark — dark rounded square + hex prism frame + teal interior + amber focal dot. Same family, different semantics: where BondLens focuses a bond yield curve, tidy-skill stacks three governance tiers.
- **Palette**: badge `#17211d`, prism frame warm-white `#fffdf8`, tiers teal `#0f6b5f` (top/bottom opacity 0.55, middle 0.85 so the workspace layer reads strongest), focal dot amber `#c07a22` with a warm-white core `#fffdf8`.
- **16px fidelity**: the hex prism outline (22px stroke in the 512 viewBox) survives at favicon size; the tier bands and amber dot drop below 1px at 16px and are intentionally allowed to vanish — the prism silhouette carries the identity, same as the BondLens favicon.

### Exported sizes

`logos/export/` holds `logo-{16,32,48,192,512,1024,2048}.png`. Use `tools/svg_to_png.js` to regenerate:

```bash
node tools/svg_to_png.js logos/export/logo.svg logos/export/
```

`@resvg/resvg-js` is a WASM renderer — no native cairo/resvg install needed.

## Motion GIF

`assets/readme/tidy-motion.gif` — 320px, ~2.6s loop: hex prism frame draws in → three tidy tiers place top-to-bottom → amber "checked" dot pops at the top-tier right end. Renders the *doctor → repair → clean* narrative the rest of the README describes.

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

Two rounds were explored. **Round 1** (`concept-1` to `concept-4`) used a line-art folder-box + clean-check on a white field — rejected as too icon-pack-flat and not in the same design family as the BondLens project mark. **Round 2** (`concept-6a / 6b / 6c`) re-anchored the mark on the BondLens hex-prism + amber-peak skeleton with tidy semantics. `concept-6a` (three-tier prism) was selected; `logos/iterations/iteration-2.svg` is the refined export source (tier height normalized, amber dot moved onto the top-tier right end). `logos/preview.html` is the side-by-side concept/iteration gallery.

## Philosophy

The mark is project-native, not stock iconography: the hex prism is the same artifact-placement metaphor the skill teaches (Classes **A** formal docs at root, **C** temp in `.agent_tmp/`, **E** tool state outside the tree — here as three stacked governance tiers), and the amber focal dot is the `tidy_doctor` exit-0 read on the tier just inspected. Same voxel-badge family as the BondLens project mark, so the two repos read as one authored family while carrying distinct semantics — bond yield curve over there, governance tiers over here. No decorative swirls, no generic rocket — the identity has to read at 16px and survive being a favicon.
