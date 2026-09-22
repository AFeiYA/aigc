#!/usr/bin/env bash
# ==============================================================================
# 常用基础模型一键批量下载脚本 (适配 32GB Mac Apple Silicon)
# 支持：多选批量下载 (如 1 2 3)、一键全量套餐、镜像站高速切换、断点续传与已下载跳过
# ==============================================================================

set -eo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

COMFY_MODELS="$PROJECT_DIR/ComfyUI/models"

if [ ! -d "$COMFY_MODELS" ]; then
    echo -e "${RED}[错误] 请先执行 ./setup.sh 部署 ComfyUI${NC}"
    exit 1
fi

echo -e "${BLUE}====================================================================${NC}"
echo -e "${GREEN}      本地 AIGC 推荐精选模型 批量 / 全量一键下载工具${NC}"
echo -e "${BLUE}====================================================================${NC}"
echo -e "支持输入单个或多个编号（空格或逗号分隔），也支持一键全家桶套餐："
echo -e "--------------------------------------------------------------------"
echo -e "  ${CYAN}[1]${NC} Flux.1 必备核心 (VAE + CLIP-L + T5XXL FP8)       [约 5.5GB]"
echo -e "  ${CYAN}[2]${NC} Flux.1-schnell 极速生图底模 (GGUF Q8_0)         [约 12GB]"
echo -e "  ${CYAN}[3]${NC} LTX-Video 2B 轻量视频底模 (Mac 极速出片)         [约 2.8GB]"
echo -e "  ${CYAN}[4]${NC} Wan 2.1 1.3B 电影感视频底模 (万象电影质感)       [约 3.5GB]"
echo -e "--------------------------------------------------------------------"
echo -e "  ${YELLOW}[A] 或 [all]${NC}   一键全量下载以上所有模型 (1 + 2 + 3 + 4)"
echo -e "  ${YELLOW}[P] 或 [photo]${NC} 一键生图黄金套装 (1 + 2)"
echo -e "  ${YELLOW}[V] 或 [video]${NC} 一键视频生成套装 (3 + 4)"
echo -e "  ${RED}[Q] 或 [quit]${NC}  退出"
echo -e "--------------------------------------------------------------------"

read -p "请输入选项编号 (支持多选，如: 1 2 3 或 直接按 A 全选): " user_input

# 转为小写处理
user_input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')

if [[ "$user_input_lower" =~ ^(q|quit|exit)$ ]] || [ -z "$user_input" ]; then
    echo "已取消退出。"
    exit 0
fi

# 镜像加速选择
echo -e "\n${BLUE}是否使用国内高速镜像源 (hf-mirror.com) 加速下载？${NC}"
read -p "使用镜像加速请按 Y，直连海外官方源请按 N [默认 Y]: " use_mirror
use_mirror=${use_mirror:-Y}

if [[ "$use_mirror" =~ ^[Yy]$ ]]; then
    HF_DOMAIN="https://hf-mirror.com"
    echo -e "${GREEN}✔ 已启用国内高速镜像加速：${HF_DOMAIN}${NC}\n"
else
    HF_DOMAIN="https://huggingface.co"
    echo -e "${BLUE}✔ 使用官方源：${HF_DOMAIN}${NC}\n"
fi

