"""
LangGraph 状态机定义 - RAG 核心流程

状态流转:
  问题 -> [Rewrite] -> Retrieve -> Grade
                                     |
                          低分 -> Rewrite (循环)
                          高分 -> Generate -> 回答
"""

from typing import Any, Dict, List, TypedDict
from langgraph.graph import StateGraph, END

from nodes.retriever import retrieve
from nodes.generator import generate
from nodes.grader import grade_documents
from nodes.rewriter import rewrite_query
from utils.config import RELEVANCE_THRESHOLD, MAX_REWRITE_ATTEMPTS


# ===== 状态定义 =====

class GraphState(TypedDict):
    question: str                    # 原始问题
    rewritten_question: str          # 重写后的检索问题
    documents: List[Any]             # 检索到的文档切片
    generation: str                  # 最终生成的答案
    relevance_score: float           # 文档相关性得分
    rewrite_count: int               # 重写次数计数器
    web_search: bool                 # 是否需要联网搜索 (可选扩展)
    dataset_ids: List[str]           # 动态指定的知识库 ID 列表


# ===== 条件边: 判断是否需要重写 =====

def should_rewrite(state: Dict[str, Any]) -> str:
    """
    根据 Grader 的评分和重写次数决定下一步:
    - 得分低且未超过最大重写次数 -> rewrite
    - 得分高或已达到最大重写次数 -> generate
    """
    score = state.get("relevance_score", 0.0)
    rewrite_count = state.get("rewrite_count", 0)

    if score < RELEVANCE_THRESHOLD and rewrite_count < MAX_REWRITE_ATTEMPTS:
        return "rewrite"
    return "generate"


# ===== 构建 Graph =====

def build_graph() -> StateGraph:
    """
    构建 LangGraph 状态机。

    Returns:
        编译后的 StateGraph 实例
    """
    workflow = StateGraph(GraphState)

    # 添加节点
    workflow.add_node("rewrite", rewrite_query)
    workflow.add_node("retrieve", retrieve)
    workflow.add_node("grade", grade_documents)
    workflow.add_node("generate", generate)

    # 定义边
    workflow.set_entry_point("retrieve")

    workflow.add_edge("retrieve", "grade")

    # 条件边: grade 之后根据得分决定走向
    workflow.add_conditional_edges(
        "grade",
        should_rewrite,
        {
            "rewrite": "rewrite",
            "generate": "generate",
        },
    )

    workflow.add_edge("rewrite", "retrieve")
    workflow.add_edge("generate", END)

    return workflow.compile()


# 全局单例
rag_graph = build_graph()
