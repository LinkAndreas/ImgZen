"""Build Icon Composer .icon bundles from the ImgZen icon SVGs, one layer per SVG element.

Each element in the SVGs is preceded by a <!-- name --> comment; that name becomes the layer.
Layers keep the SVGs' paint order. They are grouped (Icon Composer applies glass per group)
into Background, Mountains (behind the sun), Sun and Mountains (in front of the sun).
Layers only in the dark SVG (the glows) are hidden in the light appearance.

Also writes the vector IconPreview-<Name> images the supporter icon picker and the in-app logo
show, and each icon's palette (SupporterIcon+Palette.swift): the accent color the app's controls
take, and the colors of its background wash.
Run from anywhere after changing the SVGs: python3 AppIcon/make_icons.py
"""
import json, os, re, shutil

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(repo, "AppIcon")
out = os.path.join(repo, "ImgZen/Resources")
icons_out = os.path.join(out, "AppIcons")

GROUPS = [  # bottom to top
    ("Background", {"kind": "none", "opacity": 0.5}, False),
    ("Back Mountains", {"kind": "neutral", "opacity": 0.5}, True),
    ("Sun", {"kind": "layer-color", "opacity": 0.5}, True),
    ("Front Mountains", {"kind": "neutral", "opacity": 0.5}, True),
]
BACKGROUND = {"background", "sun-glow", "horizon-haze", "left-haze", "top-shade", "sun-glow-2"}

def group_of(name, seen_sun):
    if name in BACKGROUND:
        return "Background"
    if name == "S":
        return "Sun"
    return "Front Mountains" if seen_sun else "Back Mountains"

def file_name(name):
    return name.replace("+", "_") + ".svg"

def elements(svg_path):
    """[(layer name, standalone SVG)] in paint order."""
    text = open(svg_path).read()
    svg_tag = re.match(r"\s*(<svg[^>]*>)", text).group(1)
    defs = text.split("<defs>", 1)[1].split("</defs>", 1)[0]
    gradients = {m.group(2): m.group(0)
                 for m in re.finditer(r'<(linearGradient|radialGradient) id="([^"]+)".*?</\1>', defs, re.S)}
    body = text.split("</defs>", 1)[1]
    result = []
    for name, element in re.findall(r"<!-- (.+?) -->\s*(<(?:rect|path|circle)[^>]*/>)", body, re.S):
        used = re.findall(r"url\(#([^)]+)\)", element)
        layer_defs = "".join(gradients[g] + "\n" for g in used)
        result.append((name, f"{svg_tag}\n<defs>\n{layer_defs}</defs>\n{element}\n</svg>\n"))
    return result

def make(name, light, dark):
    bundle = os.path.join(icons_out, f"{name}.icon")
    shutil.rmtree(bundle, ignore_errors=True)
    assets = os.path.join(bundle, "Assets")
    os.makedirs(assets)

    light_layers = elements(light)
    dark_layers = elements(dark)
    light_names = [n for n, _ in light_layers]
    dark_names = [n for n, _ in dark_layers]
    # Dark has every light layer plus the glows, in the same relative order.
    assert [n for n in dark_names if n in light_names] == light_names, name

    for layer, svg in light_layers:
        open(os.path.join(assets, file_name(layer)), "w").write(svg)
    for layer, svg in dark_layers:
        stem = file_name(layer)[:-4]
        open(os.path.join(assets, f"{stem}-dark.svg"), "w").write(svg)

    groups = {g: [] for g, _, _ in GROUPS}
    seen_sun = False
    for layer in dark_names:
        seen_sun |= layer == "S"
        stem = file_name(layer)[:-4]
        entry = {
            "image-name-specializations": [
                {"value": f"{stem}.svg" if layer in light_names else f"{stem}-dark.svg"},
                {"appearance": "dark", "value": f"{stem}-dark.svg"},
            ],
            "name": layer,
        }
        if layer not in light_names:
            entry["hidden-specializations"] = [{"value": True}, {"appearance": "dark", "value": False}]
        groups[group_of(layer, seen_sun)].append(entry)

    icon = {
        "groups": [
            {
                "layers": list(reversed(groups[g])),  # Icon Composer lists the top layer first
                "name": g,
                "shadow": shadow,
                "specular": specular,
                "translucency": {"enabled": False, "value": 0.5},
            }
            for g, shadow, specular in reversed(GROUPS)
        ],
        "supported-platforms": {"squares": "shared"},
    }
    with open(os.path.join(bundle, "icon.json"), "w") as f:
        json.dump(icon, f, indent=2)
        f.write("\n")

