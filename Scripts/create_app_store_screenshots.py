#!/usr/bin/env python3
"""Compose Vorb App Store screenshots from contextual art and native captures."""

import argparse

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

from app_store_screenshot_localizations import LOCALIZATIONS, LOCALE_ORDER


ROOT = Path(__file__).resolve().parent.parent
RAW_ROOT = ROOT / "Design" / "AppStoreScreenshots" / "Raw"
GENERATED = ROOT / "Design" / "AppStoreScreenshots" / "GeneratedReferences"
FINAL_ROOT = ROOT / "Design" / "AppStoreScreenshots" / "Final"
LOCALIZED_ROOT = ROOT / "Design" / "AppStoreScreenshots" / "Localized"
WIDTH, HEIGHT = 2880, 1800
ACTIVE_LOCALE = "en-US"
COPY = LOCALIZATIONS[ACTIVE_LOCALE]
RAW = RAW_ROOT
FINAL = FINAL_ROOT


def font(size: int, weight: str = "Regular") -> ImageFont.FreeTypeFont:
    if ACTIVE_LOCALE == "ja":
        weight_number = 6 if weight in {"Semibold", "Bold"} else 3
        path = f"/System/Library/Fonts/ヒラギノ角ゴシック W{weight_number}.ttc"
        return ImageFont.truetype(path, size)
    if ACTIVE_LOCALE == "ko":
        index = {"Regular": 0, "Medium": 2, "Semibold": 4, "Bold": 6}.get(weight, 0)
        return ImageFont.truetype(
            "/System/Library/Fonts/AppleSDGothicNeo.ttc",
            size,
            index=index,
        )
    if ACTIVE_LOCALE == "zh-Hans":
        index = 2 if weight in {"Semibold", "Bold"} else 0
        return ImageFont.truetype(
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
            size,
            index=index,
        )

    value = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
    value.set_variation_by_name(weight)
    return value


def fitted_font(
    text: str,
    initial_size: int,
    max_width: int,
    weight: str = "Medium",
    minimum_size: int = 32,
) -> ImageFont.FreeTypeFont:
    draw = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for size in range(initial_size, minimum_size - 1, -2):
        candidate = font(size, weight)
        if max(draw.textlength(line, font=candidate) for line in text.split("\n")) <= max_width:
            return candidate
    return font(minimum_size, weight)


def background(seed: int, glow_x: int, glow_y: int) -> Image.Image:
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:HEIGHT, 0:WIDTH]
    base = np.zeros((HEIGHT, WIDTH, 3), dtype=np.float32)
    top = np.array([14, 17, 28], dtype=np.float32)
    bottom = np.array([5, 7, 13], dtype=np.float32)
    vertical = (yy / HEIGHT)[..., None]
    base[:] = top * (1 - vertical) + bottom * vertical

    distance = ((xx - glow_x) / 1100) ** 2 + ((yy - glow_y) / 900) ** 2
    glow = np.exp(-distance * 2.25)[..., None]
    base += glow * np.array([42, 25, 86], dtype=np.float32)

    distance_two = ((xx - (WIDTH - glow_x / 3)) / 1450) ** 2 + (
        (yy - HEIGHT * 0.12) / 800
    ) ** 2
    blue = np.exp(-distance_two * 2.8)[..., None]
    base += blue * np.array([9, 25, 55], dtype=np.float32)

    noise = rng.normal(0, 0.75, (HEIGHT, WIDTH, 1))
    base += noise
    return Image.fromarray(np.uint8(np.clip(base, 0, 255)), "RGB").convert("RGBA")


def contextual_background(filename: str, left_darken: int = 210) -> Image.Image:
    source = Image.open(GENERATED / filename).convert("RGB")
    canvas = ImageOps.fit(
        source,
        (WIDTH, HEIGHT),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    ).convert("RGBA")

    xx = np.linspace(0, 1, WIDTH, dtype=np.float32)
    left_alpha = np.uint8(np.clip((1 - xx) ** 1.7 * left_darken, 0, 255))
    left_overlay = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    left_overlay[..., 3] = left_alpha[None, :]
    canvas.alpha_composite(Image.fromarray(left_overlay, "RGBA"))

    yy = np.linspace(0, 1, HEIGHT, dtype=np.float32)
    edge_alpha = np.uint8(np.clip(np.maximum(0, yy - 0.68) * 270, 0, 90))
    bottom_overlay = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    bottom_overlay[..., 3] = edge_alpha[:, None]
    canvas.alpha_composite(Image.fromarray(bottom_overlay, "RGBA"))
    return canvas


