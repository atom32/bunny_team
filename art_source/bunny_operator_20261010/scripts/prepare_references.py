#!/usr/bin/env python3
"""Deterministically crop the approved sheet. No generative editing/mirroring."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
# Source 1536x1024. Shared vertical range preserves scale/ground across views.
# Holster in the front image is on anatomical right: visible profile is RIGHT.
BOXES = {'front': [35, 0, 400, 1024], 'right': [510, 0, 800, 1024],
         'back': [835, 0, 1205, 1024]}

def main():
    source = ROOT / 'reference/design_sheet.png'
    image = Image.open(source).convert('RGB')
    if image.size != (1536, 1024):
        raise SystemExit('Unexpected sheet resolution; crop coordinates require review.')
    manifest = {'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                'source_size': image.size, 'operation': 'crop + horizontal padding only',
                'missing_view': 'left; deliberately omitted, not mirrored', 'views': {}}
    previews = []
    for view, box in BOXES.items():
        crop = image.crop(tuple(box))
        canvas = Image.new('RGB', (1024, 1024), (215, 215, 215))
        canvas.paste(crop, ((1024-crop.width)//2, 0))
        path = ROOT / ('reference/'+view+'.png')
        canvas.save(path)
        manifest['views'][view] = {'crop_box':box,'size':canvas.size,
                                  'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
        previews.append(crop)
    contact = Image.new('RGB',(sum(im.width for im in previews),1024))
    x = 0
    for im in previews:
        contact.paste(im,(x,0)); x += im.width
    contact.save(ROOT/'reference/crop_review.png')
    (ROOT/'reference/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Prepared front/right/back references from the original approved sheet.')

if __name__ == '__main__': main()
