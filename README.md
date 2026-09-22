# 本地 AIGC 图片/视频生成工作流工程 (Mac Apple Silicon 专属)

本项目为搭载 **Apple Silicon 芯片与 32GB 统一内存** 的 MacBook Pro 量身定制，提供单机本地一键自动化部署、运行与加速优化的 AIGC 解决方案。

---

## 目录结构

```text
AIGC/
├── .gitignore               # 过滤虚拟环境、模型权重二进制与生成产物
├── setup.sh                 # 【核心】一键自动化部署脚本（环境、uv虚拟环境、PyTorch MPS、ComfyUI与插件）
├── start.sh                 # 【核心】一键启动脚本（加载 Apple Silicon 优化环境变量并启动服务）
├── download_models.sh       # 【辅助】精选模型一键下载/指引工具
├── workflows/               # 自定义与推荐工作流 JSON 存放目录
├── ComfyUI/                 # ComfyUI 主干仓库（运行 setup.sh 后自动克隆生成）
│   ├── custom_nodes/        # 核心扩展插件（Manager、GGUF量化加载器、VideoHelperSuite 等）
│   └── models/              # 模型存放主目录
│       ├── unet/            # Flux GGUF 量化模型
│       ├── diffusion_models/# Wan 2.1 / LTX-Video 等视频模型
│       ├── checkpoints/     # SDXL / SD1.5 完整底模
│       ├── clip/            # 文本编码器 (t5xxl, clip_l)
│       ├── vae/             # 变分自编码器 (ae.safetensors)
│       └── loras/           # 微调 LoRA 权重
└── README.md                # 本说明文档
```

---

## 快速上手

### 1. 一键部署
在项目根目录下直接运行部署脚本：
```bash
chmod +x *.sh
./setup.sh
```
`setup.sh` 将自动完成：
- 识别并使用 `uv` 创建隔离的 **Python 3.11** 独立虚拟环境（`.venv`），绝不污染系统全局环境。
- 安装支持 Apple Metal 硬件加速（MPS）的 **PyTorch**。
- 拉取最新的 **ComfyUI** 官方主干。
- 自动部署 Mac 必备的核心插件矩阵：
  - **ComfyUI-Manager**：插件与模型图形化一键下载器。
  - **ComfyUI-GGUF**：让 Mac 能够以极小内存运行 Flux 等超大模型的量化加载器。
  - **ComfyUI-VideoHelperSuite**：视频处理与合成工具套件。
- 补全所有模型分类目录。

### 2. 一键启动
部署完成后，直接运行：
```bash
./start.sh
```
- 脚本会自动载入 **Apple Silicon 显存优化参数**（突破水位线限制，避免假性显存不足）。
- 以 `--force-fp16` 半精度高速模式运行。
- 自动在默认浏览器中打开 `http://127.0.0.1:8188`。

---

## 模型下载与存放指引

可使用内置的 `./download_models.sh` 脚本，或者直接通过 Web 界面右侧菜单栏的 **「Manager」 -> 「Install Models」** 搜索下载。

手动下载模型文件时的对应存放目录如下：

| 模型类型 | 推荐模型举例 | 存放路径 (`ComfyUI/models/`) | 说明 |
| :--- | :--- | :--- | :--- |
| **GGUF 量化生图** | `flux1-schnell-Q8_0.gguf` | `models/unet/` | 4 步极速出写实大片 |
| **文本编码器** | `t5xxl_fp8_e4m3fn.safetensors` | `models/clip/` | 语言理解与复杂语义映射 |
| **文本编码器** | `clip_l.safetensors` | `models/clip/` | 基础文本编码 |
| **生图 VAE** | `ae.safetensors` | `models/vae/` | Flux 官方解码器 |
| **视频模型 (推荐)** | `wan2.1_t2v_1.3B.safetensors` | `models/diffusion_models/` | 电影质感视频生成 |
| **视频模型 (轻量)** | `ltx-video-2b-v0.9.1.safetensors` | `models/checkpoints/` | 极速高流畅度短视频 |
| **SDXL 完整底模** | `juggernautXL.safetensors` | `models/checkpoints/` | 经典高效底模 |

---

## 32GB 统一内存高级调优（进阶）

macOS 系统默认单个图形应用进程最多申请物理内存的约 70% 左右。如果运行较大的 14B 视频模型，可在 macOS 终端临时提升 GPU 有线内存配额：

```bash
# 查看当前限制
sysctl iogpu.wired_mem_limit

# (可选) 临时调整到约 27GB 显存上限 (重启后自动恢复)
sudo sysctl iogpu.wired_mem_limit=28991029248
```
