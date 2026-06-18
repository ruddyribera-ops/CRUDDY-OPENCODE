# progressive-disclosure.md — Patrones Avanzados de Slide

## Progressive Disclosure

**Cuándo:** Cuando un tema tiene 5+ items o 80+ palabras.

**Cómo:**
- Slide A: título + contexto + primeros 2-3 items
- Slide B: mismo título + todos los items (marcando los nuevos)
- Fade transition entre ambos

```python
def build_progressive_pair(prs, theme, title, all_items, icon=''):
    """Crea 2 slides con progressive disclosure."""
    from code_helpers import add_fade_transition, rect, txt
    
    mitad = len(all_items) // 2 + 1
    
    for phase, items in enumerate([all_items[:mitad], all_items]):
        s = prs.slides.add_slide(prs.slide_layouts[6])
        add_bg(s, theme['bg'])
        add_fade_transition(s)
        # Title bar
        rect(s, 0, 0, 13.333, 1.2, theme['primary'])
        tag = ' (continuacion)' if phase == 1 else ''
        txt(s, 0.6, 0.15, 12, 0.7, f'{icon} {title}{tag}', 26, True, WHITE)
        rect(s, 0, 1.2, 13.333, 0.06, theme['accent'])
        # Items numerados
        for i, item in enumerate(items):
            y = 1.7 + i * 0.8
            color = theme['secondary'] if (phase == 1 and i >= len(all_items)//2) else theme['primary']
            rect(s, 0.8, y, 0.5, 0.5, color)
            txt(s, 0.8, y+0.05, 0.5, 0.4, str(i+1), 14, True, WHITE, PP_ALIGN.CENTER)
            txt(s, 1.5, y+0.05, 10, 0.4, item, 15, theme['text'])
        # Footer + page number
        # ...
```

## Image Labeling

**Cuándo:** La imagen es el elemento principal del slide.

**Cómo:** Etiqueta SEMI-TRANSPARENTE sobre la imagen + badge comparativo abajo.

```python
def add_labeled_image(slide, img_path, x, y, w, h, label, subtitle, size_cmp, theme):
    """Imagen + label + badge. La etiqueta VA SOBRE la imagen."""
    add_img(slide, img_path, x, y, w, h)
    # Label superior izquierdo
    rect(slide, x+0.2, y+0.1, 3.0, 0.7, theme['primary'])
    txt(slide, x+0.4, y+0.15, 2.6, 0.5, label, 16, True, WHITE)
    txt(slide, x+0.4, y+0.5, 2.6, 0.3, subtitle, 10, color=RGBColor(0xD4,0xEC,0xEC))
    # Badge tamaño comparativo (esquina inferior)
    rect(slide, x+0.2, y+h-0.6, 2.8, 0.5, theme['secondary'])
    txt(slide, x+0.4, y+h-0.55, 2.4, 0.4, size_cmp, 11, True, WHITE)
```

## Data Cards (Cognitive Load Optimized)

**Cuándo:** Datos numéricos, fechas, estadísticas.

**Cómo:** 3-4 tarjetas en fila. Cada una: icono grande + número enorme + texto mínimo.

```python
def build_data_cards(slide, cards_data, theme, start_y=1.7):
    """cards_data = [(icon, value, label, accent_color), ...]"""
    card_w = 3.8
    gap = 0.4
    for i, (icon, value, label, color) in enumerate(cards_data):
        x = 0.6 + i * (card_w + gap)
        # Card background
        rect(slide, x, start_y, card_w, 3.0, WHITE)
        rect(slide, x, start_y, card_w, 0.08, color)  # top accent bar
        # Icon
        txt(slide, x+1.2, start_y+0.2, 1.4, 0.7, icon, 36, align=PP_ALIGN.CENTER)
        # Big number
        txt(slide, x+0.2, start_y+0.9, card_w-0.4, 0.6, value, 26, True, color, PP_ALIGN.CENTER)
        # Label
        txt(slide, x+0.2, start_y+1.5, card_w-0.4, 1.0, label, 14, align=PP_ALIGN.CENTER)
```

## Auto Image Fetching

**Cuándo:** Necesitas imágenes para los slides y no están en el directorio.

```python
import urllib.request, urllib.parse, json, time

def fetch_image_by_topic(query, output_path):
    """Busca imagen en Commons por keyword y la descarga."""
    headers = {'User-Agent': 'Mozilla/5.0'}
    search_url = (f'https://commons.wikimedia.org/w/api.php'
                  f'?action=query&list=search&srsearch={urllib.parse.quote(query)}+filetype:image'
                  f'&srnamespace=6&srlimit=3&format=json')
    try:
        req = urllib.request.Request(search_url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
        for item in data.get('query', {}).get('search', []):
            title = item['title']
            if not title.startswith('File:'):
                continue
            time.sleep(2)
            info_url = (f'https://commons.wikimedia.org/w/api.php'
                       f'?action=query&titles={urllib.parse.quote(title)}'
                       f'&prop=imageinfo&iiprop=url&format=json')
            req2 = urllib.request.Request(info_url, headers=headers)
            with urllib.request.urlopen(req2, timeout=10) as r2:
                data2 = json.loads(r2.read())
            for pid, p in data2.get('query', {}).get('pages', {}).items():
                if 'imageinfo' in p:
                    url = p['imageinfo'][0]['url']
                    time.sleep(2)
                    req3 = urllib.request.Request(url, headers=headers)
                    with urllib.request.urlopen(req3, timeout=30) as r3:
                        with open(output_path, 'wb') as f:
                            f.write(r3.read())
                    if os.path.getsize(output_path) > 5000:
                        return True
    except Exception as e:
        print(f'Fetch error: {e}')
    return False

# Queries recomendadas por tema
SEARCH_QUERIES = {
    'beringia': ['Beringia land bridge', 'Bering strait migration map'],
    'clovis': ['Clovis point projectile', 'Clovis culture artifacts'],
    'monte verde': ['Monte Verde archaeological site Chile'],
    'megatherium': ['Megatherium giant ground sloth', 'Megatherium skeleton'],
    'glyptodon': ['Glyptodon fossil', 'Glyptodon life restoration'],
    'migration': ['human migration Americas map', 'peopling of the Americas'],
}
```

## Bloom Objectives Slide

**Siempre en Slide 1 o portada. Visible, no escondido.**

```python
def add_bloom_objectives(slide, objectives, theme):
    """objectives = [(level_name, verb+description, color), ...]"""
    for i, (level, desc, color) in enumerate(objectives):
        y = 2.15 + i * 0.35
        rect(slide, 1.0, y, 0.04, 0.25, color)
        txt(slide, 1.2, y-0.02, 1.4, 0.25, level, 11, True, color)
        txt(slide, 2.7, y-0.02, 9.5, 0.25, desc, 11, theme['text'])
```
