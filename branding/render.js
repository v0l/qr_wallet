// Render an SVG in this directory to a PNG at a given width.
//   node render.js icon.svg icon-1024.png 1024
const { Resvg } = require('@resvg/resvg-js');
const fs = require('fs');

const [, , input, output, size] = process.argv;
const svg = fs.readFileSync(input, 'utf8');
const r = new Resvg(svg, { fitTo: { mode: 'width', value: parseInt(size, 10) } });
fs.writeFileSync(output, r.render().asPng());
console.log(`${output} @ ${size}px`);
