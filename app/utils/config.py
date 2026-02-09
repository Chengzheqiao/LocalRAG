"""
统一配置加载模块
从 .env 文件和环境变量中读取所有配置项

加载优先级:
  1. .env_localtest (本地调试，host 指向 localhost)
  2. .env           (容器部署，host 指向 Docker 内部网络名)
  Docker 容器中通过 env_file 直接注入环境变量，两个文件均不会生效。
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# 项目根目录 (app/utils/config.py -> 向上两级到项目根)
_project_root = Path(__file__).resolve().parent.parent.parent

_local_env = _project_root / ".env_localtest"
if _local_env.exists():
    load_dotenv(_local_env)
else:
    load_dotenv(_project_root / ".env")


# ===== LLM 配置 =====
QWEN_API_KEY: str = os.getenv("QWEN_API_KEY", "")
QWEN_MODEL_NAME: str = os.getenv("QWEN_MODEL_NAME", "qwen-plus")

# ===== RAGFlow 配置 =====
RAGFLOW_API_KEY: str = os.getenv("RAGFLOW_API_KEY", "")
RAGFLOW_BASE_URL: str = os.getenv("RAGFLOW_BASE_URL", "http://localhost:9380")
RAGFLOW_DATASET_IDS: list = [
    s.strip()
    for s in os.getenv("RAGFLOW_DATASET_IDS", "").split(",")
    if s.strip()
]

# ===== Grader 阈值 =====
RELEVANCE_THRESHOLD: float = float(os.getenv("RELEVANCE_THRESHOLD", "0.7"))

# ===== 最大重写次数 (防止无限循环) =====
MAX_REWRITE_ATTEMPTS: int = int(os.getenv("MAX_REWRITE_ATTEMPTS", "3"))
