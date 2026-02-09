"""
共用 Qwen LLM 调用模块
通过 OpenAI 兼容接口访问通义千问
"""

from openai import OpenAI

from utils.config import QWEN_API_KEY, QWEN_MODEL_NAME

_client = OpenAI(
    api_key=QWEN_API_KEY,
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
)


def call_qwen(system_prompt: str, user_prompt: str) -> str:
    """
    调用 Qwen API 返回文本。

    Args:
        system_prompt: 系统角色提示词
        user_prompt:   用户输入

    Returns:
        模型生成的文本
    """
    response = _client.chat.completions.create(
        model=QWEN_MODEL_NAME,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    )
    return response.choices[0].message.content.strip()
