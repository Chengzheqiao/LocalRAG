#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 生产环境 - 构建所有 Docker 镜像
# 功能: 构建全部服务镜像 (不启动)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 生产镜像构建"
echo "========================================="

# ---------- 1. 前置检查 ----------
if ! command -v docker &>/dev/null; then
    echo "[ERROR] Docker 未安装"
    exit 1
fi

if [ ! -f docker-compose.yml ]; then
    echo "[ERROR] 未找到 docker-compose.yml"
    exit 1
fi

# 检查子模块
if [ ! -d vendor/ragflow/Dockerfile ] && [ ! -f vendor/ragflow/Dockerfile ]; then
    echo "[WARN] vendor/ragflow/Dockerfile 不存在"
    echo "       请先运行: git submodule update --init --recursive"
fi

# ---------- 2. 构建镜像 ----------
echo "[INFO] 构建所有 Docker 镜像 ..."
docker compose build "$@"

echo ""
echo "========================================="
echo "  构建完成!"
echo "========================================="
echo ""
echo "启动服务: bash ops/prod-start.sh"
