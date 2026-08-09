# Branding

Tidy Skill project mark.

## Mark

`assets/readme/logo.svg` — 512px icon: a **broom** sweeping a scattered chaos cluster (small abstract symbols △ □ + ~ and stray dots ahead of the broom) toward a tidy aligned row of three dots and one sparkle behind the handle root. Pure black on a rounded white card.

The mark is project-native, not stock iconography: an agent tidy-up is literally "sweep the noise out of the repo" — so we drew that. The broom is `tidy_doctor → tidy_repair`; the scattered chaos beyond the head is the miss-located debris (Classes **A** misfiled docs, **C** temp in `.agent_tmp/`, **E** tool state); the ordered dots + sparkles behind the handle root are the swept-clean path left behind.

- **Style**: silhouette + minimal detail. The broom itself is the canonical Phosphor `ph/broom` MIT icon path used verbatim — proven recognizable, no attribution required, no redraw (we learned the hard way that redrawing wrecked recognition). The chaos and order clusters are single-stroke additions.
- **Palette**: pure black `#000000` on white `#ffffff` card. One ink, one ground — the "clean/tidy" promise reads before any color choice. (Earlier rounds used teal+green+sage; user feedback rejected all color — the silhouette narrative carries alone.)
- **16px fidelity**: the broom silhouette reads at favicon size (the rounded head body is a solid ~6px mass at 16px); the chaos symbols and order dots drop below 1px at 16 and are intentionally allowed to vanish — favicon reads "a broom" and that's enough. Full detail (chaos symbols, sparkles, dot row) recovers at ≥32px.

### Exported sizes

`assets/readme/logo-{16,32,48,64,128,192,256,512,1024,2048}.png` plus `favicon-32.png`. Regenerate with:

```bash
node tools/svg_to_png.js assets/readme/logo.svg assets/readme/
```

`@resvg/resvg-js` is a WASM renderer — no native cairo/resvg install needed.

## In the README

- **Hero**: the logo mark alone (160px), centered above the title. No motion GIF — the static pose already carries the "sweep → tidy row" beat; a loop competes with the badge and cheapens it.
- **Mechanism banner** (`docs/screenshots/banner.png`) sits inline in the *Three-Layer Hygiene Model* section as supporting evidence.

## Concepts and iteration

Five rounds were explored.
- **Round 1** (`concept-1` to `concept-4`): line-art folder-box + clean-check on white — rejected as too icon-pack-flat, no cleaning gesture.
- **Round 2** (`concept-6a / 6b / 6c`): re-anchored on the BondLens dark-voxel hex prism + amber peak — rejected: dark badge felt heavy and "stacked load" rather than "clean, tidy".
- **Round 3** (`concept-7a / 7b / 7c`): light Notion/Linear family. `concept-7c` (three dots on a cradle) was selected but on review read as too abstract, no cleaning semantics.
- **Round 4** (`concept-8a / 8b / 8c` + `iteration-5 / 6 / 7`): the literal "vacuum sucking debris" brief, light line-art first then pure b/w. Vacuum silhouette failed recognition twice — my hand-drawn geometry plus the MDI industry path both read as "not-a-vacuum" to the brief author. Lesson: don't redraw industry icons; their recognizability lives in the specific path.
- **Round 5** (`iteration-8`): switched brief, kept the "sweep → tidy row" story under a simpler metaphor — a **broom**. Used the Phosphor `ph/broom` MIT path verbatim as the silhouette (no redraw); that silhouette is industry-verified recognizable. The clipping to chaos (right) and order (left) restores the same "before/after" narrative vacuum could not deliver.

`logos/preview.html` is the side-by-side concept/iteration gallery.

## Philosophy

Pure black and a clean white card — the project promises "clean, tidy", and color gradients or a motion loop would decorate instead of demonstrate. The broom is the cleaning gesture an outsider recognizes in one glance; the before/after density contrast (scattered symbols → aligned dots) is what carries the *tidy-up* semantics even without reading the docs. No container shapes, no checkmarks, no rocket — the mark has to read at 16px and survive being a favicon, and the gesture (sweeping the mess) has to be obvious enough that a viewer who knows nothing about agent hygiene can still tell what the project is for.
