from PIL import Image, ImageDraw
import os

def create_gradient(width, height, color1, color2):
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        r = int(color1[0] + (color2[0] - color1[0]) * y / height)
        g = int(color1[1] + (color2[1] - color1[1]) * y / height)
        b = int(color1[2] + (color2[2] - color1[2]) * y / height)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img

def draw_circle(draw, center, radius, fill):
    x, y = center
    draw.ellipse([x-radius, y-radius, x+radius, y+radius], fill=fill)

base = os.path.join(os.path.dirname(__file__), 'assets', 'images', 'onboarding', '')
os.makedirs(base, exist_ok=True)

w, h = 600, 600

# === ONBOARDING 1: Security (Blue gradient + Shield) ===
img1 = create_gradient(w, h, (30, 64, 175), (59, 130, 246))
draw1 = ImageDraw.Draw(img1)
for cx, cy, r in [(100,100,80), (500,80,60), (120,500,100), (520,480,70)]:
    draw_circle(draw1, (cx, cy), r, fill=(255,255,255))
draw1.polygon([(300,180), (380,220), (380,320), (300,420), (220,320), (220,220)], fill=(255,255,255))
draw1.polygon([(300,210), (355,240), (355,310), (300,390), (245,310), (245,240)], fill=(37, 99, 235))
draw1.line([(270,310), (290,340), (340,260)], fill=(255,255,255), width=12)
draw1.ellipse([480,420,520,460], fill=(255,255,255))
draw1.polygon([(480,480), (500,440), (520,480)], fill=(255,255,255))
img1.save(base + 'onboarding_1.png')

# === ONBOARDING 2: Family (Pink/Orange gradient + People) ===
img2 = create_gradient(w, h, (236, 72, 153), (249, 115, 22))
draw2 = ImageDraw.Draw(img2)
for cx, cy, r in [(80,120,70), (520,100,50), (100,520,90), (500,500,60)]:
    draw_circle(draw2, (cx, cy), r, fill=(255,255,255))
draw2.ellipse([200,200,260,260], fill=(255,255,255))
draw2.rounded_rectangle([210,270,250,380], radius=15, fill=(255,255,255))
draw2.ellipse([270,170,330,230], fill=(255,255,255))
draw2.rounded_rectangle([280,240,320,390], radius=15, fill=(255,255,255))
draw2.ellipse([340,200,400,260], fill=(255,255,255))
draw2.rounded_rectangle([350,270,390,380], radius=15, fill=(255,255,255))
hc = (300, 450)
for dx, dy, r in [(-15, -10, 18), (15, -10, 18)]:
    draw2.ellipse([hc[0]+dx-r, hc[1]+dy-r, hc[0]+dx+r, hc[1]+dy+r], fill=(255,255,255))
draw2.polygon([(hc[0]-30, hc[1]-5), (hc[0]+30, hc[1]-5), (hc[0], hc[1]+35)], fill=(255,255,255))
img2.save(base + 'onboarding_2.png')

# === ONBOARDING 3: Organization (Purple gradient + Calendar) ===
img3 = create_gradient(w, h, (139, 92, 246), (59, 130, 246))
draw3 = ImageDraw.Draw(img3)
for cx, cy, r in [(90,90,60), (510,110,50), (130,510,80), (490,490,65)]:
    draw_circle(draw3, (cx, cy), r, fill=(255,255,255))
draw3.rounded_rectangle([150,150,450,420], radius=24, fill=(255,255,255))
draw3.rounded_rectangle([150,150,450,220], radius=24, fill=(243, 244, 246))
for row in range(4):
    for col in range(5):
        if row == 2 and col == 3:
            draw3.ellipse([190+col*50-12, 250+row*40-12, 190+col*50+12, 250+row*40+12], fill=(139, 92, 246))
        else:
            draw3.ellipse([190+col*50-6, 250+row*40-6, 190+col*50+6, 250+row*40+6], fill=(209, 213, 219))
draw3.line([(360,310), (375,330), (405,290)], fill=(255,255,255), width=8)
draw3.rounded_rectangle([480,180,560,200], radius=8, fill=(255,255,255))
draw3.rounded_rectangle([480,230,540,250], radius=8, fill=(255,255,255))
draw3.rounded_rectangle([480,280,550,300], radius=8, fill=(255,255,255))
img3.save(base + 'onboarding_3.png')

print('Done!')
