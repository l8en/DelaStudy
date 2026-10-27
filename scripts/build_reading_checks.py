#!/usr/bin/env python3
"""Deterministic source-excerpt checks. No network or generative model.

These are text-comprehension exercises, not claims of conceptual mastery.
The source excerpt and attribution remain available in every round. An educator
still needs to review the automatically selected blanks before release.
"""
import json
import re
from pathlib import Path
from bs4 import BeautifulSoup

DIRECTORY = Path(__file__).resolve().parents[1] / 'Sources/FirstStateCore/Resources/Curriculum'
STOP = set('about above after again against almost along already also although always among another around because before being below between both cannot chapter could different does during each either enough even every example figure first following from further given have hence however into itself just like many might more most much must neither next only other over paragraph particular perhaps rather reading same second section should since some something still such than that their them then there these they third this those though three through thus together under using very what when where whether which while will with within without would your'.split())
STOP.update('measures measure describe explain examine construct calculate interpret collect record complete sentences student learning outcomes example examples consider important following relationship relationships information understand determine process answer answers question questions statement statements called known according provide provides related including include includes'.split())

OVERRIDES = {
    'geometry-1-1': [
        ('vertical', 'Opposite angles formed by two intersecting lines are _____ angles; their measures are equal.'),
        ('180', 'The measures of the two angles in a linear pair add to _____ degrees.'),
        ('adjacent', 'Two _____ angles share a vertex and a side without overlapping interiors.'),
        ('90', 'Two complementary angles have a total measure of _____ degrees.'),
    ],
    # These task pages have little explanatory prose. Supply original concept
    # checks rather than turning instructions such as "construct" into blanks.
    '14c67c2119c187bcc396': [
        ('histogram', 'A _____ groups numerical observations into intervals and shows their frequencies.'),
        ('univariate', 'Statistics describing one variable at a time are called _____ statistics.'),
        ('discrete', 'A count such as the number of pairs of shoes a person owns is a _____ variable.'),
        ('median', 'The line inside a standard box plot marks the _____ of the data.'),
    ],
}

def clean(value):
    return re.sub(r'\s+', ' ', value).strip()

def sentences(value):
    return re.split(r'(?<=[.!?])\s+(?=[A-Z“])', value)

def facts_for(reading):
    if reading['id'] in OVERRIDES:
        return [{'answer': answer, 'prompt': prompt, 'evidence': prompt.replace('_____', answer)} for answer, prompt in OVERRIDES[reading['id']]]
    soup = BeautifulSoup((DIRECTORY / reading['filename']).read_text(), 'html.parser')
    article = soup.select_one('article')
    candidates = []
    # Source-marked terms take precedence. Otherwise use a distinctive word in
    # a complete prose sentence; don't invent a definition or an explanation.
    for p in article.select('p, li'):
        if p.find_parent(['figure', 'footer', 'aside']) or p.select('code, table, img'):
            continue
        text = clean(p.get_text(' ', strip=True))
        preferred = [clean(t.get_text(' ', strip=True)) for t in p.select('[data-type="term"], strong, b, dfn')]
        for sentence in sentences(text):
            if not 35 <= len(sentence) <= 360 or sentence[-1:] not in '.!?':
                continue
            if 'Figure ' in sentence or 'Table ' in sentence or 'http' in sentence or '___' in sentence:
                continue
            terms = [t for t in preferred if 3 <= len(t) <= 45 and t in sentence and len(t.split()) <= 5]
            definition = re.match(r'(?:An? |The )?([A-Za-z][A-Za-z -]{2,38}?)\s+(?:is |are |has |have |refers? to |consists? of |means? |describes? |occurs? |forms? |joins? |measures? |share[s]? )', sentence)
            if not terms and definition and 1 <= len(definition[1].split()) <= 4:
                term = definition[1].strip()
                if term.lower() not in STOP and not term.lower().startswith(('this ', 'these ', 'they ')):
                    terms = [term]
            if not terms:
                words = re.findall(r'\b[A-Za-z][a-z]{5,17}\b', sentence)
                words = [w for w in words if w.lower() not in STOP]
                terms = sorted(words, key=lambda w: -len(w))
            for term in terms[:1]:
                if re.search(r'\b' + re.escape(term) + r'\b', sentence, re.I) is None:
                    continue
                blank = re.sub(r'\b' + re.escape(term) + r'\b', '_____', sentence, flags=re.I)
                candidates.append({'answer': term, 'prompt': blank, 'evidence': sentence, 'priority': int(term in preferred)})
    candidates.sort(key=lambda c: -c['priority'])
    facts = []
    used = set()
    for item in candidates:
        if item['answer'].casefold() in used or any(item['evidence'] == f['evidence'] for f in facts):
            continue
        used.add(item['answer'].casefold()); item.pop('priority'); facts.append(item)
        if len(facts) == 6:
            break
    if len(facts) < 3:
        raise ValueError(f"Need three unambiguous prose excerpts: {reading['filename']} ({len(facts)})")
    return facts

def main():
    catalog = json.loads((DIRECTORY / 'catalog.json').read_text())
    result = {r['id']: facts_for(r) for r in catalog['readings'].values()}
    (DIRECTORY / 'reading-checks.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f'{len(result)} source-linked rounds; {sum(map(len, result.values()))} excerpt facts')

if __name__ == '__main__':
    main()
