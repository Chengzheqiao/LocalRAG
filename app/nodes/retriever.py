"""
Retrieval Node - 调用 RAGFlow API 执行文档检索
"""

import logging
from typing import Any, Dict

import httpx

from utils.config import RAGFLOW_API_KEY, RAGFLOW_BASE_URL, RAGFLOW_DATASET_IDS

logger = logging.getLogger(__name__)

# 检索返回的最大文档片段数
_TOP_K = 5


def retrieve(state: Dict[str, Any]) -> Dict[str, Any]:
    """
    通过 RAGFlow /api/v1/retrieval 检索与问题相关的文档切片。
    优先使用重写后的问题 (如果有的话)。

    Args:
        state: 包含 question / rewritten_question 的状态字典

    Returns:
        更新后的 state，包含 documents 字段
    """
    query = state.get("rewritten_question") or state["question"]

    if not RAGFLOW_DATASET_IDS:
        logger.warning("RAGFLOW_DATASET_IDS 未配置，跳过检索")
        return {**state, "documents": []}

    try:
        resp = httpx.post(
            f"{RAGFLOW_BASE_URL}/api/v1/retrieval",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {RAGFLOW_API_KEY}",
            },
            json={
                "question": query,
                "dataset_ids": RAGFLOW_DATASET_IDS,
                "top_k": _TOP_K,
            },
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        logger.error("RAGFlow 检索失败: %s", e)
        return {**state, "documents": []}

    chunks = data.get("data", {}).get("chunks", [])
    documents = [
        {
            "content": c.get("content", ""),
            "document_name": c.get("document_name", ""),
            "similarity": c.get("similarity", 0.0),
        }
        for c in chunks
    ]
    logger.info("RAGFlow 检索到 %d 个文档片段", len(documents))
    return {**state, "documents": documents}
