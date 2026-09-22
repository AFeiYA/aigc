#!/usr/bin/env python3
"""
局域网一键分镜批量生成脚本 (ComfyUI API Client)
可在本机或局域网任意设备（如另一台电脑、iPad、脚本服务器等）运行。
"""

import json
import urllib.request
import urllib.error
import time
import sys

# ==============================================================================
# 配置参数
# ==============================================================================
# 目标 ComfyUI 服务器地址（本机可用 127.0.0.1，局域网其它设备请替换为 Mac 局域网 IP，如 192.168.1.149）
COMFY_SERVER_URL = "http://127.0.0.1:8188"

# 你的分镜脚本列表（包含镜头序号、画面正向提示词、负向提示词、运镜与随机种子等）
STORYBOARDS = [
    {
        "shot": 1,
        "title": "赛博都市全景",
        "prompt": "wide establishing shot, futuristic neo-tokyo cyberpunk city at night, rain-slicked streets, glowing neon billboards, flying vehicles, highly detailed, photorealistic, 8k",
        "negative_prompt": "blurry, low quality, deformed, worst quality",
        "seed": 1001,
        "steps": 4  # 例如 Flux Schnell 只需要 4 步
    },
    {
        "shot": 2,
        "title": "主角特写",
        "prompt": "cinematic close-up portrait of a female detective with glowing mechanical cyberware eyes, reflections of neon lights in the rain, dramatic rim lighting, depth of field",
        "negative_prompt": "blurry, low quality, cartoon, bad eyes",
        "seed": 1002,
        "steps": 4
    },
    {
        "shot": 3,
        "title": "追踪追逐镜头",
        "prompt": "low angle dynamic motion tracking shot, sleek hover car speeding through an underground tunnel, motion blur, sparks, lens flare, film grain",
        "negative_prompt": "static, poor quality, bad lighting",
        "seed": 1003,
        "steps": 4
    }
]

def queue_prompt(prompt_workflow, server_address=COMFY_SERVER_URL):
    """向 ComfyUI /prompt 接口提交生成任务"""
    p = {"prompt": prompt_workflow}
    data = json.dumps(p).encode('utf-8')
    req = urllib.request.Request(f"{server_address}/prompt", data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.URLError as e:
        print(f"[错误] 无法连接到 ComfyUI 服务 ({server_address}): {e}")
        print("请确认 ComfyUI 是否正在运行，并在局域网内可以访问。")
        return None

def get_queue_status(server_address=COMFY_SERVER_URL):
    """获取当前任务排队状态"""
    try:
        with urllib.request.urlopen(f"{server_address}/queue") as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        return None

def main():
    print("=" * 65)
    print(f"       ComfyUI 局域网分镜提示词批量提交工具")
    print(f"   目标服务器: {COMFY_SERVER_URL}")
    print(f"   待分发镜头数: {len(STORYBOARDS)} 镜")
    print("=" * 65)

    # 1. 连通性测试
    status = get_queue_status()
    if status is None:
        print("[错误] 连接失败，请检查网络与服务启动状态。")
        sys.exit(1)
    
    running_count = len(status.get('queue_running', []))
    pending_count = len(status.get('queue_pending', []))
    print(f"✔ 成功连接！当前执行中任务: {running_count}, 队列等待中: {pending_count}\n")

    # 2. 读取 API 格式工作流模版
    # 提示：可以在 Web UI 右侧点击「设置」-> 勾选「Enable Dev mode Options」-> 点击「Save (API format)」导出
    workflow_template_path = "workflows/api_workflow_template.json"
    
    try:
        with open(workflow_template_path, 'r', encoding='utf-8') as f:
            workflow_template = json.load(f)
    except FileNotFoundError:
        print(f"[提示] 未找到 {workflow_template_path}，使用默认示例工作流演示提交流程。")
        workflow_template = None

    # 3. 遍历分镜批量派发
    for item in STORYBOARDS:
        print(f"--> 正在推送分镜 #{item['shot']} [{item['title']}]...")
        print(f"    Prompt: {item['prompt'][:60]}...")
        
        if workflow_template:
            # 深拷贝一份工作流，替换其中的提示词节点文本与种子
            # 注：不同工作流的节点 ID 会略有差异，通常找到 class_type 为 CLIPTextEncode 的节点替换即可
            job_workflow = json.loads(json.dumps(workflow_template))
            for node_id, node in job_workflow.items():
                # 匹配正向提示词节点
                if node.get("class_type") == "CLIPTextEncode" and "positive" in str(node.get("_meta", {})).lower():
                    node["inputs"]["text"] = item["prompt"]
                # 匹配采样器随机种子
                if "KSampler" in node.get("class_type", ""):
                    if "seed" in node.get("inputs", {}):
                        node["inputs"]["seed"] = item["seed"]
                    if "steps" in node.get("inputs", {}) and "steps" in item:
                        node["inputs"]["steps"] = item["steps"]
            
            res = queue_prompt(job_workflow)
            if res:
                prompt_id = res.get("prompt_id")
                print(f"    ✔ 成功入队！Prompt ID: {prompt_id}")
        else:
            print("    [演示模式] 工作流模板就绪后，此镜头将通过 /prompt 立即加入队列。")
        
        time.sleep(0.3)

    print("\n" + "=" * 65)
    print("🎉 所有分镜提示词已全部成功提交至 ComfyUI 队列！")
    print(f"Mac GPU 将依次渲染所有分镜，生成结果保存在 ComfyUI/output 目录。")
    print("=" * 65)

if __name__ == "__main__":
    main()
