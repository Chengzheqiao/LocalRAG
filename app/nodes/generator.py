"""
Generation Node - 调用 Qwen API 生成最终回答
"""

from typing import Any, Dict

from utils.llm import call_qwen

# Qwen 生成的 System Prompt
SYSTEM_PROMPT = """你是一个专业的技术文档助手。请根据以下提供的参考文档内容，准确回答用户的问题。
如果参考文档中没有相关信息，请如实告知用户。不要编造信息。

参考文档:
{context}
"""


def generate(state: Dict[str, Any]) -> Dict[str, Any]:
    """
    拼接 Prompt 并调用 Qwen 生成最终回答。

    Args:
        state: 包含 question 和 documents 的状态字典

    Returns:
        更新后的 state，包含 generation 字段
    """
    question = state["question"]
    documents = state.get("documents", [])

    # 拼接检索到的文档内容作为 context
    context = "\n\n---\n\n".join(
        doc["content"] if isinstance(doc, dict) else str(doc)
        for doc in documents
    )

    if not context:
        context = "(无相关文档)"

    answer = call_qwen(
        system_prompt=SYSTEM_PROMPT.format(context=context),
        user_prompt=question,
    )

    return {**state, "generation": answer}
