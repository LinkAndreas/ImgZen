"""Build Icon Composer .icon bundles from the ImgZen icon SVGs, one layer per SVG element.

Each element in the SVGs is preceded by a <!-- name --> comment; that name becomes the layer.
Layers keep the SVGs' paint order. They are grouped (Icon Composer applies glass per group)
into Background, Mountains (behind the sun), Sun and Mountains (in front of the sun).
Layers only in the dark SVG (the glows) are hidden in the light appearance.

Also writes the vector IconPreview-<Name> images the supporter icon picker shows.
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

make("AppIcon", f"{src}/app_icon_light.svg", f"{src}/app_icon_dark.svg")
preview("Default", f"{src}/app_icon_light.svg", f"{src}/app_icon_dark.svg")
for variant in ["amethyst", "aurora", "blush", "cyber_lime", "dune", "ember", "evergreen",
                "glacier", "lagoon", "matcha", "midnight_gold", "noir"]:
    name = "".join(p.capitalize() for p in variant.split("_"))
    light = f"{src}/app_icon_variants/app_icon_{variant}_light.svg"
    dark = f"{src}/app_icon_variants/app_icon_{variant}_dark.svg"
    make(f"AppIcon-{name}", light, dark)
    preview(name, light, dark)
    print(name)