def add_brand(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((156, 104, 181, 129), fill=(152, 119, 255, 255))
    draw.ellipse((164, 112, 173, 121), fill=(235, 228, 255, 255))
    draw.text((202, 91), "VORB", font=font(43, "Semibold"), fill=(242, 241, 248))
    draw.text(
        (350, 103),
        COPY["brand"],
        font=font(24, "Medium"),
        fill=(158, 158, 176),
    )


def add_copy(
    canvas: Image.Image,
    headline: str,
    supporting: str,
    x: int = 170,
    y: int = 265,
    headline_size: int = 112,
    max_width: int = 1270,
) -> None:
    draw = ImageDraw.Draw(canvas)
    headline_font = font(headline_size, "Bold")
    supporting_font = font(42, "Regular")
    line_height = int(headline_size * 1.04)
    for line_number, line in enumerate(headline.split("\n")):
        draw.text(
            (x, y + line_number * line_height),
            line,
            font=headline_font,
            fill=(249, 248, 252),
        )
    support_y = y + len(headline.split("\n")) * line_height + 48
    # CJK marketing copy has no inter-word spaces, so wrap it by character.
    # Latin and Cyrillic copy keeps natural word boundaries.
    compact_script = ACTIVE_LOCALE in {"ja", "zh-Hans"}
    words = list(supporting) if compact_script else supporting.split()
    separator = "" if compact_script else " "
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current}{separator}{word}".strip()
        if draw.textlength(candidate, font=supporting_font) > max_width and current:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    for line_number, line in enumerate(lines):
        draw.text(
            (x, support_y + line_number * 56),
            line,
            font=supporting_font,
            fill=(177, 177, 195),
        )


def paste_with_shadow(
    canvas: Image.Image,
    source: Image.Image,
    position: tuple[int, int],
    target_width: int,
    shadow_radius: int = 55,
    shadow_offset: tuple[int, int] = (0, 28),
) -> None:
    ratio = target_width / source.width
    target_height = round(source.height * ratio)
    source = source.resize((target_width, target_height), Image.Resampling.LANCZOS)
    if source.mode != "RGBA":
        source = source.convert("RGBA")

    # Render the shadow on a padded surface. Blurring inside the source-sized
    # bounds clipped the soft edge and exposed a dark rectangular strip below
    # window captures.
    alpha = source.getchannel("A")
    padding = max(32, shadow_radius * 2)
    shadow_mask = Image.new(
        "L",
        (source.width + padding * 2, source.height + padding * 2),
        0,
    )
    shadow_mask.paste(alpha, (padding, padding))
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(shadow_radius))
    shadow_opacity = shadow_mask.point(lambda value: round(value * 0.58))
    dark = Image.new("RGBA", shadow_mask.size, (0, 0, 0, 0))
    dark.putalpha(shadow_opacity)
    canvas.alpha_composite(
        dark,
        (
            position[0] + shadow_offset[0] - padding,
            position[1] + shadow_offset[1] - padding,
        ),
    )
    canvas.alpha_composite(source, position)


def window_capture(path: Path, corner_radius: int = 48) -> Image.Image:
    """Remove the desktop pixels outside a captured macOS window."""
    source = Image.open(path).convert("RGBA")
    mask = Image.new("L", source.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (1, 1, source.width - 2, source.height - 2),
        radius=corner_radius,
        fill=255,
    )
    source.putalpha(mask)
    return source


def rounded_detail(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    detail = source.crop(box).convert("RGBA")
    mask = Image.new("L", detail.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, detail.width - 1, detail.height - 1),
        radius=30,
        fill=255,
    )
    detail.putalpha(mask)
    return detail


def pill(
    canvas: Image.Image,
    text: str,
    x: int,
    y: int,
    width: int | None = None,
    accent: bool = False,
) -> int:
    draw = ImageDraw.Draw(canvas)
    pill_font = font(28, "Semibold")
    text_width = round(draw.textlength(text, font=pill_font))
    width = width or text_width + 58
    fill = (77, 50, 143, 255) if accent else (31, 33, 47, 255)
    outline = (146, 116, 224, 255) if accent else (62, 64, 82, 255)
    draw.rounded_rectangle(
        (x, y, x + width, y + 62),
        radius=31,
        fill=fill,
        outline=outline,
        width=2,
    )
    draw.text(
        (x + (width - text_width) / 2, y + 13),
        text,
        font=pill_font,
        fill=(238, 234, 249),
    )
    return width


