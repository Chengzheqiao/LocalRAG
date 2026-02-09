#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 生产环境 - 停止所有容器
# 用法:
#   bash ops/prod-stop.sh           # 停止所有容器 (保留数据卷)
#   bash ops/prod-stop.sh --clean   # 停止并删除数据卷
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 生产环境停止"
echo "========================================="

if [[ "${1:-}" == "--clean" ]]; then
    echo "[WARN] 将停止所有容器并删除数据卷!"
    read -p "确认? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker compose down -v
        echo "[OK] 所有容器已停止，数据卷已删除"
    else
        echo "[INFO] 已取消"
        exit 0
    fi
else
    docker compose down
    echo "[OK] 所有容器已停止 (数据卷已保留)"
fi
