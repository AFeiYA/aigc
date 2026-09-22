#!/usr/bin/env bash
# ==============================================================================
# AIGC 本地一键启动脚本 (Mac Apple Silicon 专属优化版)
# ==============================================================================

set -eo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -d ".venv" ] || [ ! -f "ComfyUI/main.py" ]; then
    echo -e "${RED}[错误] 尚未部署完整环境，请先执行: ./setup.sh${NC}"
    exit 1
fi

# 激活 uv 构建的 Python 虚拟环境
source .venv/bin/activate

# ==============================================================================
# Apple Silicon 关键性能与显存调优参数
# ==============================================================================
# 1. 突破 macOS 统一内存的水位保护，允许 PyTorch 充分利用统一内存空间（避免伪 OOM）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 2. 当某些特殊算子未实现 MPS 原生加速时，自动回退到 CPU 执行，避免程序崩溃
export PYTORCH_ENABLE_MPS_FALLBACK=1

# 3. 避免偶发性 OpenMP 冲突
export KMP_DUPLICATE_LIB_OK=TRUE

PORT=8188
URL="http://127.0.0.1:${PORT}"

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}      启动本地 AIGC 工作流服务 (ComfyUI)...${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "  硬件加速:  ${GREEN}Apple Silicon Metal (MPS)${NC}"
echo -e "  本地地址:  ${BLUE}${URL}${NC}"
echo -e "  运行模式:  ${YELLOW}--force-fp16 (低显存高速半精度)${NC}"
echo -e "${BLUE}======================================================${NC}"

# 后台等待服务就绪并自动打开浏览器
(
    sleep 3
    if command -v open &> /dev/null; then
        echo -e "${GREEN}--> 正在自动打开浏览器: ${URL}${NC}"
        open "$URL" || true
    fi
) &

# 启动 ComfyUI 并透传所有额外命令行参数
exec python ComfyUI/main.py \
    --force-fp16 \
    --preview-method auto \
    --listen 127.0.0.1 \
    --port "$PORT" \
    "$@"
