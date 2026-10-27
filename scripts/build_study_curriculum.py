#!/usr/bin/env python3
"""Build the noncommercial, attributed OpenStax reading collection.

Run with beautifulsoup4 and lxml installed. Network is used only at build time.
The downloaded content and source manifest are bundled; learners need no account.
"""
import concurrent.futures
import hashlib
import html
import json
import re
import sys
import time
import urllib.request
from pathlib import Path
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
CACHE = Path('/tmp/first-state-curriculum-cache')
DEST = ROOT / 'Sources/FirstStateCore/Resources/Curriculum'
CACHE.mkdir(exist_ok=True)
DEST.mkdir(parents=True, exist_ok=True)

# Each unit selects three complete textbook sections, each followed by a recall lab.
# Chapter ranges, not labels chosen by an algorithm, define the editorial scope.
PLANS = {
 'first-state-civics': ('us-history', [('Colonial worlds', [2,3]), ('Independence', [5,6]), ('Making a republic', [7]), ('Expansion & conflict', [11,14]), ('Reconstruction & citizenship', [16])]),
 'algebra-i': ('elementary-algebra-2e', [('Numbers & expressions', [1]), ('Solving equations', [2]), ('Models & inequalities', [3]), ('Graphs & lines', [4]), ('Systems', [5])]),
 'algebra-ii': ('intermediate-algebra-2e', [('Equations & inequalities', [2]), ('Functions & graphs', [3]), ('Polynomial operations', [5]), ('Radicals & quadratics', [8,9]), ('Exponential models', [10])]),
 'precalculus': ('precalculus-2e', [('Functions', [1]), ('Polynomial models', [3]), ('Exponents & logarithms', [4]), ('Trigonometry', [5]), ('Analytic trigonometry', [7])]),
 'college-algebra': ('college-algebra-2e', [('Functions', [3]), ('Linear models', [4]), ('Polynomial models', [5]), ('Exponents & logarithms', [6]), ('Systems', [7])]),
 'high-school-statistics': ('introductory-statistics-2e', [('Collecting data', [1]), ('Describing data', [2]), ('Probability', [3]), ('Random variables', [4]), ('Normal distributions', [6])]),
 'college-statistics': ('introductory-statistics-2e', [('Sampling & variation', [1,2]), ('Probability models', [3,4]), ('Continuous distributions', [5,6]), ('Estimation', [7,8]), ('Testing & relationships', [9,12])]),
 'ap-biology': ('biology-2e', [('Life & scientific inquiry', [1,2]), ('Biological molecules', [3]), ('Cells', [4]), ('Membranes', [5]), ('Energy & metabolism', [6,7])]),
 'general-biology': ('biology-2e', [('Chemical foundations', [2,3]), ('Cells & membranes', [4,5]), ('Energy', [6,7,8]), ('Inheritance', [10,12]), ('Genes & expression', [14,15])]),
 'high-school-chemistry': ('chemistry-2e', [('Matter & measurement', [1]), ('Atoms & molecules', [2]), ('Composition', [3]), ('Chemical reactions', [4]), ('Electronic structure', [6])]),
 'general-chemistry': ('chemistry-2e', [('Measurement & atoms', [1,2]), ('Stoichiometry', [3,4]), ('Thermochemistry', [5]), ('Electronic structure', [6]), ('Bonding', [7,8])]),
 'high-school-physics': ('physics', [('Physics & measurement', [1]), ('Motion', [2]), ('Acceleration & rotation', [3,6]), ('Forces', [4]), ('Energy & momentum', [8,9])]),
 'university-physics': ('university-physics-volume-1', [('Measurement & vectors', [1,2]), ('Motion', [3,4]), ('Newton’s laws', [5]), ('Applying forces', [6]), ('Work & energy', [7,8])]),
 'environmental-science': ('biology-2e', [('Ecological systems', [44]), ('Population ecology', [45]), ('Ecosystems', [46]), ('Biodiversity', [47]), ('Plant foundations', [30])]),
 'english-composition': ('writing-guide', [('Rhetorical situations', [1]), ('Language & identity', [3]), ('Memoir', [4]), ('Profile writing', [5]), ('Argument & evidence', [10])]),
 'writing-rhetoric': ('writing-guide', [('Rhetorical situations', [1]), ('Rhetorical analysis', [9]), ('Argument', [10]), ('Research', [12]), ('Source research & ethics', [13])]),
 'world-history': ('world-history-volume-2', [('Interconnected worlds', [1]), ('Empires & exchange', [2]), ('African trade networks', [3]), ('Islamic empires', [4]), ('Revolutions', [7])]),
 'us-government': ('american-government-3e', [('Government & participation', [1]), ('The Constitution', [2]), ('Federalism', [3]), ('Civil liberties', [4]), ('Civil rights', [5])]),
 'college-government': ('american-government-3e', [('Constitutional foundations', [2,3]), ('Rights & liberties', [4,5]), ('Public opinion & elections', [6,7]), ('Congress & presidency', [11,12]), ('Courts & policy', [13,16])]),
 'high-school-economics': ('principles-economics-3e', [('Thinking economically', [1]), ('Choice & scarcity', [2]), ('Demand & supply', [3]), ('Labor & finance', [4]), ('Elasticity', [5])]),
 'microeconomics': ('principles-microeconomics-3e', [('Choices', [1,2]), ('Markets', [3]), ('Elasticity', [5]), ('Households', [6]), ('Firms & production', [7])]),
 'macroeconomics': ('principles-macroeconomics-3e', [('Economic foundations', [1,2]), ('Measuring output', [6]), ('Growth', [7]), ('Unemployment', [8]), ('Inflation', [9])]),
 'intro-psychology': ('psychology-2e', [('Psychological science', [1,2]), ('Biopsychology', [3]), ('Sensation & perception', [5]), ('Learning & memory', [6,8]), ('Development', [9])]),
 'sociology': ('introduction-sociology-3e', [('Sociological thinking', [1]), ('Research', [2]), ('Culture', [3]), ('Social interaction', [4]), ('Socialization', [5])]),
 'computer-science': ('introduction-computer-science', [('Computer science & society', [1]), ('Computational thinking & design', [2]), ('Algorithms & theory', [3]), ('Models of computation', [4]), ('Computer architecture', [5])]),
 'calculus-i': ('calculus-volume-1', [('Functions', [1]), ('Limits', [2]), ('Derivatives', [3]), ('Applications', [4]), ('Integration', [5])]),
}
ALIASES = {
 'prep-biology': 'general-biology', 'prep-chemistry': 'general-chemistry',
 'prep-environmental-science': 'environmental-science', 'prep-calculus-ab': 'calculus-i',
 'prep-statistics': 'college-statistics', 'prep-english-language-and-composition': 'writing-rhetoric',
 'prep-united-states-history': 'first-state-civics',
 'prep-united-states-government-and-politics': 'college-government', 'prep-psychology': 'intro-psychology',
}

