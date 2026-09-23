#!/usr/bin/env python3
"""
.si 权威根服务器毫秒级域名可用性极速扫描器
==============================================================================
原理：
直接向斯洛文尼亚官方权威根 DNS 服务器 (b.dns.si / f.dns.si) 发送查询。
- 返回 NXDOMAIN：100% 确定未注册（立即可买！）
- 返回 NOERROR：已注册（占用）
无需走任何经过限流的 HTTP/RDAP 接口，零延迟、权威无误报。
"""

import sys
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# 颜色定义
GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"

# 斯洛文尼亚官方权威根服务器
SI_NAMESERVER = "b.dns.si"

# 针对 Super Intelligence (超级智能) 维度筛选的精品 .si 候选池
SI_TARGETS = [
    # 1. 超级智能核心前沿概念
    "safesuperintelligence.si", "superalignment.si", "worldmodels.si", "worldmodel.si",
    "diffusionmodel.si", "diffusionmodels.si", "agenticai.si", "embodiedai.si",
    "multimodalai.si", "reasoningai.si", "reasoningmodel.si", "reasoningmodels.si",
    "chainofthought.si", "selfimproving.si", "neurosymbolic.si", "prompting.si",
    "finetune.si", "pretrain.si", "distill.si", "quantize.si", "tokenize.si", "orchestrate.si",

    # 2. Super + 核心科技词 (打造超级智能产品/平台)
    "superagent.si", "supermind.si", "superbrain.si", "supermodel.si",
    "supercompute.si", "supernetwork.si", "supercluster.si", "superfoundry.si",
    "superfactory.si", "superstack.si", "superplatform.si", "superengine.si",
    "supercoder.si", "superhumanai.si", "supervision.si", "supervoice.si",
    "superdata.si", "supercore.si", "superlogic.si", "supersoftware.si",
    "supertools.si", "supercopilot.si", "superassistant.si", "supersystems.si",
    "supercloud.si", "supersmart.si", "superagi.si",

    # 3. 顶级智能机构/实验室命名
    "openintelligence.si", "deepintelligence.si", "trueintelligence.si",
    "nextintelligence.si", "futureintelligence.si", "humanintelligence.si",
    "autonomousagent.si", "generalai.si", "syntheticai.si", "omnimodel.si",
    "omniagent.si", "worldagent.si", "mindagent.si", "digitalmind.si",
    "digitalhuman.si", "siliconmind.si", "syntheticmind.si",

    # 4. 垂直产业赋能 (行业 + SI)
    "biotech.si", "genomics.si", "robotics.si", "semiconductor.si",
    "aerospace.si", "neuro.si", "cybersecurity.si", "quantumcomputing.si",
    "syntheticbiology.si", "pharmacology.si", "financeai.si", "legalai.si",
    "medai.si", "codeai.si", "robotai.si",

    # 5. 精简前缀/双音节词汇 + .si
    "hyperai.si", "ultraai.si", "nextai.si", "pureai.si", "realai.si",
    "coreai.si", "baseai.si", "flowai.si", "devai.si", "labai.si",
    "runai.si", "appai.si", "mindai.si", "agentai.si"
]

def check_si_domain_authority(domain):
    """直接查询权威服务器，判断是否为 NXDOMAIN (可注册)"""
    if not domain.endswith(".si"):
        domain = domain + ".si"
    
    cmd = ["dig", f"@{SI_NAMESERVER}", domain, "NS", "+noall", "+comments"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
        out = proc.stdout
        if "status: NXDOMAIN" in out:
            return {"domain": domain, "available": True, "status": "Available (NXDOMAIN)"}
        elif "status: NOERROR" in out:
            return {"domain": domain, "available": False, "status": "Registered"}
        else:
            return {"domain": domain, "available": None, "status": "CheckManually"}
    except Exception as e:
        return {"domain": domain, "available": None, "status": f"Err: {e}"}

def main():
    targets = SI_TARGETS
    if len(sys.argv) > 1:
        targets = [d.strip() for d in sys.argv[1:]]

    print(f"{CYAN}{'='*75}{NC}")
    print(f"{BOLD}   .si (Super Intelligence) 权威根服务器极速可用性扫描器{NC}")
    print(f"   权威根解析服务器: {SI_NAMESERVER} | 扫描总数: {len(targets)} 个")
    print(f"{CYAN}{'='*75}{NC}\n")

    available_list = []
    registered_count = 0

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=10) as executor:
        future_to_domain = {executor.submit(check_si_domain_authority, d): d for d in targets}
        for future in as_completed(future_to_domain):
            res = future.result()
            domain = res["domain"]
            if res["available"] is True:
                available_list.append(domain)
                print(f"  {GREEN}[可直接购买 🟢]{NC}  {BOLD}{domain:<28}{NC}  -> 立即注册！")
            elif res["available"] is False:
                registered_count += 1
                # print(f"  {RED}[已被占用 🔴]{NC}  {domain:<28}")
            else:
                print(f"  {YELLOW}[需人工复核 ⚪]{NC}  {domain:<28}  -> {res['status']}")

    duration = time.time() - start_time
    print(f"\n{CYAN}{'='*75}{NC}")
    print(f"{BOLD}                        扫描完成统计{NC}")
    print(f"{CYAN}{'='*75}{NC}")
    print(f"  耗时: {duration:.2f} 秒")
    print(f"  已注册占用: {registered_count} 个")
    print(f"  {GREEN}{BOLD}当前确定可注册购买: {len(available_list)} 个{NC}")
    print(f"{CYAN}{'='*75}{NC}\n")

    if available_list:
        print(f"{GREEN}{BOLD}🎉 以下是当前实测 100% 确定未注册的顶级 .si 域名：{NC}\n")
        # 按字母排序展示
        for idx, dom in enumerate(sorted(available_list), 1):
            reg_url = f"https://www.namecheap.com/domains/registration/results/?domain={dom}"
            print(f"  {idx:2d}. 👉 {BOLD}{dom:<26}{NC} (注册直达: {reg_url})")
        print()

if __name__ == "__main__":
    main()