def transcript_card(canvas: Image.Image, x: int, y: int) -> None:
    draw = ImageDraw.Draw(canvas)
    width, height = 930, 235
    draw.rounded_rectangle(
        (x, y, x + width, y + height),
        radius=34,
        fill=(18, 20, 31, 255),
        outline=(93, 77, 139, 255),
        width=2,
    )
    draw.ellipse((x + 42, y + 42, x + 78, y + 78), fill=(133, 98, 235, 255))
    draw.text(
        (x + 98, y + 40),
        "SPEECH → CLEAN TEXT",
        font=font(27, "Semibold"),
        fill=(180, 157, 247),
    )
    draw.text(
        (x + 42, y + 108),
        "“Turn this idea into a clear note\nbefore I forget it.”",
        font=font(37, "Medium"),
        fill=(239, 237, 246),
        spacing=10,
    )


def save(canvas: Image.Image, name: str) -> None:
    FINAL.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(FINAL / name, "PNG", compress_level=3)


def screenshot_one() -> None:
    screen = COPY["screens"][0]
    canvas = contextual_background("01-dictating-at-desk.png", left_darken=235)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=270,
        headline_size=screen.get("headline_size", 112),
        max_width=1120,
    )
    first, second, third = screen["pills"]
    x = 175
    x += pill(canvas, first, x, 1260, accent=True) + 24
    x += pill(canvas, second, x, 1260) + 24
    pill(canvas, third, x, 1260)
    save(canvas, "01-capture-thoughts.png")


def screenshot_two() -> None:
    screen = COPY["screens"][1]
    canvas = contextual_background("02-waveform-to-text.png", left_darken=155)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=245,
        headline_size=screen.get("headline_size", 112),
        max_width=1050,
    )
    first, second, third = screen["pills"]
    x = 175
    x += pill(canvas, first, x, 1310, accent=True) + 20
    x += pill(canvas, second, x, 1310, width=82) + 20
    pill(canvas, third, x, 1310)

    draw = ImageDraw.Draw(canvas)
    draw.text(
        (1840, 520),
        screen["transcript_label"],
        font=font(27, "Semibold"),
        fill=(168, 144, 240),
    )
    transcript_font = fitted_font(screen["transcript"], 52, 820, "Medium", 38)
    draw.multiline_text(
        (1840, 625),
        screen["transcript"],
        font=transcript_font,
        fill=(245, 243, 250),
        spacing=20,
    )
    ready_width = min(
        830,
        max(
            450,
            round(draw.textlength(screen["ready"], font=font(28, "Semibold"))) + 80,
        ),
    )
    pill(canvas, screen["ready"], 1840, 875, width=ready_width, accent=True)
    save(canvas, "02-speech-to-clean-text.png")


def screenshot_three() -> None:
    screen = COPY["screens"][2]
    canvas = contextual_background("03-dictate-anywhere.png", left_darken=225)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=245,
        headline_size=screen.get("headline_size", 112),
        max_width=1050,
    )
    x = 175
    for index, label in enumerate(screen["pills"]):
        x += pill(canvas, label, x, 1290, accent=index == 0) + 18
    save(canvas, "03-dictate-anywhere.png")


def screenshot_four() -> None:
    screen = COPY["screens"][3]
    canvas = background(4, 2320, 900)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=315,
        headline_size=screen.get("headline_size", 112),
    )
    first, second, third = screen["pills"]
    x = 175
    x += pill(canvas, first, x, 1060, accent=True) + 20
    x += pill(canvas, second, x, 1060) + 20
    pill(canvas, third, x, 1060)

    settings = window_capture(RAW / "settings-local.png")
    paste_with_shadow(canvas, settings, (1660, 240), 1050)
    save(canvas, "04-private-whisper.png")


def screenshot_five() -> None:
    screen = COPY["screens"][4]
    canvas = background(5, 2290, 600)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=315,
        headline_size=screen.get("headline_size", 112),
    )
    x = 175
    for index, label in enumerate(screen["pills"][:3]):
        x += pill(canvas, label, x, 1050, accent=index == 0) + 18
    pill(canvas, screen["pills"][3], 175, 1135)

    settings = window_capture(RAW / "settings-provider.png")
    paste_with_shadow(canvas, settings, (1660, 240), 1050)
    save(canvas, "05-bring-your-provider.png")


