import math
from PIL import Image, ImageDraw, ImageFont

def create_wallpaper(output_path="branding/wallpaper/wallpaper.png", width=1920, height=1080):
    img = Image.new("RGBA", (width, height), (15, 20, 30, 255))
    draw = ImageDraw.Draw(img)

    # Subtle radial gradient from center
    cx, cy = width // 2, height // 2
    max_radius = int(math.hypot(cx, cy))
    
    # Draw background gradient bands
    for r in range(max_radius, 0, -4):
        ratio = r / max_radius
        # Interpolate between deep dark (#0c0e14) to dark slate blue (#1b2438)
        red = int(12 + (27 - 12) * (1 - ratio))
        green = int(14 + (36 - 14) * (1 - ratio))
        blue = int(20 + (56 - 20) * (1 - ratio))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(red, green, blue, 255))

    # Draw geometric circuit / modern constellation lines in background
    accent_color = (60, 110, 180, 40)
    for i in range(-5, 6):
        x1 = cx + i * 160
        y1 = 0
        x2 = cx + i * 220
        y2 = height
        draw.line([x1, y1, x2, y2], fill=accent_color, width=1)
    for j in range(-4, 5):
        y = cy + j * 120
        draw.line([0, y, width, y], fill=accent_color, width=1)

    # Draw central modern Emblem (Hexagonal shield with K glyph)
    emblem_y = cy - 60
    r_hex = 80
    hex_points = []
    for deg in range(30, 390, 60):
        rad = math.radians(deg)
        hex_points.append((cx + r_hex * math.cos(rad), emblem_y + r_hex * math.sin(rad)))
    
    # Outer glow & fill
    draw.polygon(hex_points, fill=(24, 34, 54, 230), outline=(56, 189, 248, 255), width=3)
    
    # Inner K symbol
    # Vertical spine
    draw.line([cx - 24, emblem_y - 45, cx - 24, emblem_y + 45], fill=(56, 189, 248, 255), width=8)
    # Upper diagonal
    draw.line([cx - 20, emblem_y, cx + 24, emblem_y - 45], fill=(96, 165, 250, 255), width=8)
    # Lower diagonal
    draw.line([cx - 20, emblem_y, cx + 24, emblem_y + 45], fill=(96, 165, 250, 255), width=8)

    # Load system font or default
    try:
        font_title = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 54)
        font_sub = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 20)
    except Exception:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    title_text = "K A V Y A   O S"
    sub_text = "A Minimal Debian-Based Linux Distribution"

    # Centered title
    bbox_t = draw.textbbox((0, 0), title_text, font=font_title)
    w_t = bbox_t[2] - bbox_t[0]
    draw.text((cx - w_t // 2, emblem_y + 110), title_text, font=font_title, fill=(240, 246, 252, 255))

    # Centered subtitle
    bbox_s = draw.textbbox((0, 0), sub_text, font=font_sub)
    w_s = bbox_s[2] - bbox_s[0]
    draw.text((cx - w_s // 2, emblem_y + 180), sub_text, font=font_sub, fill=(148, 163, 184, 255))

    img.convert("RGB").save(output_path, "PNG", optimize=True)
    print(f"Wallpaper saved: {output_path}")

def create_grub_splash(output_path="branding/grub/splash.png", width=640, height=480):
    img = Image.new("RGB", (width, height), (16, 22, 34))
    draw = ImageDraw.Draw(img)

    # Gradient top to bottom
    for y in range(height):
        ratio = y / height
        r = int(16 + (28 - 16) * ratio)
        g = int(22 + (38 - 22) * ratio)
        b = int(34 + (54 - 34) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # Border header
    draw.rectangle([20, 20, width - 20, 75], outline=(56, 189, 248), width=1)
    
    try:
        font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 24)
        subfont = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 13)
    except Exception:
        font = ImageFont.load_default()
        subfont = ImageFont.load_default()

    draw.text((35, 28), "KAVYA OS", font=font, fill=(240, 246, 252))
    draw.text((35, 54), "Minimal Debian GNU/Linux 12 (Bookworm)", font=subfont, fill=(148, 163, 184))

    img.save(output_path, "PNG", optimize=True)
    print(f"GRUB splash saved: {output_path}")

if __name__ == "__main__":
    create_wallpaper()
    create_grub_splash()
