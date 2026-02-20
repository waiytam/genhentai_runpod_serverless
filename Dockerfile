# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.5.1-base

# install custom nodes into comfyui (first node with --mode remote to fetch updated cache)
# The workflow lists only unknown_registry custom nodes and none provide aux_id (GitHub repo).
# Therefore none can be installed via `comfy node install` or cloned automatically. Skipping these with notes:
# Could not resolve unknown registry node CheckpointLoaderSimple - no aux_id provided; skipped
# Could not resolve unknown registry node ModelSamplingSD3 - no aux_id provided; skipped
# Could not resolve unknown registry node VHS_VideoCombine - no aux_id provided; skipped
# Could not resolve unknown registry node WanImageToVideo - no aux_id provided; skipped
# Could not resolve unknown registry node CLIPVisionEncode - no aux_id provided; skipped
# Could not resolve unknown registry node CLIPVisionLoader - no aux_id provided; skipped
# Could not resolve unknown registry node LoadImageFromUrlOrPath - no aux_id provided; skipped
# Could not resolve unknown registry node easy cleanGpuUsed - no aux_id provided; skipped
# Could not resolve unknown registry node easy clearCacheAll - no aux_id provided; skipped

# download models into comfyui
RUN comfy model download --url https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/blob/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors --relative-path models/checkpoints --filename wan2.2-i2v-rapid-aio-v10-nsfw.safetensors
RUN comfy model download --url https://huggingface.co/lllyasviel/misc/blob/main/clip_vision_vit_h.safetensors --relative-path models/clip_vision --filename clip_vision_vit_h.safetensors

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/
