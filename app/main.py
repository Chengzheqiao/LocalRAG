"""
Chainlit 入口文件 - LocalRAG 聊天界面
"""

import logging

import chainlit as cl
from chainlit.input_widget import Tags

from graph import rag_graph
from utils.config import RAGFLOW_DATASET_IDS
from utils.ragflow_client import list_datasets

logger = logging.getLogger(__name__)


@cl.on_chat_start
async def on_chat_start():
    """聊天开始时的初始化: 拉取知识库列表并展示为下拉多选"""

    # 从 RAGFlow 拉取全部知识库
    datasets = await cl.make_async(list_datasets)()

    if not datasets:
        await cl.Message(
            content="你好！我是 LocalRAG 助手。\n"
            "(未能获取知识库列表，将使用默认配置)"
        ).send()
        cl.user_session.set("selected_dataset_ids", list(RAGFLOW_DATASET_IDS))
        return

    # 构建 name -> id 映射，保存到 session
    name_to_id = {ds.get("name", ds["id"]): ds["id"] for ds in datasets}
    cl.user_session.set("datasets", datasets)
    cl.user_session.set("name_to_id", name_to_id)

    all_names = list(name_to_id.keys())

    # 默认全部知识库预加载选中，用户删除不需要的即可
    cl.user_session.set(
        "selected_dataset_ids",
        [name_to_id[n] for n in all_names],
    )

    # 渲染设置面板: Tags 预加载全部知识库
    settings = cl.ChatSettings(
        [
            Tags(
                id="selected_datasets",
                label="知识库",
                values=all_names,
                initial=all_names,
                description="已加载全部知识库，删除不需要的即可",
            )
        ]
    )
    await settings.send()

    await cl.Message(
        content="你好！我是 LocalRAG 助手，可以根据技术文档回答问题。\n"
        f"当前已加载全部知识库 ({len(all_names)} 个): {', '.join(all_names)}\n"
        "点击左侧设置图标，删除不需要的知识库标签即可。"
    ).send()


@cl.on_settings_update
async def on_settings_update(settings: dict):
    """用户在下拉多选中变更知识库后，更新 session"""
    name_to_id = cl.user_session.get("name_to_id") or {}
    selected_names = settings.get("selected_datasets", [])

    selected_ids = [name_to_id[n] for n in selected_names if n in name_to_id]
    cl.user_session.set("selected_dataset_ids", selected_ids)

    label = ", ".join(selected_names) if selected_names else "无 (检索将跳过)"
    await cl.Message(content=f"知识库已切换: {label}").send()


@cl.on_message
async def on_message(message: cl.Message):
    """处理用户消息"""

    # 显示思考过程
    thinking_msg = cl.Message(content="正在检索相关文档...")
    await thinking_msg.send()

    # 获取当前 session 选中的知识库
    dataset_ids = cl.user_session.get("selected_dataset_ids") or list(
        RAGFLOW_DATASET_IDS
    )

    # 调用 LangGraph 状态机
    initial_state = {
        "question": message.content,
        "rewritten_question": "",
        "documents": [],
        "generation": "",
        "relevance_score": 0.0,
        "rewrite_count": 0,
        "web_search": False,
        "dataset_ids": dataset_ids,
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
