#!/usr/bin/env bash
# ==============================================================================
# AIGC 本地环境一键自动化部署脚本 (Mac Apple Silicon 专属优化版)
# 使用 uv 管理 Python 3.11 独立虚拟环境 + PyTorch MPS 加速 + ComfyUI
# ==============================================================================

set -eo pipefail

# 确保常用工具路径加载
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# 文本颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}    Mac Apple Silicon 本地 AIGC 一键部署脚本${NC}"
echo -e "${BLUE}======================================================${NC}"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 1. 检查基础系统依赖
echo -e "\n${BLUE}[1/6] 检查系统环境依赖...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}[错误] 未检测到 git，请先安装 Xcode Command Line Tools: xcode-select --install${NC}"
    exit 1
fi
echo -e "  ✔ Git: $(git --version)"

# 检查 ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}  ⚠ 未检测到 ffmpeg，视频生成/处理强烈建议安装：brew install ffmpeg${NC}"
else
    echo -e "  ✔ FFmpeg: $(ffmpeg -version | head -n 1 | awk '{print $1, $2, $3}')"
fi

# 检查 uv
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}  ⚠ 未在 PATH 中找到 uv，尝试安装 uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}[错误] uv 安装失败，请手动安装后重试: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
        exit 1
    fi
fi
echo -e "  ✔ uv 包管理器: $(uv --version)"

# 2. 构建独立 Python 3.11 虚拟环境
echo -e "\n${BLUE}[2/6] 使用 uv 初始化 Python 3.11 虚拟环境...${NC}"
if [ ! -d ".venv" ]; then
    echo -e "  正在创建 .venv (Python 3.11)..."
    uv venv .venv --python 3.11
    echo -e "${GREEN}  ✔ 虚拟环境创建完成 (.venv)${NC}"
else
    echo -e "  ✔ 虚拟环境 .venv 已存在，跳过创建"
fi

VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"
VENV_PIP="$PROJECT_DIR/.venv/bin/pip"

# 3. 安装 PyTorch (带 Apple Silicon MPS 支持) 与核心基础包
echo -e "\n${BLUE}[3/6] 安装 PyTorch 与 Apple Metal (MPS) 加速组件...${NC}"
uv pip install --python "$VENV_PYTHON" \
    torch torchvision torchaudio \
    --upgrade

# 验证 MPS 是否可用
echo -e "  正在验证 PyTorch Metal (MPS) 支持..."
MPS_STATUS=$("$VENV_PYTHON" -c "import torch; print('available' if torch.backends.mps.is_available() else 'unavailable')")
if [ "$MPS_STATUS" = "available" ]; then
    echo -e "${GREEN}  ✔ Apple Silicon Metal (MPS) 硬件加速检测通过！${NC}"
else
    echo -e "${YELLOW}  ⚠ 警告: torch.backends.mps.is_available() 返回 False，将回退至 CPU 运算${NC}"
fi

# 4. 获取与更新 ComfyUI
echo -e "\n${BLUE}[4/6] 部署 ComfyUI 主干仓库...${NC}"
if [ ! -d "ComfyUI" ]; then
    echo -e "  克隆 ComfyUI 官方仓库..."
    git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
else
    echo -e "  ComfyUI 已存在，正在拉取最新代码..."
    git -C ComfyUI pull || echo -e "${YELLOW}  拉取代码出现警告，跳过更新${NC}"
fi

echo -e "  安装 ComfyUI 核心依赖..."
uv pip install --python "$VENV_PYTHON" -r ComfyUI/requirements.txt

# 5. 安装核心扩展插件 (Custom Nodes)
echo -e "\n${BLUE}[5/6] 部署 AIGC 图片/视频生成关键扩展插件...${NC}"
CUSTOM_NODES_DIR="ComfyUI/custom_nodes"
mkdir -p "$CUSTOM_NODES_DIR"

declare -A NODES=(
    ["ComfyUI-Manager"]="https://github.com/ltdrdata/ComfyUI-Manager.git"
    ["ComfyUI-GGUF"]="https://github.com/city96/ComfyUI-GGUF.git"
    ["ComfyUI-VideoHelperSuite"]="https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
)

for NODE_NAME in "${!NODES[@]}"; do
    NODE_URL="${NODES[$NODE_NAME]}"
    TARGET_PATH="$CUSTOM_NODES_DIR/$NODE_NAME"
    if [ ! -d "$TARGET_PATH" ]; then
        echo -e "  -> 正在安装插件: ${GREEN}$NODE_NAME${NC}..."
        git clone "$NODE_URL" "$TARGET_PATH"
    else
        echo -e "  -> 插件 ${GREEN}$NODE_NAME${NC} 已存在，跳过克隆"
    fi
    # 如果插件有单独的 requirements.txt，自动安装
    if [ -f "$TARGET_PATH/requirements.txt" ]; then
        uv pip install --python "$VENV_PYTHON" -r "$TARGET_PATH/requirements.txt" || true
    fi
done

# 安装 GGUF 与视频处理常用 Python 库
echo -e "  补充安装 GGUF 与媒体处理扩展包 (gguf, opencv-python, imageio)..."
uv pip install --python "$VENV_PYTHON" gguf opencv-python imageio[ffmpeg] moviepy

# 6. 初始化模型分类目录
echo -e "\n${BLUE}[6/6] 检查并补全模型存放目录...${NC}"
MODEL_DIRS=(
    "ComfyUI/models/checkpoints"
    "ComfyUI/models/unet"
    "ComfyUI/models/diffusion_models"
    "ComfyUI/models/vae"
    "ComfyUI/models/clip"
    "ComfyUI/models/loras"
    "ComfyUI/models/controlnet"
    "ComfyUI/models/upscale_models"
    "workflows"
)

for DIR in "${MODEL_DIRS[@]}"; do
    mkdir -p "$DIR"
    touch "$DIR/.gitkeep"
done

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}           🎉 本地 AIGC 环境部署完成！${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "接下来的操作："
echo -e "  1. 启动服务：执行 ${BLUE}./start.sh${NC} 即可自动打开浏览器"
echo -e "  2. 下载模型：执行 ${BLUE}./download_models.sh${NC} 或使用 ComfyUI-Manager 界面下载"
echo -e "  3. 详细说明：请阅读 ${YELLOW}README.md${NC}\n"
