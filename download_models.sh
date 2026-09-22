#!/usr/bin/env bash
# ==============================================================================
# 常用基础模型一键/指引下载脚本 (适配 32GB Mac Apple Silicon)
# ==============================================================================

set -eo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

COMFY_MODELS="$PROJECT_DIR/ComfyUI/models"

if [ ! -d "$COMFY_MODELS" ]; then
    echo -e "${RED}[错误] 请先执行 ./setup.sh 部署 ComfyUI${NC}"
    exit 1
fi

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   本地 AIGC 推荐精选模型一键下载/指引${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "模型下载推荐直接放入相应目录，或通过 ComfyUI 启动后右上角的"
echo -e "${YELLOW}「ComfyUI-Manager」 -> 「Install Models」${NC} 图形界面一键搜索下载。"
echo -e "------------------------------------------------------"
echo -e "1) 下载 Flux.1 必备组件 (VAE + CLIP-L + T5XXL FP8) [约 5.5GB]"
echo -e "2) 下载 Flux.1-schnell 极速版 (GGUF Q8_0) [约 12GB，4步出高质量大图]"
echo -e "3) 下载 LTX-Video 0.9B 轻量视频底模 [约 2.5GB，秒级高流畅度视频]"
echo -e "4) 下载 Wan 2.1 1.3B 电影感视频底模 [约 3.5GB，高质感镜头]"
echo -e "5) 退出"
echo -e "------------------------------------------------------"

read -p "请输入选择 [1-5]: " choice

download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename="$3"

    mkdir -p "$dest_dir"
    echo -e "${BLUE}正在下载: ${filename} 到 ${dest_dir}...${NC}"
    if command -v curl &> /dev/null; then
        curl -L --progress-bar -C - "$url" -o "$dest_dir/$filename"
    elif command -v wget &> /dev/null; then
        wget -c "$url" -O "$dest_dir/$filename"
    else
        echo -e "${RED}未找到 curl 或 wget${NC}"
    fi
    echo -e "${GREEN}✔ ${filename} 下载完成！${NC}"
}

case $choice in
    1)
        # Flux VAE & Text Encoders
        download_file "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors" \
                      "$COMFY_MODELS/vae" "ae.safetensors"
        download_file "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
                      "$COMFY_MODELS/clip" "clip_l.safetensors"
        download_file "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors" \
                      "$COMFY_MODELS/clip" "t5xxl_fp8_e4m3fn.safetensors"
        ;;
    2)
        # Flux.1 Schnell GGUF
        download_file "https://huggingface.co/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q8_0.gguf" \
                      "$COMFY_MODELS/unet" "flux1-schnell-Q8_0.gguf"
        ;;
    3)
        # LTX-Video
        download_file "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.1.safetensors" \
                      "$COMFY_MODELS/checkpoints" "ltx-video-2b-v0.9.1.safetensors"
        ;;
    4)
        # Wan 2.1 1.3B
        download_file "https://huggingface.co/Wan-AI/Wan2.1-T2V-1.3B/resolve/main/diffusion_pytorch_model.safetensors" \
                      "$COMFY_MODELS/diffusion_models" "wan2.1_t2v_1.3B.safetensors"
        ;;
    5)
        echo "已退出。"
        exit 0
        ;;
    *)
        echo "无效选项。"
        ;;
esac
