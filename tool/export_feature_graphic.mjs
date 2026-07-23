#!/usr/bin/env node
/**
 * Export Play Store feature graphic (1024×500 PNG).
 * Run: npm install --prefix tool && node tool/export_feature_graphic.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const inputSvg = join(root, 'assets', 'store', 'feature-graphic.svg');
const outputPng = join(root, 'assets', 'store', 'feature-graphic.png');

const svg = readFileSync(inputSvg, 'utf8');
const resvg = new Resvg(svg, {
  fitTo: { mode: 'width', value: 1024 },
  background: '#08080E',
});
const rendered = resvg.render();
writeFileSync(outputPng, rendered.asPng());
console.log(`Wrote ${outputPng} (${rendered.width}x${rendered.height})`);
