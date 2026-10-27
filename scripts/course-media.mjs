// Reproducible acquisition/validation of individually curated Commons files.
// No credentials, image generation, or runtime image service is used.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';
const root = process.cwd();
const cache = path.join(os.tmpdir(), 'first-state-course-media');
fs.mkdirSync(cache, { recursive: true });
const selectionsPath = path.join(root, 'Design/course-image-selections.json');
const selections = JSON.parse(fs.readFileSync(selectionsPath, 'utf8'));
const clean = s => String(s || '').replace(/<[^>]*>/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/\s+/g, ' ').trim();
function request(url) {
  // Avoid rapid sequential requests to the public API.
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1800);
  return execFileSync('curl', ['-fsSL', '--retry', '3', '--retry-all-errors', '--retry-delay', '10', '--max-time', '35', '-A', 'FirstStateLens/1.0 (educational collection research)', url], { maxBuffer: 15 * 1024 * 1024 });
}
function api(params) {
  return JSON.parse(request('https://commons.wikimedia.org/w/api.php?' + new URLSearchParams({ action: 'query', format: 'json', ...params })));
}
function describe(p) {
  const i = p.imageinfo?.[0], m = i?.extmetadata || {};
  return { title: p.title, source: i?.descriptionurl, original: i?.url, thumbnail: i?.thumburl, width: i?.width, height: i?.height,
    description: clean(m.ImageDescription?.value).slice(0, 1100), creator: clean(m.Artist?.value), license: clean(m.LicenseShortName?.value),
    licenseURL: clean(m.LicenseUrl?.value), date: clean(m.DateTimeOriginal?.value), credit: clean(m.Credit?.value),
    restrictions: clean(m.Restrictions?.value), categories: clean(m.Categories?.value), uploadDate: i?.timestamp };
}
const command = process.argv[2];
if (command === 'search') {
  for (const s of selections.filter(x => !x.file && (!process.argv[3] || x.id.includes(process.argv[3])))) {
    const file = path.join(cache, s.id + '-' + Buffer.from(s.search).toString('base64url').slice(0,80) + '-search.json');
    const data = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file)) : api({ generator: 'search', gsrsearch: s.search + ' filetype:bitmap', gsrnamespace: '6', gsrlimit: '4', prop: 'imageinfo', iiprop: 'url|size|extmetadata|timestamp', iiurlwidth: '960' });
    fs.writeFileSync(file, JSON.stringify(data, null, 2));
    console.log('\n' + s.id + ' / ' + s.search);
    for (const p of Object.values(data.query?.pages || {}).sort((a,b) => a.index-b.index)) console.log(JSON.stringify(describe(p)));
  }
} else if (command === 'records') {
  const cachedPages = fs.readdirSync(cache).filter(x => x.endsWith('.json')).flatMap(f => Object.values(JSON.parse(fs.readFileSync(path.join(cache, f))).query?.pages || {}));
  const chosen = selections.filter(x => x.file && (!process.argv[3] || x.id.includes(process.argv[3])));
  const missing = [];
  for (const s of chosen) {
    const page = cachedPages.find(p => p.title.normalize() === s.file.normalize());
    if (page?.imageinfo) {
      fs.writeFileSync(path.join(cache, s.id + '-record.json'), JSON.stringify({ query: { pages: { [page.pageid]: page } } }, null, 2));
      console.log(s.id, JSON.stringify(describe(page)));
    } else { missing.push(s); }
  }
  for (let start = 0; start < missing.length; start += 10) {
    const batch = missing.slice(start, start + 10);
    const data = api({ titles: batch.map(x => x.file).join('|'), prop: 'imageinfo', iiprop: 'url|size|extmetadata|timestamp', iiurlwidth: '960' });
    for (const s of batch) {
      const page = Object.values(data.query?.pages || {}).find(p => p.title.normalize() === s.file.normalize());
      if (!page?.imageinfo) throw Error('Missing file: ' + s.file);
      fs.writeFileSync(path.join(cache, s.id + '-record.json'), JSON.stringify({ query: { pages: { [page.pageid]: page } } }, null, 2));
      console.log(s.id, JSON.stringify(describe(page)));
    }
  }
} else if (command === 'acquire') {
  const dest = path.join(root, 'Sources/FirstStateCore/Resources/CourseMedia');
  fs.mkdirSync(dest, { recursive: true });
  const assets = [];
  for (const s of selections) {
    if (!s.file && process.argv.includes('--partial')) continue;
    if (!s.file) throw Error('Unselected: ' + s.id);
    const data = JSON.parse(fs.readFileSync(path.join(cache, s.id + '-record.json')));
    const d = describe(Object.values(data.query.pages)[0]);
    if (!/^(CC BY-SA|CC BY|CC0|Public domain)/i.test(d.license)) throw Error('Review rights: ' + s.id + ': ' + d.license);
    if (!d.creator || !d.source || !d.original || !s.reason || !s.alt) throw Error('Incomplete: ' + s.id);
    const downloadURL = (d.thumbnail || d.original).replace(/\?.*$/, '');
    const downloaded = path.join(cache, s.id + '-download');
    if (!fs.existsSync(downloaded)) fs.writeFileSync(downloaded, request(downloadURL));
    const localFile = s.id + '.jpg';
    execFileSync('sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', '76', '-Z', '960', downloaded, '--out', path.join(dest, localFile)], { stdio: 'pipe' });
    assets.push({ id: s.id, courseIDs: s.courseIDs, filename: localFile, title: s.title || d.title.replace(/^File:/, '').replace(/\.[^.]+$/, ''),
      creator: d.creator, institution: s.institution || 'Wikimedia Commons contributor', sourceURL: d.source, originalURL: d.original.replace(/\?.*$/, ''), downloadURL,
      license: d.license, licenseURL: (d.licenseURL || 'https://commons.wikimedia.org/wiki/Commons:Public_domain').replace(/^http:/, 'https:'),
      credit: s.credit || `${d.creator} · ${d.license}`, accessedOn: '2026-10-24', sourceDate: d.date || d.uploadDate,
      modifications: 'Resized to a maximum 960 px and JPEG-compressed. Display cropping only; no generated content, recoloring, or retouching.',
      alt: s.alt, focalX: s.focal?.[0] ?? 0.5, focalY: s.focal?.[1] ?? 0.5, fit: s.fit || 'fill', reason: s.reason,
      medium: s.medium || 'Photograph', provenance: s.provenance || d.credit || `Creator record and original upload ${d.uploadDate}.`,
      sourceDescription: d.description, filePageTitle: s.file, sourceUploadDate: d.uploadDate });
    console.log(s.id, Math.round(fs.statSync(path.join(dest, localFile)).size / 1024) + ' KB');
  }
  fs.writeFileSync(path.join(dest, 'catalog.json'), JSON.stringify(assets, null, 2) + '\n');
  console.log(assets.length + ' assets / ' + assets.reduce((n,x) => n + x.courseIDs.length, 0) + ' course mappings');
} else if (command === 'validate') {
  const dest = path.join(root, 'Sources/FirstStateCore/Resources/CourseMedia');
  const assets = JSON.parse(fs.readFileSync(path.join(dest, 'catalog.json')));
  const ids = new Set(); let bytes = 0;
  for (const a of assets) {
    for (const id of a.courseIDs) { if (ids.has(id)) throw Error('Duplicate mapping: ' + id); ids.add(id); }
    for (const key of ['sourceURL', 'originalURL', 'licenseURL']) if (!a[key].startsWith('https://')) throw Error('Invalid URL: ' + a.id);
    const file = fs.readFileSync(path.join(dest, a.filename));
    if (file[0] !== 255 || file[1] !== 216) throw Error('Not a JPEG: ' + a.id);
    bytes += file.length;
  }
  console.log(`${assets.length} valid JPEGs, ${ids.size} unique course mappings, ${(bytes / 1048576).toFixed(2)} MiB shipped images`);
} else { console.log('Usage: node scripts/course-media.mjs search|records [id fragment]|acquire|validate'); }
