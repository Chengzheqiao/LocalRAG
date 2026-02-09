"""
Rewriter Node - 将用户口语化的问题重写为利于检索的 Query
"""

import logging
from typing import Any, Dict

from utils.llm import call_qwen

logger = logging.getLogger(__name__)

REWRITE_SYSTEM = "你是一个搜索查询优化专家。请将用户问题重写为更适合向量检索的查询语句。保留核心语义，使用精确术语，去除口语化表达，只输出优化后的查询，不要输出其他内容。"

REWRITE_USER = "用户原始问题: {question}"


def rewrite_query(state: Dict[str, Any]) -> Dict[str, Any]:
    """
    调用 LLM 将用户问题重写为更适合向量检索的 Query。
    同时记录重写次数，防止无限循环。

    Args:
        state: 包含 question 的状态字典

    Returns:
        更新后的 state，包含 rewritten_question 和 rewrite_count
    """
    question = state["question"]
    rewrite_count = state.get("rewrite_count", 0) + 1

    try:
        rewritten = call_qwen(
            system_prompt=REWRITE_SYSTEM,
            user_prompt=REWRITE_USER.format(question=question),
        )
    except Exception as e:
        logger.warning("重写失败，使用原始问题: %s", e)
        rewritten = question

    logger.info("Query 重写 (v%d): %s -> %s", rewrite_count, question, rewritten)

    return {
        **state,
        "rewritten_question": rewritten,
        "rewrite_count": rewrite_count,
    }