# 通用下载函数 (支持已存在跳过、断点续传)
download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename="$3"
    local filepath="$dest_dir/$filename"

    mkdir -p "$dest_dir"

    # 如果文件已存在且大小大于 10MB，提示是否跳过
    if [ -f "$filepath" ]; then
        local file_size_mb
        file_size_mb=$(du -m "$filepath" | cut -f1)
        if [ "$file_size_mb" -ge 10 ]; then
            echo -e "  ${GREEN}✔ [已存在，跳过]${NC} $filename (${file_size_mb} MB) -> $dest_dir"
            return 0
        fi
    fi

    echo -e "  ${BLUE}--> 正在下载:${NC} ${filename}"
    echo -e "      目标位置: ${CYAN}${filepath}${NC}"
    
    # 使用 curl 支持断点续传与网络重试
    if command -v curl &> /dev/null; then
        curl -L --progress-bar -C - --retry 5 --retry-delay 2 "$url" -o "$filepath"
    elif command -v wget &> /dev/null; then
        wget -c -t 5 "$url" -O "$filepath"
    else
        echo -e "${RED}[错误] 未检测到 curl 或 wget${NC}"
        return 1
    fi

    echo -e "  ${GREEN}✔ 下载完成:${NC} $filename\n"
}

# 任务分发函数
run_task() {
    local task_id="$1"
    case $task_id in
        1)
            echo -e "${YELLOW}>>> [任务 1] 下载 Flux.1 必备组件 (VAE + 文本编码器)...${NC}"
            download_file "${HF_DOMAIN}/camenduru/FLUX.1-dev/resolve/main/ae.safetensors" \
                          "$COMFY_MODELS/vae" "ae.safetensors"
            download_file "${HF_DOMAIN}/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
                          "$COMFY_MODELS/clip" "clip_l.safetensors"
            download_file "${HF_DOMAIN}/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors" \
                          "$COMFY_MODELS/clip" "t5xxl_fp8_e4m3fn.safetensors"
            ;;
        2)
            echo -e "${YELLOW}>>> [任务 2] 下载 Flux.1-schnell GGUF 极速生图底模...${NC}"
            download_file "${HF_DOMAIN}/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q8_0.gguf" \
                          "$COMFY_MODELS/unet" "flux1-schnell-Q8_0.gguf"
            ;;
        3)
            echo -e "${YELLOW}>>> [任务 3] 下载 LTX-Video 2B 极速视频底模...${NC}"
            download_file "${HF_DOMAIN}/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.1.safetensors" \
                          "$COMFY_MODELS/checkpoints" "ltx-video-2b-v0.9.1.safetensors"
            ;;
        4)
            echo -e "${YELLOW}>>> [任务 4] 下载 Wan 2.1 1.3B 电影感视频底模...${NC}"
            download_file "${HF_DOMAIN}/Wan-AI/Wan2.1-T2V-1.3B/resolve/main/diffusion_pytorch_model.safetensors" \
                          "$COMFY_MODELS/diffusion_models" "wan2.1_t2v_1.3B.safetensors"
            ;;
    esac
}

# 解析用户输入
TASKS=()

if [[ "$user_input_lower" =~ all|a ]]; then
    TASKS=(1 2 3 4)
elif [[ "$user_input_lower" =~ photo|p ]]; then
    TASKS=(1 2)
elif [[ "$user_input_lower" =~ video|v ]]; then
    TASKS=(3 4)
else
    # 提取所有数字并去重
    for token in $user_input; do
        token_clean=$(echo "$token" | tr -cd '0-9')
        if [[ "$token_clean" =~ ^[1-4]$ ]]; then
            TASKS+=("$token_clean")
        fi
    done
fi

# 去重任务
UNIQUE_TASKS=($(echo "${TASKS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

if [ ${#UNIQUE_TASKS[@]} -eq 0 ]; then
    echo -e "${RED}[错误] 未识别到有效选项，请输入 1-4 或 A/P/V 套餐${NC}"
    exit 1
fi

echo -e "${GREEN}====================================================================${NC}"
echo -e " 即将开始批量执行任务: ${YELLOW}${UNIQUE_TASKS[*]}${NC}"
echo -e "${GREEN}====================================================================${NC}\n"

for tid in "${UNIQUE_TASKS[@]}"; do
    run_task "$tid"
done

echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}         🎉 所选模型已全部处理/下载完毕！${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "现在你可以执行 ${BLUE}./start.sh${NC} 启动 ComfyUI 开始创作了！\n"