def preview(name, light, dark):
    imageset = os.path.join(out, "Assets.xcassets", f"IconPreview-{name}.imageset")
    shutil.rmtree(imageset, ignore_errors=True)
    os.makedirs(imageset)
    shutil.copy(light, os.path.join(imageset, "preview.svg"))
    shutil.copy(dark, os.path.join(imageset, "preview_dark.svg"))
    contents = {
        "images": [
            {"filename": "preview.svg", "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "filename": "preview_dark.svg", "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True},
    }
    with open(os.path.join(imageset, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")

# The background's wash: the mountains' color at the top, fading through the sun's color.
# The accent is the light icon's mountain color, which reads well on light and dark backgrounds.
# Stronger in dark mode, where the icon's colors are deeper. (top opacity, middle opacity)
WASH_OPACITY = {"light": (0.16, 0.10), "dark": (0.30, 0.14)}
WASH_LOCATIONS = (0.0, 0.35, 0.7)

def stop_color(svg_path, gradient_id):
    """The middle stop of one of the SVG's gradients: g2 is the back mountain, g4 the sun."""
    text = open(svg_path).read()
    gradient = re.search(r'id="%s".*?</(?:linear|radial)Gradient>' % gradient_id, text, re.S).group(0)
    colors = re.findall(r'stop-color="#([0-9a-fA-F]{6})"', gradient)
    return colors[len(colors) // 2].lower()

def palette(light, dark):
    return {mode: (stop_color(path, "g2"), stop_color(path, "g4"))
            for mode, path in (("light", light), ("dark", dark))}

def swift_color(hex_color, opacity):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    return f"UIColor(red: {r / 255:.3f}, green: {g / 255:.3f}, blue: {b / 255:.3f}, alpha: {opacity})"

def write_palettes(palettes):
    """SupporterIcon+Palette.swift: each icon's wash colors, dynamic for light and dark mode."""
    cases = []
    for case, colors in palettes:
        (light_mountain, light_sun), (dark_mountain, dark_sun) = colors["light"], colors["dark"]
        (light_top, light_middle), (dark_top, dark_middle) = WASH_OPACITY["light"], WASH_OPACITY["dark"]
        cases.append(
            f"        case .{case}:\n"
            f"            Palette(\n"
            f"                accent: Color({swift_color(light_mountain, 1)}),\n"
            f"                mountain: .dynamic(light: {swift_color(light_mountain, light_top)}, "
            f"dark: {swift_color(dark_mountain, dark_top)}),\n"
            f"                sun: .dynamic(light: {swift_color(light_sun, light_middle)}, "
            f"dark: {swift_color(dark_sun, dark_middle)})\n"
            f"            )"
        )
    locations = ", ".join(str(l) for l in WASH_LOCATIONS)
    swift = f"""// Generated by AppIcon/make_icons.py from the icon SVGs; run it again instead of editing this file.

import SwiftUI
import UIKit

extension SupporterIcon {{
    /// An icon's colors, taken from its artwork: the accent the app's controls take, and the background
    /// wash's back mountain and sun, already at the wash's opacity.
    struct Palette {{
        let accent: Color
        let mountain: Color
        let sun: Color

        /// Where the wash's colors sit, from the top: the mountain, the sun, and where it has faded out.
        static let locations: [CGFloat] = [{locations}]
    }}

    var palette: Palette {{
        switch self {{
{chr(10).join(cases)}
        }}
    }}
}}

private extension Color {{
    static func dynamic(light: UIColor, dark: UIColor) -> Color {{
        Color(UIColor {{ traits in traits.userInterfaceStyle == .dark ? dark : light }})
    }}
}}
"""
    with open(os.path.join(repo, "ImgZen/Presentation/SupporterIcon+Palette.swift"), "w") as f:
        f.write(swift)

classic_light, classic_dark = f"{src}/app_icon_light.svg", f"{src}/app_icon_dark.svg"
make("AppIcon", classic_light, classic_dark)
preview("Default", classic_light, classic_dark)
palettes = [("classic", palette(classic_light, classic_dark))]
for variant in ["amethyst", "aurora", "blush", "cyber_lime", "dune", "ember", "evergreen",
                "glacier", "lagoon", "matcha", "midnight_gold", "noir"]:
    name = "".join(p.capitalize() for p in variant.split("_"))
    light = f"{src}/app_icon_variants/app_icon_{variant}_light.svg"
    dark = f"{src}/app_icon_variants/app_icon_{variant}_dark.svg"
    make(f"AppIcon-{name}", light, dark)
    preview(name, light, dark)
    palettes.append((name[0].lower() + name[1:], palette(light, dark)))
    print(name)
write_palettes(palettes)
