#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 生产环境 - 构建并启动所有容器
# 功能: docker compose up -d --build 全量启动
# 使用 .env 文件作为容器环境变量 (host 指向 Docker 网络名)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 生产环境启动"
echo "========================================="

# ---------- 1. 前置检查 ----------
if ! command -v docker &>/dev/null; then
    echo "[ERROR] Docker 未安装"
    exit 1
fi

if [ ! -f .env ]; then
    echo "[ERROR] .env 文件不存在，请从 .env.example 复制并配置"
    exit 1
fi

# ---------- 2. 停止本地调试进程 (避免端口冲突) ----------
LOCAL_PIDS=$(lsof -ti :8000 2>/dev/null || true)
if [ -n "$LOCAL_PIDS" ]; then
    echo "[INFO] 检测到端口 8000 被占用，停止本地进程 ..."
    echo "$LOCAL_PIDS" | xargs kill -SIGTERM 2>/dev/null || true
    sleep 1
    echo "[OK] 本地进程已停止"
fi

# ---------- 3. 创建数据目录 ----------
mkdir -p data/qdrant data/ragflow

# ---------- 4. 启动所有服务 ----------
echo "[INFO] 构建并启动所有 Docker 服务 ..."
docker compose up -d --build "$@"

echo ""
echo "========================================="
echo "  启动完成!"
echo "========================================="
echo ""
echo "服务地址:"
echo "  Chainlit UI:       http://localhost:8000"
echo "  RAGFlow Web UI:    http://localhost:80"
echo "  RAGFlow API:       http://localhost:9380"
echo "  Qdrant Dashboard:  http://localhost:6333/dashboard"
echo "  MinIO Console:     http://localhost:9001"
echo ""
echo "查看日志: docker compose logs -f"
echo "停止服务: bash ops/prod-stop.sh"
