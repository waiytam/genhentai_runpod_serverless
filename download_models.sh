#!/bin/bash
# Download models to the RunPod Network Volume if they are not already present.
# Idempotent: re-running on an already-populated volume is a fast no-op.
set -e

MODELS_DIR="/runpod-volume/models"
LORA_DIR="$MODELS_DIR/loras"
DIFF_DIR="$MODELS_DIR/unet"
CLIP_DIR="$MODELS_DIR/clip"
VAE_DIR="$MODELS_DIR/vae"
CLIP_VIS_DIR="$MODELS_DIR/clip_vision"

HF_BASE="https://huggingface.co"
LORA_REPO="waiytam/genhentai-lora-wan/resolve/main"

download_if_missing() {
  local dest="$1"
  local url="$2"
  if [ ! -f "$dest" ]; then
    echo "Downloading $(basename "$dest")..."
    mkdir -p "$(dirname "$dest")"
    # Pass HF token if set (required for private HuggingFace repos)
    if [ -n "$HF_TOKEN" ]; then
      wget -q --show-progress --header="Authorization: Bearer $HF_TOKEN" -O "$dest" "$url" \
        || { echo "FAILED: $url"; rm -f "$dest"; }
    else
      wget -q --show-progress -O "$dest" "$url" || { echo "FAILED: $url"; rm -f "$dest"; }
    fi
  else
    echo "Already present: $(basename "$dest")"
  fi
}

# ── Main models ───────────────────────────────────────────────────────────────

# WAN 2.2 GGUF dual-model (High + Low noise, Enhanced NSFW SVI Camera merge)
download_if_missing "$DIFF_DIR/wan22EnhancedNSFWSVICamera_nsfwV2Q8High.gguf" \
  "$HF_BASE/rgomezs2010/loras_wan/resolve/54e79c9896eeeed2c0d23e03bfd5b64fc1a1fad6/wan22EnhancedNSFWSVICamera_nsfwV2Q8High.gguf"

download_if_missing "$DIFF_DIR/wan22EnhancedNSFWSVICamera_nsfwV2Q8Low.gguf" \
  "$HF_BASE/rgomezs2010/loras_wan/resolve/54e79c9896eeeed2c0d23e03bfd5b64fc1a1fad6/wan22EnhancedNSFWSVICamera_nsfwV2Q8Low.gguf"

# CLIP text encoder (fp8, used by ClipLoaderGGUF node)
download_if_missing "$CLIP_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
  "$HF_BASE/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# VAE
download_if_missing "$VAE_DIR/wan_2.1_vae.safetensors" \
  "$HF_BASE/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# CLIP Vision (used internally by WanImageToVideo)
download_if_missing "$CLIP_VIS_DIR/clip_vision_vit_h.safetensors" \
  "$HF_BASE/lllyasviel/misc/resolve/main/clip_vision_vit_h.safetensors"

# ── Default LoRAs (always active in workflow nodes 97 and 98) ─────────────────

for f in \
  "SmoothXXXAnimation_High.safetensors" \
  "SmoothXXXAnimation_Low.safetensors" \
  "wan22-k3nk4llinon3-16epoc-full-high-k3nk.safetensors" \
  "wan22-k3nk4llinon3-15epoc-full-low-k3nk.safetensors" \
  "bounce_test_HighNoise-000005.safetensors" \
  "bounce_test_LowNoise-000005.safetensors"; do
  download_if_missing "$LORA_DIR/$f" "$HF_BASE/$LORA_REPO/$f"
done

# ── Dynamic LoRAs (selected per-generation by keyword scanning) ───────────────

for f in \
  "PENISLORA_22_i2v_HIGH_e320.safetensors" \
  "PENISLORA_22_i2v_LOW_e496.safetensors" \
  "PenInsert_high_noise.safetensors" \
  "PenInsert_low_noise.safetensors" \
  "wan2.2-i2v-high-breast-insertion-v1.0.safetensors" \
  "wan2.2-i2v-low-breast-insertion-v1.0.safetensors" \
  "wan2.2-i2v-high-pov-insertion-v1.0.safetensors" \
  "wan2.2-i2v-low-pov-insertion-v1.0.safetensors" \
  "pussyjob_v1.0_wan2.1_14b.safetensors" \
  "DR34MJOB_I2V_14b_HighNoise.safetensors" \
  "DR34MJOB_I2V_14b_LowNoise.safetensors" \
  "wan22-fullnelson-i2v-108epoc-high-k3nk.safetensors" \
  "wan22-fullnelson-i2v-368epoc-low-k3nk.safetensors" \
  "Wan2.2_dp_v2_HighNoise-000020.safetensors" \
  "Wan2.2_dp_v2_LowNoise-000018.safetensors" \
  "wan22-ultimatedeepthroat-i2v-102epoc-high-k3nk.safetensors" \
  "wan22-ultimatedeepthroat-I2V-101epoc-low-k3nk.safetensors" \
  "23High-Cumshot-Aesthetics.safetensors" \
  "56Low-Cumshot-Aesthetics.safetensors" \
  "wan22-mouthfull-140epoc-high-k3nk.safetensors" \
  "wan22-mouthfull-152epoc-low-k3nk.safetensors" \
  "sh00tz_HN_75.safetensors" \
  "sh00tz_LN_75.safetensors" \
  "X-ray_creampie_high.safetensors" \
  "X-ray_creampie_low.safetensors" \
  "maleejac_000004625_high_noise.safetensors" \
  "maleejac_000004625_low_noise.safetensors" \
  "CRM-FULL-EPOCH-80-HIGH.safetensors" \
  "CRM-FULL-EPOCH-80-LOW.safetensors" \
  "TWERKI2VHIGH.safetensors" \
  "TWERKI2VLOW.safetensors"; do
  download_if_missing "$LORA_DIR/$f" "$HF_BASE/$LORA_REPO/$f"
done

echo "Model check complete."
