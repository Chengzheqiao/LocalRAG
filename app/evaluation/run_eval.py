"""
Ragas 离线评测脚本

功能:
  读取对话日志，使用 Ragas 计算 RAG 质量指标:
  - context_precision: 检索回来的文档到底有没有用
  - faithfulness: AI 回答是否基于文档生成

使用方式:
  python run_eval.py --input logs/conversations.json --output reports/eval_report.json
"""

import json
import argparse
from pathlib import Path

# from ragas import evaluate
# from ragas.metrics import context_precision, faithfulness, answer_relevancy
# from datasets import Dataset


def load_conversations(input_path: str) -> list:
    """
    从 JSON 文件加载对话记录。

    期望的数据格式:
    [
        {
            "question": "用户问题",
            "contexts": ["检索到的文档1", "检索到的文档2"],
            "answer": "AI 生成的回答",
            "ground_truth": "标准答案 (可选)"
        },
        ...
    ]
    """
    path = Path(input_path)
    if not path.exists():
        raise FileNotFoundError(f"对话记录文件不存在: {input_path}")

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    return data


def run_evaluation(conversations: list) -> dict:
    """
    使用 Ragas 对对话记录进行评测。

    Returns:
        评测结果字典
    """
    # TODO: 接入 Ragas 评测
    # dataset = Dataset.from_list(conversations)
    # result = evaluate(
    #     dataset,
    #     metrics=[context_precision, faithfulness, answer_relevancy],
    # )
    # return result.to_pandas().to_dict()

    # 占位: 返回空结果
    return {
        "context_precision": None,
        "faithfulness": None,
        "answer_relevancy": None,
        "num_samples": len(conversations),
        "status": "TODO - 请实现 Ragas 评测逻辑",
    }


def main():
    parser = argparse.ArgumentParser(description="LocalRAG Ragas 评测脚本")
    parser.add_argument(
        "--input",
        type=str,
        default="logs/conversations.json",
        help="对话记录 JSON 文件路径",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="reports/eval_report.json",
        help="评测结果输出路径",
    )
    args = parser.parse_args()

    print(f"加载对话记录: {args.input}")
    conversations = load_conversations(args.input)
    print(f"共加载 {len(conversations)} 条对话")

    print("开始评测...")
    results = run_evaluation(conversations)

    # 保存结果
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"评测完成，结果已保存到: {args.output}")
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
