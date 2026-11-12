#!/usr/bin/env python3
"""Render exported Lua widget geometry as HTML for layout inspection.

This approximates WoW fonts/templates; it is not a game screenshot. No production
runtime depends on this script. Generate JSON with tools/preview_options.lua.
"""
import concurrent.futures
import html
import json
from pathlib import Path
import sys
import urllib.request

source = Path(sys.argv[1]).resolve()
data = json.loads(source.read_text())
widgets = {int(key): value for key, value in data['widgets'].items()}
root = int(data['root'])
icons = source.parent / 'icons'
icons.mkdir(exist_ok=True)
names = {value['texture'].split('\\')[-1].lower() for value in widgets.values()
         if isinstance(value.get('texture'), str) and '\\Icons\\' in value['texture']}
def download(name):
    path = icons / (name + '.jpg')
    if not path.exists():
        try:
            with urllib.request.urlopen('https://wow.zamimg.com/images/wow/icons/large/' + name + '.jpg', timeout=10) as response:
                path.write_bytes(response.read())
        except Exception:
            pass
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    list(pool.map(download, names))

def chain(widget):
    result = []
    while widget:
        result.append(widget)
        widget = widgets.get(widget.get('parent'))
    return result

def anchor(point, width, height):
    return (0 if 'LEFT' in point else width if 'RIGHT' in point else width/2,
            0 if 'TOP' in point else height if 'BOTTOM' in point else height/2)
rects = {}
def rect(widget):
    key = widget['id']
    if key == widgets[root].get('parent'):
        return (0, 0, 1280, 900)
    if key in rects:
        return rects[key]
    template = widget.get('template', '')
    width = widget.get('width', 32 if template else 0)
    height = widget.get('height', 18 if widget.get('kind') == 'Text' else 32 if template else 0)
    parent = widgets.get(widget.get('parent'))
    base = (0, 0, 1280, 900) if parent is None else rect(parent)
    point = list(widget.get('point', {}).values())
    # Lua JSON object keys are not ordered; numeric point components must be sorted.
    point = [value for _, value in sorted(widget.get('point', {}).items(), key=lambda x: int(x[0]))]
    if not point:
        result = base[0], base[1], width, height
    else:
        own = point[0]
        if len(point) > 1 and isinstance(point[1], dict):
            base = rect(widgets[point[1]['relative']])
            relative, dx, dy = point[2], point[3] if len(point)>3 else 0, point[4] if len(point)>4 else 0
        else:
            relative = own
            dx, dy = point[1] if len(point)>1 else 0, point[2] if len(point)>2 else 0
        ax, ay = anchor(own, width, height)
        bx, by = anchor(relative, base[2], base[3])
        result = base[0] + bx + dx - ax, base[1] + by - dy - ay, width, height
    rects[key] = result
    return result

def color(value):
    parts = [value.get(str(i), 1) for i in range(1, 5)]
    return f'rgba({int(parts[0]*255)},{int(parts[1]*255)},{int(parts[2]*255)},{parts[3]})'

parts = ['<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#0c1110;color:#e2e2dc;font-family:Georgia,serif}*{box-sizing:border-box}.w{position:absolute;overflow:hidden}.button{background:linear-gradient(#2a3329,#131b14);border:1px solid #566444;border-radius:3px;text-align:center;line-height:24px;color:#e4cb7b;text-shadow:0 1px #000}.dropdown{background:#101710;border:1px solid #4d5545;border-radius:4px;padding:5px 20px;font-size:12px}.label{white-space:normal;line-height:1.2}.check{border:1px solid #737b61;background:#172017;color:#daca80;line-height:24px;text-align:center}.slider{height:6px!important;border:1px solid #697151;background:#111611;margin-top:5px;overflow:visible}.slider:after{content:"";position:absolute;width:12px;height:17px;background:linear-gradient(90deg,#535d3d,#c1cc96,#4f5b3d);left:40%;top:-6px}</style>']
for widget in widgets.values():
    ancestors = chain(widget)
    if not any(item['id'] == root for item in ancestors) or any(item.get('shown') is False for item in ancestors):
        continue
    x,y,w,h = rect(widget)
    kind, template = widget.get('kind'), widget.get('template', '')
    css = f'left:{x}px;top:{y}px;width:{w}px;height:{h}px;'
    if any(item.get('strata') == 'FULLSCREEN_DIALOG' for item in ancestors): css += 'z-index:100;'
    if widget.get('alpha') is not None: css += f"opacity:{widget['alpha']};"
    klass = 'w'
    content = ''
    if widget.get('background'):
        css += 'background:' + color(widget['background']) + ';border:1px solid #394d35;border-radius:5px;'
    if kind == 'Text':
        klass += ' label'
        font = widget.get('font', '')
        size = 18 if 'Large' in font else 11 if 'Small' in font else 13
        css += f'font-size:{size}px;'
        if 'Normal' in font: css += 'color:#d5c48a;'
        content = html.escape(widget.get('text', ''))
    elif widget.get('text') is not None:
        content = html.escape(widget['text'])
    if template == 'UIPanelButtonTemplate': klass += ' button'; css += 'font-size:12px;'
    elif template == 'UIDropDownMenuTemplate': klass += ' dropdown'; content += ' ▾'
    elif template == 'InterfaceOptionsCheckButtonTemplate': klass += ' check'; content = '✓' if widget.get('checked') else ''
    elif template == 'OptionsSliderTemplate': klass += ' slider'
    elif template == 'UIPanelCloseButton': klass += ' button'; content = '×'
    texture = widget.get('texture')
    if isinstance(texture, str):
        if texture.endswith('logo-header.tga'):
            url = (Path(__file__).resolve().parents[1] / 'assets/logo-header.png').as_uri()
        elif '\\Icons\\' in texture:
            url = (icons / (texture.split('\\')[-1].lower()+'.jpg')).as_uri()
        else:
            continue
        content = f'<img style="width:100%;height:100%;object-fit:contain" src="{url}">'
    if kind == 'Texture' and not content: continue
    if kind == 'Button' and not content and not template: continue
    parts.append(f'<div class="{klass}" style="{css}">{content}</div>')
parts.append('<div style="position:absolute;left:80px;top:840px;font:12px sans-serif;color:#8c9c8c">Layout preview from Lua widgets · native WoW fonts and controls may differ</div>')
source.with_suffix('.html').write_text('\n'.join(parts))
print(source.with_suffix('.html'))
