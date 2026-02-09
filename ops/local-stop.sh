#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 本地调试停止
# 功能: 终止本地运行的 Chainlit 进程
# ============================================================

PORT="${CHAINLIT_PORT:-8000}"

echo "========================================="
echo "  LocalRAG 本地调试停止"
echo "========================================="

# 查找占用目标端口的进程
PIDS=$(lsof -ti :"$PORT" 2>/dev/null || true)

if [ -n "$PIDS" ]; then
    echo "[INFO] 发现占用端口 $PORT 的进程: $PIDS"
    echo "$PIDS" | xargs kill -SIGTERM 2>/dev/null || true
    sleep 1

    # 检查是否仍在运行
    REMAINING=$(lsof -ti :"$PORT" 2>/dev/null || true)
    if [ -n "$REMAINING" ]; then
        echo "[WARN] 进程未响应 SIGTERM，发送 SIGKILL ..."
        echo "$REMAINING" | xargs kill -9 2>/dev/null || true
    fi

    echo "[OK] 本地 Chainlit 已停止"
else
    echo "[OK] 端口 $PORT 上无运行中的进程"
fi
