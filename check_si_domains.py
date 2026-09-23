#!/usr/bin/env python3
"""
SI (Super Intelligence) 潜力域名批量自动查询与投资筛选工具
==============================================================================
原理：
1. 本地 DNS SOA/NS 预检（毫秒级过滤已解析域名）
2. ICANN 标准 RDAP 协议精确校验（检测 404 未注册 vs 200 已注册）
3. 聚合输出可购买域名报告与注册直达链接
"""

import sys
import socket
import urllib.request
import urllib.error
import json
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# 终端色彩定义
GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"

# ==============================================================================
# 精选 SI (Super Intelligence / 超级智能) 潜力候选域名库
# ==============================================================================
DEFAULT_CANDIDATES = [
    # 1. 核心大模型与超级智能概念 (.si 国别域，对标 .ai)
    "super.si", "open.si", "safe.si", "deep.si", "omni.si",
    "agent.si", "mind.si", "brain.si", "neural.si", "cortex.si",
    "nexus.si", "core.si", "hyper.si", "meta.si", "matrix.si",
    "prime.si", "sentient.si", "singularity.si", "agi.si",

    # 2. 动词 / 开发者与工程高频词 (.si)
    "run.si", "dev.si", "build.si", "flow.si", "train.si",
    "chat.si", "bot.si", "eval.si", "cloud.si", "hub.si",
    "lab.si", "api.si", "app.si", "box.si", "node.si",

    # 3. 垂直专业领域 (.si)
    "med.si", "bio.si", "law.si", "code.si", "fin.si",
    "math.si", "gene.si", "quantum.si", "robot.si", "chip.si",

    # 4. 品牌词组合: SI 前缀 (.com / .org / .ai)
    "siagent.com", "siagents.com", "sicore.com", "simodel.com",
    "simodels.com", "silabs.ai", "siresearch.com", "sinetwork.com",
    "sihub.com", "sipower.com", "siengine.com", "sicompute.com",

    # 5. 品牌词组合: SI 后缀 / 短语 (.com / .org)
    "opensi.org", "safesi.org", "nextsi.com", "truesi.com",
    "futuresi.com", "omnesi.com", "puresi.com", "deepsi.com",
    "humansi.com", "hypersi.com", "metasi.com", "primesi.com",
]

def check_dns_has_records(domain):
    """通过 socket 检查域名是否已解析（若有 IP 则必已被注册）"""
    try:
        socket.gethostbyname(domain)
        return True  # 有解析，必然已注册
    except (socket.gaierror, socket.herror):
        return False  # 无 A 记录，需进一步 RDAP 校验

def check_rdap_availability(domain, timeout=5):
    """
    通过 ICANN RDAP 协议精确核验注册状态:
    HTTP 404 -> 未被注册（可买）
    HTTP 200 -> 已注册
    """
    url = f"https://rdap.org/domain/{domain}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (DomainChecker/1.0; +https://rdap.org)"}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if resp.status == 200:
                return {"domain": domain, "available": False, "status": "Registered"}
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return {"domain": domain, "available": True, "status": "Available"}
        elif e.code == 429:
            return {"domain": domain, "available": None, "status": "RateLimited"}
        else:
            return {"domain": domain, "available": None, "status": f"HTTP {e.code}"}
    except Exception as e:
        return {"domain": domain, "available": None, "status": f"Err: {type(e).__name__}"}

    return {"domain": domain, "available": None, "status": "Unknown"}

def inspect_domain(domain):
    """综合检测"""
    # 快速过滤：如果有直接可解析的 A 记录，100% 已被注册使用
    if check_dns_has_records(domain):
        return {"domain": domain, "available": False, "status": "Registered (Active DNS)"}
    
    # 深度 RDAP 校验
    result = check_rdap_availability(domain)
    # 若 RDAP 被限流或超时，重试一次
    if result["available"] is None and "RateLimited" in result["status"]:
        time.sleep(1.5)
        result = check_rdap_availability(domain)
    return result

def main():
    print(f"{CYAN}{'='*75}{NC}")
    print(f"{BOLD}    SI (Super Intelligence / 超级智能) 域名投资筛选与可用性查询器{NC}")
    print(f"{CYAN}{'='*75}{NC}")

    domains_to_check = DEFAULT_CANDIDATES
    if len(sys.argv) > 1:
        # 用户通过命令行传入自定义域名
        domains_to_check = [d.strip() for d in sys.argv[1:] if "." in d]
        print(f"模式: 自定义查询指定 {len(domains_to_check)} 个域名\n")
    else:
        print(f"模式: 批量扫描精选候选库 (共 {len(domains_to_check)} 个高潜力域名)")
        print(f"涵盖: .si 国别顶级域、SI+核心词.com、超级智能生态命名\n")

    print(f"正在进行多线程高并发 RDAP 验证，请稍候...\n")

    available_list = []
    registered_count = 0
    unknown_count = 0

    # 保持温和并发，避免触发公共 RDAP 频控
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(inspect_domain, d): d for d in domains_to_check}
        for fut in as_completed(futures):
            res = fut.result()
            d = res["domain"]
            status = res["status"]
            avail = res["available"]

            if avail is True:
                available_list.append(d)
                print(f"  {GREEN}[可购买 🟢]{NC} {BOLD}{d:<22}{NC}  -> 立即注册")
            elif avail is False:
                registered_count += 1
                print(f"  {RED}[已注册 🔴]{NC} {d:<22}  -> {status}")
            else:
                unknown_count += 1
                print(f"  {YELLOW}[待复核 ⚪]{NC} {d:<22}  -> {status}")
            
            # 微小休眠保障稳定性
            time.sleep(0.15)

    print(f"\n{CYAN}{'='*75}{NC}")
    print(f"{BOLD}                   扫描完成总结报告{NC}")
    print(f"{CYAN}{'='*75}{NC}")
    print(f"  总计扫描: {len(domains_to_check)} 个")
    print(f"  已被抢注: {registered_count} 个")
    print(f"  {GREEN}当前可购买: {len(available_list)} 个{NC}")
    if unknown_count > 0:
        print(f"  {YELLOW}需人工复核: {unknown_count} 个{NC}")

    if available_list:
        print(f"\n{GREEN}{BOLD}🎉 以下是可以直接注册的高价值 SI 域名：{NC}")
        for item in sorted(available_list):
            if item.endswith(".si"):
                reg_url = f"https://www.namecheap.com/domains/registration/results/?domain={item} 或 https://register.si"
            else:
                reg_url = f"https://www.porkbun.com/checkout/search?q={item}"
            print(f"  👉 {BOLD}{item:<20}{NC} | 注册通道: {reg_url}")
        
        # 导出为 JSON 方便持久保存
        report_file = "available_si_domains.json"
        with open(report_file, "w", encoding="utf-8") as f:
            json.dump({
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                "available_domains": available_list
            }, f, indent=2)
        print(f"\n结果已保存至本地文件：{report_file}")
    else:
        print(f"\n提示：候选库中的极品硬核单字大多已被注册，建议探索组合词或使用脚本追加新词库。")

    print(f"{CYAN}{'='*75}{NC}\n")

if __name__ == "__main__":
    main()
