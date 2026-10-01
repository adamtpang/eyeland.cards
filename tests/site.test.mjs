import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const read = (name) => readFile(new URL(`../${name}`, import.meta.url), 'utf8');

test('home page exposes accurate metadata and trust links', async () => {
  const html = await read('index.html');
  const description = html.match(/<meta name="description" content="([^"]+)">/)?.[1] ?? '';

  assert.ok(description.length >= 70 && description.length <= 170);
  assert.match(html, /href="\/about\.html">About<\/a>/);
  assert.match(html, /href="\/contact\.html">Contact<\/a>/);
  assert.match(html, /href="\/privacy\.html">Privacy<\/a>/);
  assert.doesNotMatch(html, /<article\b/i);
  assert.doesNotMatch(html, /\sstyle=/i);
  assert.match(html, /waitlist costs \$0/i);
});

test('trust pages disclose the real operator and current collection behavior', async () => {
  const [about, contact, privacy] = await Promise.all([
    read('about.html'),
    read('contact.html'),
    read('privacy.html')
  ]);

  assert.match(about, /Adam Pangelinan/);
  assert.match(about, /Anchor Marianas/);
  assert.match(contact, /does not submit data to a website database/i);
  assert.match(privacy, /does not set cookies or load analytics/i);
  assert.match(privacy, /Vercel hosts this website/i);
});

test('deployment config enforces restrictive security headers', async () => {
  const config = JSON.parse(await read('vercel.json'));
  const headers = Object.fromEntries(config.headers[0].headers.map(({ key, value }) => [key, value]));
  const csp = headers['Content-Security-Policy'];

  assert.match(csp, /default-src 'self'/);
  assert.match(csp, /object-src 'none'/);
  assert.match(csp, /frame-ancestors 'none'/);
  assert.doesNotMatch(csp, /\*/);
  assert.doesNotMatch(csp, /unsafe-inline|unsafe-eval/);
  assert.equal(headers['X-Content-Type-Options'], 'nosniff');
});

test('sitemap includes every public HTML page', async () => {
  const sitemap = await read('sitemap.xml');
  for (const page of ['/', '/about.html', '/contact.html', '/privacy.html']) {
    const escaped = page.replaceAll('.', '\\.');
    assert.match(sitemap, new RegExp(`<loc>https://eyeland\\.cards${escaped}<\\/loc>`));
  }
});
