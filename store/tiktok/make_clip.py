# -*- coding: utf-8 -*-
"""One TikTok clip from one screen recording: the hook, the moment, the name.

    python make_clip.py bored

Every clip here is the same shape, because the thing being sold is the same
every time: a learner says something wrong, and Amy's card lands. So a clip
is three parts and nothing else --

  hook     two seconds of the mistake, as text, on the app's own dark ground.
           This is frame one, which is the thumbnail and the only frame a
           muted feed guarantees anyone sees.
  moment   the recording, cut to open with the mic already held and to run
           a few seconds past the card. When the card lands, a Turkish gloss
           of the two words appears in the strip above the mic.
  name     three seconds: the icon, the name, the same line the bio carries.

The recordings come from `adb shell screenrecord`, which captures no audio,
and that is fine for this shape: the app's text is the content, and the sound
goes on in TikTok's own editor, where a trending track does more for reach
than Amy's voice would. What the recording does have is variable frame rate
with sparse keyframes, so the cut seeks on the output side (-ss after -i) and
writes a constant-rate intermediate, same as make_video.py in ../video.

The phone is 1080x2340 and the feed is 1080x1920. The status bar and the
navigation bar are cropped, the rest is scaled to height and set on the app's
background colour; the side margins that leaves are 44px of the same dark as
the chat, so they read as the app's own edge rather than as bars.

Text is set in PIL, not drawtext: drawtext needs fontconfig, which this
machine does not have, and PIL can centre and letter-space anyway.
"""
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, 'raw')
OUT = os.path.join(HERE, 'clips')
BUILD = os.path.join(HERE, 'build')
ICON = os.path.join(HERE, '..', '..', 'flutter_vocabmaster', 'assets',
                    'images', 'app_icon_composed.png')

BLACK_F = 'C:/Windows/Fonts/seguibl.ttf'
SEMI_F = 'C:/Windows/Fonts/seguisb.ttf'

W, H = 1080, 1920
FPS = 30

# Sampled off a frame of the recording: the chat ground, the user's bubble.
GROUND = '#12101e'
BUBBLE = (110, 92, 246)
WHITE = (255, 255, 255)
DIM = (196, 192, 220)
WRONG = (242, 168, 168)
RIGHT = (158, 230, 180)

# Phone frame: the status bar ends at y=90, the navigation bar starts at 2200.
CROP_TOP, CROP_BOTTOM = 90, 2200

CLIPS = {
    'bored': dict(
        src='klio_bored.mp4',
        # Output-side seconds in the raw file. Mic pressed at 36.75, released
        # at 39.6, the card and Amy's reply land together at 40.5. The cut
        # opens mid-hold: three seconds of a held button is dead air in a
        # feed, and "Göndermek için bırak" under the mic says what is going on.
        start=38.2, end=46.4, lands=40.5,
        hook=('Bunu sen de diyorsun:', 'I am boring'),
        gloss=(('boring', 'sıkıcı'), ('bored', 'sıkılmış')),
    ),
    'light': dict(
        src='klio_light.mp4',
        # Released at 12.4, the card lands at 14.0. Same offsets as 'bored':
        # the cut opens 2.3s before the card. Measured with -ss AFTER -i; the
        # contact sheet made with an input seek read every moment 1.5s early.
        start=11.7, end=19.9, lands=14.0,
        hook=('Bunu sen de diyorsun:', 'open the light'),
        gloss=(('open', 'açmak (kapı, kutu)'), ('turn on', 'açmak (ışık, TV)')),
    ),
}


def font(path, size):
    return ImageFont.truetype(path, size)


def centred(d, y, text, f, fill):
    d.text((W // 2, y), text, font=f, fill=fill, anchor='mt')


def hook_card(path, line1, line2):
    im = Image.new('RGB', (W, H), GROUND)
    d = ImageDraw.Draw(im)
    centred(d, 690, line1, font(SEMI_F, 60), DIM)
    # The mistake sits in a bubble like the one it will appear in.
    f = font(BLACK_F, 118)
    tw = d.textlength(line2, font=f)
    x0, x1 = W // 2 - tw // 2 - 56, W // 2 + tw // 2 + 56
    d.rounded_rectangle((x0, 800, x1, 990), radius=44, fill=BUBBLE)
    centred(d, 812, line2, f, WHITE)
    im.save(path)


def gloss_overlay(path, pairs):
    """Transparent full-frame layer; two lines at the top of the mic panel.

    Once the card and the reply have scrolled into place, Amy's bubble runs
    down to y=1224 and the mic panel begins at 1280, so the gap between them
    is too thin for type. The panel's own top, above the button at 1400, is
    the one empty strip on the settled frame.
    """
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = font(SEMI_F, 40)
    y = 1292
    for (word, meaning), colour in zip(pairs, (WRONG, RIGHT)):
        centred(d, y, u'%s  \u2192  %s' % (word, meaning), f, colour)
        y += 52
    im.save(path)


def end_card(path):
    im = Image.new('RGB', (W, H), GROUND)
    icon = Image.open(ICON).convert('RGBA').resize((260, 260), Image.LANCZOS)
    im.paste(icon, (W // 2 - 130, 640), icon)
    d = ImageDraw.Draw(im)
    centred(d, 940, 'KlioAI', font(BLACK_F, 110), WHITE)
    centred(d, 1090, "Play Store'da ara: KlioAI", font(SEMI_F, 52), DIM)
    im.save(path)


def run(args):
    print(' '.join(a if ' ' not in a else '"%s"' % a for a in args))
    subprocess.check_call(args)


def build(name):
    c = CLIPS[name]
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)
    hook = os.path.join(BUILD, name + '_hook.png')
    gloss = os.path.join(BUILD, name + '_gloss.png')
    end = os.path.join(BUILD, name + '_end.png')
    seg = os.path.join(BUILD, name + '_seg.mp4')
    out = os.path.join(OUT, 'klio_%s.mp4' % name)

    hook_card(hook, *c['hook'])
    gloss_overlay(gloss, c['gloss'])
    end_card(end)

    crop_h = CROP_BOTTOM - CROP_TOP
    run(['ffmpeg', '-v', 'error', '-y',
         '-i', os.path.join(RAW, c['src']),
         '-ss', str(c['start']), '-t', str(c['end'] - c['start']),
         '-vf', ('crop=1080:%d:0:%d,scale=-2:%d,'
                 'pad=%d:%d:(ow-iw)/2:0:color=%s,fps=%d,format=yuv420p'
                 % (crop_h, CROP_TOP, H, W, H, GROUND, FPS)),
         '-c:v', 'libx264', '-crf', '16', '-preset', 'slow', seg])

    # The gloss fades in half a second after the card, once the list has
    # finished scrolling to it.
    at = c['lands'] - c['start'] + 0.5
    run(['ffmpeg', '-v', 'error', '-y',
         '-loop', '1', '-t', '2', '-i', hook,
         '-i', seg,
         '-loop', '1', '-t', '3', '-i', end,
         '-i', gloss,
         '-filter_complex',
         ('[0]fps=%d,format=yuv420p[a];'
          '[1][3]overlay=0:0:enable=gte(t\\,%.2f)[m];'
          '[m]fps=%d,format=yuv420p[b];'
          '[2]fps=%d,format=yuv420p[c];'
          '[a][b][c]concat=n=3:v=1:a=0[v]' % (FPS, at, FPS, FPS)),
         '-map', '[v]', '-c:v', 'libx264', '-crf', '16', '-preset', 'slow',
         '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out])
    print('wrote', out)


if __name__ == '__main__':
    build(sys.argv[1] if len(sys.argv) > 1 else 'bored')