def get(url):
    key = hashlib.sha256(url.encode()).hexdigest()
    path = CACHE / key
    if path.exists(): return path.read_bytes()
    for retry in range(4):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'FirstStateLens-EducationalCollection/1.0'})
            with urllib.request.urlopen(req, timeout=70) as response: data = response.read()
            path.write_bytes(data)
            return data
        except Exception:
            if retry == 3: raise
            time.sleep(2 ** retry)

def document(body):
    return '''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><style>
    :root { color-scheme: light dark; } html { max-width:100%; overflow-x:hidden; } body { font: -apple-system-body; line-height:1.65; margin:20px; color:#18233a; background:#fcfcfa; overflow-wrap:break-word; min-width:0; } article { max-width:100%; min-width:0; }
    h1 { font-size:1.6em; line-height:1.2; } h2 { font-size:1.25em; line-height:1.3; margin-top:1.8em; } h3 { font-size:1.1em; }
    a { color:#3455d1; } img,svg { max-width:100%; height:auto; } figure { margin:1.5em 0; } figcaption,footer,aside { font-size:.9em; } footer { border-top:1px solid #b4bfd1; margin-top:2em; padding-top:1em; } aside { border-left:3px solid #3455d1; padding-left:1em; margin-bottom:1.5em; }
    .math-scroll,.table-scroll { max-width:100%; overflow-x:auto; overscroll-behavior-x:contain; } table { border-collapse:collapse; } th,td { padding:.5em; border:1px solid #b4bfd1; } math[display=block] { padding:.5em 0; } pre { max-width:100%; overflow-x:auto; } code { font-family:ui-monospace,monospace; } [data-type=note] { border-left:3px solid #3455d1; padding-left:1em; margin:1.5em 0; }
    @media(prefers-color-scheme:dark) { body { background:#10151d; color:#f0f3fa; } a { color:#a2b5ff; } img { background:#fff; } }
    </style></head><body>''' + body + '</body></html>'

