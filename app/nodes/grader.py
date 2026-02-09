"""
Grader Node - 判断检索到的文档是否与问题相关
"""

import logging
from typing import Any, Dict

from utils.config import RELEVANCE_THRESHOLD
from utils.llm import call_qwen

logger = logging.getLogger(__name__)

# 评分 Prompt: 让 LLM 判断文档与问题的相关性
GRADER_SYSTEM = "你是一个文档相关性评估专家。只需回答一个 0 到 1 之间的数字，表示文档与问题的相关性。1 表示完全相关，0 表示完全不相关。只输出数字，不要输出其他内容。"

GRADER_USER = """用户问题: {question}

文档内容: {document}

相关性得分 (0-1):"""


def _parse_score(text: str) -> float:
    """从 LLM 返回中提取 0-1 之间的浮点数"""
    import re
    match = re.search(r"([01](?:\.\d+)?)", text)
    return float(match.group(1)) if match else 0.0


def grade_documents(state: Dict[str, Any]) -> Dict[str, Any]:
    """
    对检索到的文档逐一评分，过滤低相关性文档。
    如果所有文档得分都低于阈值，标记需要重写。

    Args:
        state: 包含 question 和 documents 的状态字典

    Returns:
        更新后的 state，包含过滤后的 documents 和 relevance_score
    """
    question = state["question"]
    documents = state.get("documents", [])

    if not documents:
        return {**state, "documents": [], "relevance_score": 0.0}

    filtered_docs = []
    scores = []
    for doc in documents:
        content = doc["content"] if isinstance(doc, dict) else str(doc)
        try:
            raw = call_qwen(
                system_prompt=GRADER_SYSTEM,
                user_prompt=GRADER_USER.format(question=question, document=content),
            )
            score = _parse_score(raw)
        except Exception as e:
            logger.warning("评分失败，默认通过: %s", e)
            score = 1.0
        scores.append(score)
        if score >= RELEVANCE_THRESHOLD:
            filtered_docs.append(doc)

    avg_score = sum(scores) / len(scores) if scores else 0.0
    logger.info("评分完成: %d/%d 文档通过 (avg=%.2f)", len(filtered_docs), len(documents), avg_score)

    return {
        **state,
        "documents": filtered_docs,
        "relevance_score": avg_score,
    }
