"""
RAGFlow API 客户端 - 提供知识库管理接口
"""

import logging
from typing import Any, Dict, List

import httpx

from utils.config import RAGFLOW_API_KEY, RAGFLOW_BASE_URL

logger = logging.getLogger(__name__)


def list_datasets() -> List[Dict[str, Any]]:
    """
    获取 RAGFlow 中所有知识库列表。

    Returns:
        知识库列表，每项包含 id, name, description 等字段。
        失败时返回空列表。
    """
    try:
        resp = httpx.get(
            f"{RAGFLOW_BASE_URL}/api/v1/datasets",
            headers={"Authorization": f"Bearer {RAGFLOW_API_KEY}"},
            params={"page": 1, "page_size": 100},
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()
        datasets = data.get("data", [])
        logger.info("获取到 %d 个知识库", len(datasets))
        return datasets
    except Exception as e:
        logger.error("获取知识库列表失败: %s", e)
        return []
