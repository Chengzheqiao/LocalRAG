"""
Chainlit 入口文件 - LocalRAG 聊天界面
"""

import chainlit as cl
from graph import rag_graph


@cl.on_chat_start
async def on_chat_start():
    """聊天开始时的初始化"""
    await cl.Message(
        content="你好！我是 LocalRAG 助手，可以根据你的技术文档回答问题。请输入你的问题。"
    ).send()


@cl.on_message
async def on_message(message: cl.Message):
    """处理用户消息"""

    # 显示思考过程
    thinking_msg = cl.Message(content="正在检索相关文档...")
    await thinking_msg.send()

    # 调用 LangGraph 状态机
    initial_state = {
        "question": message.content,
        "rewritten_question": "",
        "documents": [],
        "generation": "",
        "relevance_score": 0.0,
        "rewrite_count": 0,
        "web_search": False,
    }

    # 执行 Graph (异步)
    result = await cl.make_async(rag_graph.invoke)(initial_state)

    # 更新思考消息为最终回答
    await thinking_msg.remove()

    # 发送最终回答
    answer = result.get("generation", "抱歉，未能生成回答。")
    await cl.Message(content=answer).send()


@cl.on_chat_end
async def on_chat_end():
    """
    聊天结束时保存对话记录，用于后续 Ragas 评测。
    """
    # TODO: 将对话记录 (Question, Contexts, Answer) 保存到 JSON/SQLite
    pass
