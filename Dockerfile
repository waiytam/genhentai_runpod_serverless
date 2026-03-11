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

# ── Main models ───────────────────────────────────────────────────────────────

# WAN 2.2 GGUF dual-model (High + Low noise, Enhanced NSFW SVI Camera merge)
RUN comfy model download \
    --url "https://huggingface.co/rgomezs2010/loras_wan/resolve/54e79c9896eeeed2c0d23e03bfd5b64fc1a1fad6/wan22EnhancedNSFWSVICamera_nsfwV2Q8High.gguf" \
    --relative-path models/diffusion_models \
    --filename wan22EnhancedNSFWSVICamera_nsfwV2Q8High.gguf

RUN comfy model download \
    --url "https://huggingface.co/rgomezs2010/loras_wan/resolve/54e79c9896eeeed2c0d23e03bfd5b64fc1a1fad6/wan22EnhancedNSFWSVICamera_nsfwV2Q8Low.gguf" \
    --relative-path models/diffusion_models \
    --filename wan22EnhancedNSFWSVICamera_nsfwV2Q8Low.gguf

# CLIP text encoder (fp8, used by ClipLoaderGGUF node)
RUN comfy model download \
    --url "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    --relative-path models/clip \
    --filename umt5_xxl_fp8_e4m3fn_scaled.safetensors

# VAE
RUN comfy model download \
    --url "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    --relative-path models/vae \
    --filename wan_2.1_vae.safetensors

# CLIP Vision (used internally by WanImageToVideo)
RUN comfy model download \
    --url "https://huggingface.co/lllyasviel/misc/resolve/main/clip_vision_vit_h.safetensors" \
    --relative-path models/clip_vision \
    --filename clip_vision_vit_h.safetensors

# ── LoRAs (from waiytam/genhentai-lora-wan HuggingFace repo) ─────────────────
# Default LoRAs (always active in workflow nodes 97 and 98):

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/SmoothXXXAnimation_High.safetensors" \
    --relative-path models/loras \
    --filename SmoothXXXAnimation_High.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/SmoothXXXAnimation_Low.safetensors" \
    --relative-path models/loras \
    --filename SmoothXXXAnimation_Low.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-k3nk4llinon3-16epoc-full-high-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-k3nk4llinon3-16epoc-full-high-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-k3nk4llinon3-15epoc-full-low-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-k3nk4llinon3-15epoc-full-low-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/bounce_test_HighNoise-000005.safetensors" \
    --relative-path models/loras \
    --filename bounce_test_HighNoise-000005.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/bounce_test_LowNoise-000005.safetensors" \
    --relative-path models/loras \
    --filename bounce_test_LowNoise-000005.safetensors

# Dynamic LoRAs (selected per-generation by keyword scanning):

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/PENISLORA_22_i2v_HIGH_e320.safetensors" \
    --relative-path models/loras \
    --filename PENISLORA_22_i2v_HIGH_e320.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/PENISLORA_22_i2v_LOW_e496.safetensors" \
    --relative-path models/loras \
    --filename PENISLORA_22_i2v_LOW_e496.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/PenInsert_high_noise.safetensors" \
    --relative-path models/loras \
    --filename PenInsert_high_noise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/PenInsert_low_noise.safetensors" \
    --relative-path models/loras \
    --filename PenInsert_low_noise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan2.2-i2v-high-breast-insertion-v1.0.safetensors" \
    --relative-path models/loras \
    --filename wan2.2-i2v-high-breast-insertion-v1.0.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan2.2-i2v-low-breast-insertion-v1.0.safetensors" \
    --relative-path models/loras \
    --filename wan2.2-i2v-low-breast-insertion-v1.0.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan2.2-i2v-high-pov-insertion-v1.0.safetensors" \
    --relative-path models/loras \
    --filename wan2.2-i2v-high-pov-insertion-v1.0.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan2.2-i2v-low-pov-insertion-v1.0.safetensors" \
    --relative-path models/loras \
    --filename wan2.2-i2v-low-pov-insertion-v1.0.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/pussyjob_v1.0_wan2.1_14b.safetensors" \
    --relative-path models/loras \
    --filename pussyjob_v1.0_wan2.1_14b.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/DR34MJOB_I2V_14b_HighNoise.safetensors" \
    --relative-path models/loras \
    --filename DR34MJOB_I2V_14b_HighNoise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/DR34MJOB_I2V_14b_LowNoise.safetensors" \
    --relative-path models/loras \
    --filename DR34MJOB_I2V_14b_LowNoise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-fullnelson-i2v-108epoc-high-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-fullnelson-i2v-108epoc-high-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-fullnelson-i2v-368epoc-low-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-fullnelson-i2v-368epoc-low-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/Wan2.2_dp_v2_HighNoise-000020.safetensors" \
    --relative-path models/loras \
    --filename Wan2.2_dp_v2_HighNoise-000020.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/Wan2.2_dp_v2_LowNoise-000018.safetensors" \
    --relative-path models/loras \
    --filename Wan2.2_dp_v2_LowNoise-000018.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-ultimatedeepthroat-i2v-102epoc-high-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-ultimatedeepthroat-i2v-102epoc-high-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-ultimatedeepthroat-I2V-101epoc-low-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-ultimatedeepthroat-I2V-101epoc-low-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/23High-Cumshot-Aesthetics.safetensors" \
    --relative-path models/loras \
    --filename 23High-Cumshot-Aesthetics.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/56Low-Cumshot-Aesthetics.safetensors" \
    --relative-path models/loras \
    --filename 56Low-Cumshot-Aesthetics.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-mouthfull-140epoc-high-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-mouthfull-140epoc-high-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/wan22-mouthfull-152epoc-low-k3nk.safetensors" \
    --relative-path models/loras \
    --filename wan22-mouthfull-152epoc-low-k3nk.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/sh00tz_HN_75.safetensors" \
    --relative-path models/loras \
    --filename sh00tz_HN_75.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/sh00tz_LN_75.safetensors" \
    --relative-path models/loras \
    --filename sh00tz_LN_75.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/X-ray_creampie_high.safetensors" \
    --relative-path models/loras \
    --filename X-ray_creampie_high.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/X-ray_creampie_low.safetensors" \
    --relative-path models/loras \
    --filename X-ray_creampie_low.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/maleejac_000004625_high_noise.safetensors" \
    --relative-path models/loras \
    --filename maleejac_000004625_high_noise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/maleejac_000004625_low_noise.safetensors" \
    --relative-path models/loras \
    --filename maleejac_000004625_low_noise.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/CRM-FULL-EPOCH-80-HIGH.safetensors" \
    --relative-path models/loras \
    --filename CRM-FULL-EPOCH-80-HIGH.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/CRM-FULL-EPOCH-80-LOW.safetensors" \
    --relative-path models/loras \
    --filename CRM-FULL-EPOCH-80-LOW.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/TWERKI2VHIGH.safetensors" \
    --relative-path models/loras \
    --filename TWERKI2VHIGH.safetensors

RUN comfy model download \
    --url "https://huggingface.co/waiytam/genhentai-lora-wan/resolve/main/TWERKI2VLOW.safetensors" \
    --relative-path models/loras \
    --filename TWERKI2VLOW.safetensors