def state(soup):
    script = next(x.text for x in soup.find_all('script') if 'window.__PRELOADED_STATE__ =' in x.text)
    return json.JSONDecoder().raw_decode(script.split(' = ', 1)[1])[0]['content']

def sections(node):
    result = []
    if node.get('toc_target_type') == 'numbered-section': result.append(node)
    for child in node.get('contents', []): result.extend(sections(child))
    return result

def toc(book):
    url = f'https://openstax.org/books/{book}/pages/preface'
    content = state(BeautifulSoup(get(url), 'lxml'))
    data = content['book']
    return book, {'title': data['title'], 'license': data['license'], 'version': data['contentVersion'], 'sections': sections(data['tree'])}

def read_section(job):
    book, item, metadata = job
    url = f'https://openstax.org/books/{book}/pages/{item["slug"]}'
    soup = BeautifulSoup(get(url), 'lxml')
    page = soup.select_one('[data-type="page"]')
    if page is None: raise ValueError(f'Missing content: {url}')
    title = BeautifulSoup(item['title'], 'lxml').get_text(' ', strip=True)
    text = page.get_text(' ', strip=True)
    if len(text.split()) < 120: raise ValueError(f'Too little instruction: {url}')
    objectives = [x.get_text(' ', strip=True) for x in page.select('[data-type="abstract"] li')]
    # Script-free reader. MathML and worked examples remain; media source links stay explicit.
    for x in page.select('button'): x.unwrap()
    for x in page.select('script, iframe, video, audio, input, style'): x.decompose()
    for x in page.find_all(True):
        for attr in list(x.attrs):
            if attr.startswith('on') or attr in ('style', 'srcset'): del x[attr]
    # Illustrations retain original captions and credits. Bundle the exact licensed image.
    for image in page.select('img'):
        src = image.get('src', '')
        src = urllib.parse.urljoin(url, src)
        try:
            data = get(src)
            ext = Path(urllib.parse.urlparse(src).path).suffix.lower()
            if ext not in ('.jpg', '.jpeg', '.png', '.svg', '.gif', '.webp'): ext = '.webp' if 'f=webp' in src else '.png'
            name = hashlib.sha256(src.encode()).hexdigest()[:24] + ext
            (DEST / name).write_bytes(data)
            image['src'] = name
        except Exception:
            # Do not silently omit diagrams essential to the lesson.
            raise ValueError(f'Image unavailable in {url}: {src}')
    for a in page.select('a[href]'):
        href = a['href']
        if href.startswith('#'): continue
        a['href'] = urllib.parse.urljoin(url, href)
        if not a['href'].startswith(('https://', 'http://')): del a['href']
    for expression in page.select('math[display="block"]'):
        expression.wrap(soup.new_tag('div', attrs={'class': 'math-scroll'}))
    for table in page.select('table'):
        table.wrap(soup.new_tag('div', attrs={'class': 'table-scroll'}))
    key = hashlib.sha256(url.encode()).hexdigest()[:20]
    filename = key + '.html'
    credit = f'Adapted from OpenStax, {metadata["title"]}, {title}. Formatting adapted for this reader; content and original figure credits retained.'
    # Reader styles are injected by the app to follow text size and appearance.
    body = f'<article>{page}</article><footer><p>{html.escape(credit)}</p><p><a href="{url}">Access the original free textbook</a> · <a href="{metadata["license"]["url"]}">{html.escape(metadata["license"]["name"])}</a></p></footer>'
    (DEST / filename).write_text(document(body))
    return url, {'id': key, 'title': title, 'filename': filename, 'sourceURL': url, 'book': metadata['title'], 'license': metadata['license']['name'], 'licenseURL': metadata['license']['url'], 'version': metadata['version'], 'wordCount': len(text.split()), 'recallPrompts': objectives[:5] or [f'Explain the main relationship in {title} using a specific example, then check it against the reading.']}

