#!/bin/bash
# Entrypoint wrapper for the RunPod worker.
# Downloads any missing models from HuggingFace to the Network Volume,
# then hands off to the base image's original /start.sh.

# RunPod serverless always mounts the network volume at /runpod-volume.
# ComfyUI expects models at /comfyui/models — symlink bridges the two.
mkdir -p /runpod-volume
ln -sfn /runpod-volume /comfyui/models

echo "=== Checking/downloading models to network volume ==="
/download_models.sh
echo "=== Starting worker ==="
exec /start.sh
