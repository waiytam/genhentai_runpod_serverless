# Base image: ComfyUI + comfy-cli + ComfyUI-Manager
FROM runpod/worker-comfyui:5.5.1-base

# Install ComfyUI-VideoHelperSuite (provides VHS_VideoCombine for MP4 video output)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip install -r /comfyui/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt

# Download models into ComfyUI
RUN comfy model download \
    --url https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/blob/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors \
    --relative-path models/checkpoints \
    --filename wan2.2-i2v-rapid-aio-v10-nsfw.safetensors

RUN comfy model download \
    --url https://huggingface.co/lllyasviel/misc/blob/main/clip_vision_vit_h.safetensors \
    --relative-path models/clip_vision \
    --filename clip_vision_vit_h.safetensors
