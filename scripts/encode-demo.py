"""Encode screenshot sequences into README GIFs. Requires Pillow.

Frames come from record-demo.cjs (drag / import) and demo-integrations.cjs (integrations);
kinds without frames in the folder are skipped.
"""
from pathlib import Path
import sys
from PIL import Image
frames = Path(sys.argv[1])
out = Path(__file__).resolve().parent.parent / 'docs' / 'images'
FRAME_MS = {'drag': 40, 'import': 110, 'integrations': 120}
done = 0
for kind, ms in FRAME_MS.items():
    images = [Image.open(p).convert('RGB') for p in sorted(frames.glob(f'{kind}-*.png'))]
    if not images:
        continue
    durations = [ms] * len(images)
    durations[0] = 1000
    durations[-1] = 1800
    # Share a palette across every frame to prevent color flicker during movement.
    palette = images[0].quantize(colors=128)
    images = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in images]
    images[0].save(out / f'{kind}-demo.gif', save_all=True, append_images=images[1:], duration=durations, loop=0, optimize=True)
    print(f'{kind}: {len(images)} frames')
    done += 1
if not done:
    raise ValueError(f'No frames found in {frames}')