def screenshot_six() -> None:
    screen = COPY["screens"][5]
    canvas = background(6, 2050, 1120)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=250,
        headline_size=screen.get("headline_size", 112),
    )
    x = 175
    for label in screen["pills"]:
        x += pill(canvas, label, x, 1030, accent=label == "SMALL") + 16

    settings = Image.open(RAW / "settings-local.png").convert("RGBA")
    detail = rounded_detail(settings, (50, 700, 990, 1135))
    paste_with_shadow(canvas, detail, (1210, 710), 1500, shadow_radius=45)
    save(canvas, "06-model-language.png")


def screenshot_seven() -> None:
    screen = COPY["screens"][6]
    canvas = background(7, 1800, 1200)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=220,
        headline_size=screen.get("headline_size", 112),
        max_width=700,
    )
    x = 178
    for index, label in enumerate(screen["pills"]):
        x += pill(canvas, label, x, 960, accent=index == 0) + 18

    history = window_capture(RAW / "history.png", corner_radius=40)
    paste_with_shadow(canvas, history, (940, 570), 1780)
    save(canvas, "07-history.png")


def screenshot_eight() -> None:
    screen = COPY["screens"][7]
    canvas = background(8, 2250, 980)
    add_brand(canvas)
    add_copy(
        canvas,
        screen["headline"],
        screen["supporting"],
        y=285,
        headline_size=screen.get("headline_size", 112),
    )
    first, second, third = screen["pills"]
    x = 175
    x += pill(canvas, first, x, 1060, accent=True) + 20
    x += pill(canvas, second, x, 1060) + 20
    pill(canvas, third, x, 1060)

    settings = window_capture(RAW / "settings-shortcut.png")
    paste_with_shadow(canvas, settings, (1660, 240), 1050)
    save(canvas, "08-shortcut.png")


def contact_sheet() -> None:
    filenames = [
        "01-capture-thoughts.png",
        "02-speech-to-clean-text.png",
        "03-dictate-anywhere.png",
        "04-private-whisper.png",
        "05-bring-your-provider.png",
        "06-model-language.png",
        "07-history.png",
        "08-shortcut.png",
    ]
    files = [FINAL / filename for filename in filenames]
    thumb_size = (720, 450)
    sheet = Image.new("RGB", (1440, 1800), (8, 10, 16))
    for index, path in enumerate(files):
        thumb = Image.open(path).convert("RGB")
        thumb.thumbnail(thumb_size, Image.Resampling.LANCZOS)
        x = (index % 2) * 720
        y = (index // 2) * 450
        sheet.paste(thumb, (x, y))
    # PNG avoids relying on an optional JPEG codec in minimal release
    # environments and keeps small UI text crisp during review.
    sheet.save(FINAL / "contact-sheet.png", "PNG", compress_level=3)


def generate_locale(locale: str, output: Path, raw: Path) -> None:
    global ACTIVE_LOCALE, COPY, RAW, FINAL
    ACTIVE_LOCALE = locale
    COPY = LOCALIZATIONS[locale]
    RAW = raw
    FINAL = output

    required = [
        RAW / "settings-local.png",
        RAW / "settings-provider.png",
        RAW / "history.png",
        RAW / "settings-shortcut.png",
        GENERATED / "01-dictating-at-desk.png",
        GENERATED / "02-waveform-to-text.png",
        GENERATED / "03-dictate-anywhere.png",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("Missing raw captures:\n" + "\n".join(missing))

    screenshot_one()
    screenshot_two()
    screenshot_three()
    screenshot_four()
    screenshot_five()
    screenshot_six()
    screenshot_seven()
    screenshot_eight()
    contact_sheet()
    print(f"Generated {locale}: {FINAL}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--locale", choices=LOCALE_ORDER)
    parser.add_argument("--all-locales", action="store_true")
    arguments = parser.parse_args()

    if arguments.all_locales:
        for locale in LOCALE_ORDER:
            raw = RAW_ROOT if locale == "en-US" else RAW_ROOT / locale
            generate_locale(locale, LOCALIZED_ROOT / locale, raw)
        return

    if arguments.locale:
        raw = RAW_ROOT if arguments.locale == "en-US" else RAW_ROOT / arguments.locale
        generate_locale(arguments.locale, LOCALIZED_ROOT / arguments.locale, raw)
        return

    generate_locale("en-US", FINAL_ROOT, RAW_ROOT)


if __name__ == "__main__":
    main()
