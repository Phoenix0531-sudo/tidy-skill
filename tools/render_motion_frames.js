// Frame-by-frame GIF renderer for the tidy-motion logo.
// resvg does not run SMIL timelines, so we manually compute per-frame
// stroke-dashoffset for the box/check and radius for the amber dot,
// then emit a PNG per frame. A companion PIL step stitches them to GIF.
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const TOTAL = 2.4; // seconds, matches SVG timeline
const FPS = 18;
const FRAMES = Math.round(TOTAL * FPS);
const W = 320; // gif width

const outDir = process.argv[2] || '.agent_tmp/_motion_frames';
fs.mkdirSync(outDir, { recursive: true });

const tpl = (boxOff, checkOff, dotR) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" fill="#ffffff"/>
  <g id="icon">
    <path d="M108 144 Q108 116 136 116 L208 116 L244 152 L376 152 Q404 152 404 180 L404 372 Q404 404 372 404 L140 404 Q108 404 108 372 Z"
          fill="#ffffff" stroke="#0f172a" stroke-width="18" stroke-linejoin="round"
          ${boxOff < 100 ? `stroke-dasharray="100" stroke-dashoffset="${boxOff}"` : ''}/>
    <path d="M176 280 L236 340 L352 212"
          fill="none" stroke="#0f172a" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"
          ${checkOff < 100 ? `stroke-dasharray="100" stroke-dashoffset="${checkOff}"` : ''}/>
    <circle cx="352" cy="212" r="${dotR}" fill="#f59e0b" stroke="#0f172a" stroke-width="10"/>
  </g>
</svg>`;

// easeOut: x -> 1-(1-x)^2.5, easeIn slightly on the dot.
const easeOut = (x) => 1 - Math.pow(1 - x, 2.5);
const clamp = (x) => Math.max(0, Math.min(1, x));

for (let i = 0; i < FRAMES; i++) {
  const t = i / (FRAMES - 1) * TOTAL; // 0..TOTAL
  // box draws 0..0.6s
  const boxP = clamp(t / 0.6);
  const boxOff = 100 * (1 - easeOut(boxP));
  // check draws 0.6..1.4s
  const checkP = clamp((t - 0.6) / 0.8);
  const checkOff = 100 * (1 - easeOut(checkP));
  // dot pops 1.4..1.8s, holds to end (loop gap handled by GIF)
  let dotR = 0;
  if (t >= 1.4) {
    const dotP = clamp((t - 1.4) / 0.4);
    dotR = easeOut(dotP) * 22;
    if (t >= 1.8) dotR = 22;
    // tiny overshoot pop
    if (t >= 1.4 && t < 1.8) dotR = easeOut(dotP) * 26 * 0.5 + easeOut(dotP) * 22 * 0.5;
  }
  const svg = tpl(boxOff, checkOff, Math.max(0, dotR));
  const r = new Resvg(svg, { fitTo: { mode: 'width', value: W } });
  const png = r.render().asPng();
  fs.writeFileSync(path.join(outDir, `f_${String(i).padStart(3, '0')}.png`), png);
}
console.log(`Rendered ${FRAMES} frames at ${W}px to ${outDir}`);
