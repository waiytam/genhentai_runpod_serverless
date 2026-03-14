# Base image: ComfyUI + comfy-cli + ComfyUI-Manager
FROM runpod/worker-comfyui:5.5.1-base

# Increase WebSocket polling interval so the worker waits 60 s between
# "Still waiting..." log lines instead of the default ~10 s.
ENV COMFY_POLLING_INTERVAL_MS=60000

# Disable torch.compile (dynamo) to prevent FP8 Triton kernel compilation errors
# on non-H100 GPUs.
ENV TORCHDYNAMO_DISABLE=1

# ── Custom nodes ──────────────────────────────────────────────────────────────

# ComfyUI-VideoHelperSuite (provides VHS_VideoCombine for MP4 video output)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip install -r /comfyui/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt

# ComfyUI-GGUF (provides UnetLoaderGGUF and ClipLoaderGGUF for .gguf model files)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    pip install -r /comfyui/custom_nodes/ComfyUI-GGUF/requirements.txt

# rgthree-comfy (provides "Power Lora Loader (rgthree)" node)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    pip install -r /comfyui/custom_nodes/rgthree-comfy/requirements.txt

# Patch the worker handler to also return VHS video (gifs) output alongside images.
COPY patch_handler.py /tmp/patch_handler.py
RUN python3 /tmp/patch_handler.py

# ── Model download startup script ────────────────────────────────────────────
# Models are NOT baked into the image. They live on a RunPod Network Volume
# mounted at /comfyui/models. The download script checks for each file and
# only downloads what is missing (idempotent — fast no-op on warm starts).

COPY download_models.sh /download_models.sh
RUN chmod +x /download_models.sh

# Entrypoint wrapper: download missing models first, then start the worker.
# Named entrypoint.sh to avoid overwriting the base image's own /start.sh.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