def main():
    if '--extras-only' in sys.argv:
        manifest = json.loads((DEST / 'catalog.json').read_text())
        for course, (_, units) in PLANS.items():
            for unit, (title, _) in zip(manifest['courses'][course], units): unit['title'] = title
        for alias, original in ALIASES.items():
            for unit, originalUnit in zip(manifest['courses'][alias], manifest['courses'][original]): unit['title'] = originalUnit['title']
        append_originals(manifest['courses'], manifest['readings'])
        append_literature(manifest['courses'], manifest['readings'])
        used = {url for units in manifest['courses'].values() for unit in units for url in unit['readingURLs']}
        manifest['readings'] = {url: r for url, r in manifest['readings'].items() if url in used}
        (DEST / 'catalog.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
        print(f'Built {len(manifest["courses"])} courses, {len(manifest["readings"])} readings.', flush=True)
        return
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        books = dict(pool.map(toc, sorted({p[0] for p in PLANS.values()})))
    (CACHE / 'tocs.json').write_text(json.dumps(books, indent=2))
    plans = {}
    jobs = {}
    for course, (book, units) in PLANS.items():
        used = set(); result = []
        for number, (title, chapters) in enumerate(units, 1):
            candidates = [s for s in books[book]['sections'] if int(s['slug'].split('-')[0]) in chapters and s['slug'] not in used]
            if len(candidates) < 3: raise ValueError(f'{course}/{title}: only {len(candidates)} sections')
            # First, middle, last preserve breadth within the chosen chapter range.
            picks = [candidates[i] for i in [0, len(candidates)//2, len(candidates)-1]]
            urls = []
            for section in picks:
                used.add(section['slug'])
                url = f'https://openstax.org/books/{book}/pages/{section["slug"]}'
                urls.append(url); jobs[url] = (book, section, books[book])
            result.append({'id': f'{course}-unit-{number}', 'title': title, 'readingURLs': urls})
        plans[course] = result
    for alias, original in ALIASES.items():
        plans[alias] = [{**u, 'id': u['id'].replace(original, alias)} for u in plans[original]]
    readings = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for i, (url, reading) in enumerate(pool.map(read_section, jobs.values()), 1):
            readings[url] = reading
            print(f'{i}/{len(jobs)} {reading["title"]}', flush=True)
    append_originals(plans, readings)
    append_literature(plans, readings)
    used = {url for units in plans.values() for unit in units for url in unit['readingURLs']}
    readings = {url: r for url, r in readings.items() if url in used}
    manifest = {'retrievedOn': '2026-10-24', 'courses': plans, 'readings': readings}
    (DEST / 'catalog.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f'Built {len(plans)} courses, {len(readings)} full readings.', flush=True)

def append_originals(plans, readings):
    originals = json.loads((ROOT / 'Design/original-study-lessons.json').read_text())
    originals.update(json.loads((ROOT / 'Design/personal-finance-study-lessons.json').read_text()))
    references = {
        'geometry': 'https://openstax.org/books/elementary-algebra-2e/pages/9-introduction',
        'prep-computer-science-a': 'https://dev.java/learn/language-basics/',
        'personal-finance': [
            'https://www.consumerfinance.gov/consumer-tools/educator-tool/your-money-your-goals/toolkit/',
            'https://www.consumerfinance.gov/consumer-tools/educator-tool/your-money-your-goals/toolkit/',
            'https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/',
            'https://www.consumerfinance.gov/consumer-tools/credit-cards/',
            'https://www.consumerfinance.gov/consumer-tools/student-loans/'
        ]
    }
    for course, units in originals.items():
        plans[course] = []
        for i, unit in enumerate(units, 1):
            reference = references[course][i-1] if isinstance(references[course], list) else references[course]
            urls = []
            for j, (title, instruction, example, challenge, check) in enumerate(unit['lessons'], 1):
                key = f'{course}-{i}-{j}'
                url = f'https://firststatelens.local/lessons/{key}'
                filename = key + '.html'
                extra = ' Financial examples are hypothetical, not current offers or individualized advice.' if course == 'personal-finance' else ''
                body = f'<article><h1>{html.escape(title)}</h1><p>{html.escape(instruction)}</p><h2>Worked example</h2><p>{html.escape(example)}</p></article><footer><p>Original First State Lens instruction. Selected foundations, not complete course coverage.{extra}</p><a href="{reference}">Reference for further study</a></footer>'
                (DEST / filename).write_text(document(body))
                readings[url] = {'id': key, 'title': title, 'filename': filename, 'sourceURL': reference, 'book': 'First State Lens · original instruction', 'license': 'Original lesson; linked reference is not reproduced', 'licenseURL': None, 'version': '2026-10-24', 'wordCount': len((instruction + ' ' + example).split()), 'recallPrompts': [challenge], 'selfCheck': check}
                urls.append(url)
            plans[course].append({'id': f'{course}-unit-{i}', 'title': unit['title'], 'readingURLs': urls})

def append_literature(plans, readings):
    # Selected public-domain primary texts, not generated literary summaries.
    works = [(23, 'Frederick Douglass', 'Narrative of the Life of Frederick Douglass', 'Testimony & freedom'),
             (33, 'Nathaniel Hawthorne', 'The Scarlet Letter', 'Symbol & social judgment'),
             (2701, 'Herman Melville', 'Moby-Dick', 'Narrator & the sea'),
             (514, 'Louisa May Alcott', 'Little Women', 'Character & domestic life'),
             (541, 'Edith Wharton', 'The Age of Innocence', 'Society & perspective')]
    plans['american-literature'] = []
    for i, (number, author, title, theme) in enumerate(works, 1):
        url = f'https://www.gutenberg.org/ebooks/{number}.html.images'
        soup = BeautifulSoup(get(url), 'lxml')
        chapters = [c for c in soup.select('div.chapter') if c.find('h2') and re.search(r'^(CHAPTER\s+(?:I\b|II\b|III\b|1\b|2\b|3\b)|[IVX]+\.?\s*$|1\s|2\s|3\s)', c.find('h2').get_text(' ',strip=True), re.I)]
        if len(chapters) < 3:
            chapters = [c for c in soup.select('div.chapter') if c.find('h2') and len(c.get_text(' ',strip=True).split()) > 300 and not re.search(r'preface|contents|introduction|etymology|extracts|custom-house',c.find('h2').get_text(),re.I)]
        if len(chapters) < 3:
            chapters = []
            for heading in soup.select('h2,h3'):
                if not re.search(r'^(CHAPTER\s+[123]\b|I\.$|II\.$|III\.$)', heading.get_text(' ',strip=True), re.I): continue
                part = soup.new_tag('div')
                part.append(BeautifulSoup(str(heading), 'lxml').find(heading.name))
                for sibling in heading.next_siblings:
                    if getattr(sibling, 'name', '') in ('h2', 'h3'): break
                    fragment = BeautifulSoup(str(sibling), 'html.parser')
                    part.append(fragment)
                chapters.append(part)
        if len(chapters) < 3: raise ValueError(f'Need three verified chapters: {title}')
        urls = []
        for j, chapter in enumerate(chapters[:3], 1):
            heading = chapter.find(['h2', 'h3']).get_text(' ',strip=True)
            for image in chapter.select('img'): image.decompose()
            for script in chapter.select('script, iframe'): script.decompose()
            for a in chapter.select('a[href]'): a['href'] = urllib.parse.urljoin(url, a['href'])
            key = f'literature-{number}-{j}'; filename = key + '.html'
            source = f'https://www.gutenberg.org/ebooks/{number}'
            chapterURL = f'https://firststatelens.local/primary/{key}'
            # The original primary text stays intact; warning and analysis are separate.
            body = f'<article><p><strong>{html.escape(author)} · {html.escape(title)}</strong></p><aside>Historical text: may include enslavement, violence, and discriminatory language. Read critically; the app does not endorse these views.</aside>{chapter}</article><footer><p>Primary text by {html.escape(author)}. Public domain in the United States. Transcription: Project Gutenberg; original spelling retained. Selected chapter, not the complete work.</p><a href="{source}">Read the complete work and its ebook terms</a></footer>'
            (DEST / filename).write_text(document(body))
            prompts = [f'In {heading}, identify a telling detail about the narrator or focal character. Explain what the wording supports and what it does not establish.', f'Choose a short passage from {heading}. Explain how diction, imagery, or dialogue shapes the reader’s response; distinguish textual evidence from your interpretation.', f'Connect a specific conflict in this chapter to the unit theme “{theme}.” Offer a plausible alternative interpretation and compare the evidence.']
            readings[chapterURL] = {'id':key, 'title': f'{author} · {heading}', 'filename':filename, 'sourceURL':source, 'book':title, 'license':'Primary text: public domain in the USA; check local law elsewhere', 'licenseURL':'https://www.gutenberg.org/policy/license.html', 'version':'2026-10-24', 'wordCount':len(chapter.get_text(' ',strip=True).split()), 'recallPrompts':prompts}
            urls.append(chapterURL)
        plans['american-literature'].append({'id':f'american-literature-unit-{i}','title':theme,'readingURLs':urls})

if __name__ == '__main__': main()
