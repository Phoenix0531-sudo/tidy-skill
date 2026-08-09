// Frame-by-frame motion GIF renderer for the "three dots, one ready" tidy logo.
// resvg does not run SMIL timelines, so we compute per-frame:
//   - cradle arc stroke-dashoffset (0..0.5s)
//   - dot1 radius pop (0.5..0.9s)
//   - dot2 radius pop (0.9..1.3s)
//   - dot3 (sage focal) radius pop (1.3..1.9s)
//   - hold to 2.5s
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const TOTAL = 2.5;
const FPS = 18;
const FRAMES = Math.round(TOTAL * FPS);
const W = 320;
const outDir = process.argv[2] || '.agent_tmp/_motion_frames';
fs.mkdirSync(outDir, { recursive: true });

const easeOut = (x) => 1 - Math.pow(1 - x, 2.5);
const clamp = (x) => Math.max(0, Math.min(1, x));

// Pop with a small overshoot: 0 -> overshoot*rest at 60% -> rest at 100%.
function popRadius(t, start, dur, rest, overshootRatio = 1.1) {
  if (t < start) return 0;
  const p = clamp((t - start) / dur);
  if (p < 0.6) return rest * overshootRatio * easeOut(p / 0.6);
  return rest * overshootRatio - (rest * overshootRatio - rest) * easeOut((p - 0.6) / 0.4);
}

const tpl = (cradleOff, r1, r2, r3) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" fill="#f7f8f9"/>
  <path d="M150 340 Q256 300 362 340" fill="none" stroke="#c0c8d2" stroke-width="14" stroke-linecap="round"
        ${cradleOff < 100 ? `stroke-dasharray="100" stroke-dashoffset="${cradleOff.toFixed(2)}"` : ''}/>
  ${r1 > 0.2 ? `<circle cx="184" cy="256" r="${r1.toFixed(2)}" fill="#2b3a47"/>` : ''}
  ${r2 > 0.2 ? `<circle cx="256" cy="216" r="${r2.toFixed(2)}" fill="#2b3a47"/>` : ''}
  ${r3 > 0.2 ? `<circle cx="328" cy="176" r="${r3.toFixed(2)}" fill="#3f9d7a"/>` : ''}
</svg>`;

for (let i = 0; i < FRAMES; i++) {
  const t = i / (FRAMES - 1) * TOTAL;
  const cradleP = clamp(t / 0.5);
  const cradleOff = 100 * (1 - easeOut(cradleP));
  const r1 = popRadius(t, 0.5, 0.4, 38, 1.1);   // overshoot to ~42 then settle 38
  const r2 = popRadius(t, 0.9, 0.4, 42, 1.1);   // overshoot to ~46 then settle 42
  const r3 = popRadius(t, 1.3, 0.6, 52, 1.12);  // overshoot to ~58 then settle 52
  const svg = tpl(cradleOff, Math.max(0, r1), Math.max(0, r2), Math.max(0, r3));
  const r = new Resvg(svg, { fitTo: { mode: 'width', value: W } });
  fs.writeFileSync(path.join(outDir, `f_${String(i).padStart(3, '0')}.png`), r.render().asPng());
}
console.log(`Rendered ${FRAMES} frames at ${W}px to ${outDir}`);
