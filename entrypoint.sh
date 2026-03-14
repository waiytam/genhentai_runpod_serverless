#!/bin/bash
# Entrypoint wrapper for the RunPod worker.
# Downloads any missing models from HuggingFace to the Network Volume,
# then hands off to the base image's original /start.sh.
echo "=== Checking/downloading models to network volume ==="
/download_models.sh
echo "=== Starting worker ==="
exec /start.sh
