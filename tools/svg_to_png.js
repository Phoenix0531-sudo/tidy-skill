// Local SVG -> PNG exporter using @resvg/resvg-js (WASM, zero-native-dep).
// Usage: node tools/svg_to_png.js <input.svg> <output-dir> [sizes...]
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const [,, inSvg, outDir, ...sizeArgs] = process.argv;
if (!inSvg || !outDir) {
  console.error('Usage: svg_to_png.js <input.svg> <output-dir> [sizes...]');
  process.exit(1);
}
const sizes = sizeArgs.length ? sizeArgs.map(Number) : [16, 32, 48, 192, 512, 1024, 2048];
const svg = fs.readFileSync(inSvg, 'utf-8');
fs.mkdirSync(outDir, { recursive: true });
const base = path.basename(inSvg, '.svg');
for (const size of sizes) {
  const r = new Resvg(svg, { fitTo: { mode: 'width', value: size } });
  const png = r.render().asPng();
  const out = path.join(outDir, `${base}-${size}.png`);
  fs.writeFileSync(out, png);
  console.log(`  Exported: ${base}-${size}.png (${size}x${size})`);
}
console.log(`\nDone. Files in: ${outDir}`);
