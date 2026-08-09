// Frame-by-frame motion GIF renderer for the three-layer-prism tidy logo.
// resvg does not run SMIL timelines, so we compute per-frame:
//   - hex frame stroke-dashoffset (0..0.5s)
//   - three tiers opacity cascade (0.5..1.4s)
//   - amber dot radius pop (1.5..1.9s)
//   - hold to 2.6s
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const TOTAL = 2.6;
const FPS = 18;
const FRAMES = Math.round(TOTAL * FPS);
const W = 320;
const outDir = process.argv[2] || '.agent_tmp/_motion_frames';
fs.mkdirSync(outDir, { recursive: true });

const easeOut = (x) => 1 - Math.pow(1 - x, 2.5);
const clamp = (x) => Math.max(0, Math.min(1, x));

const tpl = (hexOff, op1, op2, op3, dotR) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="96" fill="#17211d"/>
  <path d="M256 56 L424 152 L424 360 L256 456 L88 360 L88 152 Z" fill="none" stroke="#fffdf8" stroke-width="22" stroke-linejoin="round"
        ${hexOff < 100 ? `stroke-dasharray="100" stroke-dashoffset="${hexOff.toFixed(2)}"` : ''}/>
  <rect x="168" y="206" width="176" height="34" rx="10" fill="#0f6b5f" opacity="${op1.toFixed(3)}"/>
  <rect x="144" y="248" width="224" height="34" rx="10" fill="#0f6b5f" opacity="${op2.toFixed(3)}"/>
  <rect x="168" y="290" width="176" height="34" rx="10" fill="#0f6b5f" opacity="${op3.toFixed(3)}"/>
  ${dotR > 0.2 ? `<circle cx="312" cy="223" r="${dotR.toFixed(2)}" fill="#c07a22"/><circle cx="312" cy="223" r="${(dotR*0.34).toFixed(2)}" fill="#fffdf8"/>` : ''}
</svg>`;

for (let i = 0; i < FRAMES; i++) {
  const t = i / (FRAMES - 1) * TOTAL;
  const hexP = clamp(t / 0.5);
  const hexOff = 100 * (1 - easeOut(hexP));
  // tier opacities cascade
  const op1 = clamp((t - 0.5) / 0.3) * 0.55;
  const op2 = clamp((t - 0.8) / 0.3) * 0.85;
  const op3 = clamp((t - 1.1) / 0.3) * 0.55;
  // amber dot pops
  let dotR = 0;
  if (t >= 1.5) {
    const dotP = clamp((t - 1.5) / 0.4);
    dotR = easeOut(dotP) * 18;
    if (t >= 1.5 && t < 1.9) dotR = easeOut(dotP) * 22 * 0.5 + easeOut(dotP) * 18 * 0.5;
  }
  const svg = tpl(hexOff, op1, op2, op3, Math.max(0, dotR));
  const r = new Resvg(svg, { fitTo: { mode: 'width', value: W } });
  fs.writeFileSync(path.join(outDir, `f_${String(i).padStart(3, '0')}.png`), r.render().asPng());
}
console.log(`Rendered ${FRAMES} frames at ${W}px to ${outDir}`);
