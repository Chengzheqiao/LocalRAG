#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 本地调试启动
# 前提: 基础容器 (Qdrant + RAGFlow 及依赖) 已运行
# 功能: 停止 app 容器 -> 检查基础容器 -> 启动本地 Chainlit
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CONDA_ENV_NAME="localrag"
HOST="${CHAINLIT_HOST:-127.0.0.1}"
PORT="${CHAINLIT_PORT:-8000}"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 本地调试启动"
echo "========================================="

# ---------- 1. 定位 conda 环境 ----------
CONDA_PREFIX="$(conda info --envs 2>/dev/null | grep "$CONDA_ENV_NAME" | awk '{print $NF}')" || true

if [ -z "$CONDA_PREFIX" ] || [ ! -d "$CONDA_PREFIX" ]; then
    echo "[ERROR] 未找到 conda 环境 '$CONDA_ENV_NAME'"
    echo "        请先运行: bash ops/local-setup.sh"
    exit 1
fi

CHAINLIT="$CONDA_PREFIX/bin/chainlit"
PYTHON="$CONDA_PREFIX/bin/python"

if [ ! -f "$CHAINLIT" ]; then
    echo "[ERROR] 未找到 $CHAINLIT，依赖可能未安装"
    echo "        请先运行: bash ops/local-setup.sh"
    exit 1
fi

# ---------- 2. 停止 app 容器 (避免端口冲突) ----------
if docker compose ps --format json 2>/dev/null | grep -q '"app"'; then
    echo "[INFO] 停止 app 容器以避免端口 $PORT 冲突 ..."
    docker compose stop app 2>/dev/null || true
    echo "[OK] app 容器已停止"
else
    echo "[OK] app 容器未运行，无需停止"
fi

# ---------- 3. 检查基础容器 ----------
check_container() {
    local name="$1"
    local display="$2"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$name"; then
        echo "[OK] $display 运行中"
    else
        echo "[WARN] $display ($name) 未运行"
    fi
}

echo ""
echo "[INFO] 基础容器状态:"
check_container "ragflow"       "RAGFlow"
check_container "redis"         "Redis"
check_container "es"            "Elasticsearch"
check_container "minio"         "MinIO"
echo ""

# ---------- 4. 检查 .env_localtest ----------
if [ ! -f "$PROJECT_ROOT/.env_localtest" ]; then
    echo "[WARN] .env_localtest 不存在，config.py 将回退到 .env"
    echo "       本地调试建议创建 .env_localtest (host 指向 localhost)"
fi

# ---------- 5. 启动 Chainlit ----------
echo "[INFO] 启动 Chainlit (http://$HOST:$PORT) ..."
echo "[INFO] 使用 Python: $PYTHON"
echo "[INFO] 按 Ctrl+C 停止"
echo ""

cd "$PROJECT_ROOT/app"
exec "$CHAINLIT" run main.py --host "$HOST" --port "$PORT"
