#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 初始化脚本"
echo "========================================="

# 1. 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker 未安装，请先安装 Docker Desktop"
    exit 1
fi

if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "[ERROR] Docker Compose 不可用，请确认安装了 Docker Compose V2"
    exit 1
fi

echo "[OK] Docker 环境检查通过"

# 2. 初始化 Git 子模块
if [ -f .gitmodules ]; then
    echo "[INFO] 初始化 Git 子模块..."
    git submodule update --init --recursive
    echo "[OK] 子模块初始化完成"
else
    echo "[WARN] 未检测到 .gitmodules，跳过子模块初始化"
    echo "       请先执行:"
    echo "         git submodule add <RAGFlow fork URL> vendor/ragflow"
    echo "         git submodule add <Ragas fork URL> vendor/ragas"
fi

# 3. 创建环境变量文件
if [ ! -f .env ]; then
    cp .env.example .env
    echo "[OK] 已从 .env.example 创建 .env，请编辑填入你的 API Key"
else
    echo "[OK] .env 已存在，跳过"
fi

# 4. 创建数据持久化目录
mkdir -p data/qdrant data/ragflow
echo "[OK] 数据目录已创建"

echo ""
echo "========================================="
echo "  初始化完成!"
echo "========================================="
echo ""
echo "下一步:"
echo "  1. 编辑 .env 填入你的 API Key"
echo "  2. 运行 make up 启动所有服务"
