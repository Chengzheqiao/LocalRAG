#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 云环境调试启动
# 场景: 中间件 (RAGFlow/ES/Redis/MinIO) 运行在阿里云 ECS
#       本地仅运行 App (Chainlit + LangGraph)
# 前提: 阿里云 ECS 上已通过 docker-compose 拉起 RAGFlow 全套服务
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CONDA_ENV_NAME="localrag"
HOST="${CHAINLIT_HOST:-127.0.0.1}"
PORT="${CHAINLIT_PORT:-8000}"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  LocalRAG 云环境调试启动"
echo "========================================="

# ---------- 1. 检查 .env_clouddev ----------
if [ ! -f "$PROJECT_ROOT/.env_clouddev" ]; then
    echo "[ERROR] .env_clouddev 不存在"
    echo "        请先从 .env.example 创建 .env_clouddev 并填入阿里云 ECS IP"
    exit 1
fi

# 检查是否还有占位符未替换
if grep -q '<ECS_PUBLIC_IP>' "$PROJECT_ROOT/.env_clouddev"; then
    echo "[ERROR] .env_clouddev 中仍存在 <ECS_PUBLIC_IP> 占位符"
    echo "        请替换为实际的阿里云 ECS 公网 IP 地址"
    exit 1
fi

echo "[OK] .env_clouddev 已配置"

# ---------- 2. 定位 conda 环境 ----------
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

# ---------- 3. 停止本地容器 (避免端口冲突) ----------
if docker compose ps --format json 2>/dev/null | grep -q '"app"'; then
    echo "[INFO] 停止本地 app 容器以避免端口 $PORT 冲突 ..."
    docker compose stop app 2>/dev/null || true
    echo "[OK] app 容器已停止"
else
    echo "[OK] app 容器未运行，无需停止"
fi

# ---------- 4. 连通性检查 (阿里云 ECS) ----------
# 从 .env_clouddev 提取 RAGFLOW_BASE_URL
RAGFLOW_URL=$(grep '^RAGFLOW_BASE_URL=' "$PROJECT_ROOT/.env_clouddev" | cut -d'=' -f2-)
ES_HOST_VAL=$(grep '^ES_HOST=' "$PROJECT_ROOT/.env_clouddev" | cut -d'=' -f2-)
ES_PORT_VAL=$(grep '^ES_PORT=' "$PROJECT_ROOT/.env_clouddev" | cut -d'=' -f2-)
REDIS_HOST_VAL=$(grep '^REDIS_HOST=' "$PROJECT_ROOT/.env_clouddev" | cut -d'=' -f2-)
REDIS_PORT_VAL=$(grep '^REDIS_PORT=' "$PROJECT_ROOT/.env_clouddev" | cut -d'=' -f2-)

echo ""
echo "[INFO] 阿里云 ECS 服务连通性检查:"

check_url() {
    local name="$1"
    local url="$2"
    if curl -sf --connect-timeout 5 "$url" >/dev/null 2>&1; then
        echo "[OK] $name ($url) 可达"
    else
        echo "[WARN] $name ($url) 不可达，请确认 ECS 服务已启动且安全组已放行端口"
    fi
}

check_tcp() {
    local name="$1"
    local host="$2"
    local port="$3"
    if nc -z -w 5 "$host" "$port" 2>/dev/null; then
        echo "[OK] $name ($host:$port) 可达"
    else
        echo "[WARN] $name ($host:$port) 不可达，请确认 ECS 服务已启动且安全组已放行端口"
    fi
}

if [ -n "$RAGFLOW_URL" ]; then
    check_url "RAGFlow API" "$RAGFLOW_URL/api/v1/datasets"
fi
if [ -n "$ES_HOST_VAL" ] && [ -n "$ES_PORT_VAL" ]; then
    check_tcp "Elasticsearch" "$ES_HOST_VAL" "$ES_PORT_VAL"
fi
if [ -n "$REDIS_HOST_VAL" ] && [ -n "$REDIS_PORT_VAL" ]; then
    check_tcp "Redis" "$REDIS_HOST_VAL" "$REDIS_PORT_VAL"
fi

echo ""

# ---------- 5. 启动 Chainlit ----------
echo "[INFO] 启动 Chainlit (http://$HOST:$PORT) ..."
echo "[INFO] 使用 Python: $PYTHON"
echo "[INFO] 中间件指向: 阿里云 ECS"
echo "[INFO] 按 Ctrl+C 停止"
echo ""

cd "$PROJECT_ROOT/app"
exec "$CHAINLIT" run main.py --host "$HOST" --port "$PORT"
