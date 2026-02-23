"""
Patch the runpod-worker-comfyui handler to support VHS video (gifs) output.

VHS_VideoCombine saves the MP4 and stores it under the 'gifs' key in the
ComfyUI history. The base worker only processes 'images' outputs, so the
generated video is silently discarded. This patch makes the worker treat
'gifs' the same as 'images': fetch the file from ComfyUI and return it.
"""
import os
import sys
import glob

# Locate the handler file (path varies across worker versions)
candidates = [
    "/src/rp_handler.py",
    "/app/src/rp_handler.py",
    "/handler.py",
]
candidates += glob.glob("/opt/venv/lib/*/site-packages/*comfy*/rp_handler.py")
candidates += glob.glob("/opt/venv/lib/*/site-packages/*comfy*/handler.py")

handler_path = next((p for p in candidates if os.path.exists(p)), None)
if not handler_path:
    print("WARNING: Could not locate handler file — skipping patch")
    sys.exit(0)

print(f"Patching handler at: {handler_path}")
with open(handler_path) as f:
    src = f.read()

if '"gifs"' in src or "'gifs'" in src:
    print("Handler already supports gifs output — nothing to do")
    sys.exit(0)

patched = src

# Pattern A: key == "images"  — handler iterates node output keys (double quotes)
if 'key == "images"' in patched:
    patched = patched.replace(
        'key == "images"',
        'key in ("images", "gifs")',
    )
    print("Applied pattern A: key == images -> key in (images, gifs)")

# Pattern A2: key == 'images'  — single quotes variant
if "key == 'images'" in patched:
    patched = patched.replace(
        "key == 'images'",
        "key in ('images', 'gifs')",
    )
    print("Applied pattern A2: key == 'images' -> key in ('images', 'gifs')")

# Pattern B: if "images" in node_output:  — double quotes
if '"images" in node_output' in patched:
    patched = patched.replace(
        '"images" in node_output',
        'bool(set(node_output.keys()) & {"images", "gifs"})',
    )
    print('Applied pattern B: "images" in node_output -> set intersection')

# Pattern B2: if 'images' in node_output:  — single quotes
if "'images' in node_output" in patched:
    patched = patched.replace(
        "'images' in node_output",
        "bool(set(node_output.keys()) & {'images', 'gifs'})",
    )
    print("Applied pattern B2: 'images' in node_output -> set intersection")

# Pattern C: node_output["images"]  — direct key access (double quotes)
if 'node_output["images"]' in patched:
    patched = patched.replace(
        'node_output["images"]',
        'node_output.get("images", node_output.get("gifs", []))',
    )
    print('Applied pattern C: node_output["images"] -> get with gifs fallback')

# Pattern C2: node_output['images']  — direct key access (single quotes)
if "node_output['images']" in patched:
    patched = patched.replace(
        "node_output['images']",
        "node_output.get('images', node_output.get('gifs', []))",
    )
    print("Applied pattern C2: node_output['images'] -> get with gifs fallback")

if patched == src:
    print("WARNING: No patch patterns matched — handler structure differs from expected")
    sys.exit(0)

with open(handler_path, "w") as f:
    f.write(patched)
print("Handler patched successfully for VHS video output")
