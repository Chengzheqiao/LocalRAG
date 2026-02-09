#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LocalRAG 本地开发环境一键搭建
# 功能: 创建 conda 环境 + 安装全部 Python 依赖
# 前置: 已安装 conda (miniconda / anaconda)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CONDA_ENV_NAME="localrag"
PYTHON_VERSION="3.11"

echo "========================================="
echo "  LocalRAG 本地开发环境搭建"
echo "========================================="

# ---------- 1. 检查 conda ----------
if ! command -v conda &>/dev/null; then
    echo "[ERROR] 未检测到 conda，请先安装 Miniconda / Anaconda"
    exit 1
fi
echo "[OK] conda 已安装"

# ---------- 2. 创建 / 复用 conda 环境 ----------
if conda env list | grep -qw "$CONDA_ENV_NAME"; then
    echo "[OK] conda 环境 '$CONDA_ENV_NAME' 已存在，跳过创建"
else
    echo "[INFO] 创建 conda 环境 '$CONDA_ENV_NAME' (Python $PYTHON_VERSION) ..."
    conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" -y
    echo "[OK] conda 环境创建完成"
fi

# ---------- 3. 定位 conda 环境 pip ----------
CONDA_PREFIX="$(conda info --envs | grep "$CONDA_ENV_NAME" | awk '{print $NF}')"
PIP="$CONDA_PREFIX/bin/pip"

if [ ! -f "$PIP" ]; then
    echo "[ERROR] 未找到 $PIP，conda 环境可能创建失败"
    exit 1
fi
echo "[OK] 使用 pip: $PIP"

# ---------- 4. 安装 requirements.txt ----------
echo "[INFO] 安装 app/requirements.txt ..."
"$PIP" install -r "$PROJECT_ROOT/app/requirements.txt"
echo "[OK] requirements.txt 安装完成"

# ---------- 5. 安装 fork 版 ragas ----------
if [ -d "$PROJECT_ROOT/vendor/ragas" ]; then
    echo "[INFO] 安装 vendor/ragas (editable mode) ..."
    "$PIP" install -e "$PROJECT_ROOT/vendor/ragas"
    echo "[OK] ragas 安装完成"
else
    echo "[WARN] vendor/ragas 不存在，跳过。请先执行 git submodule update --init --recursive"
fi

# ---------- 6. 确保 .env_localtest 存在 ----------
if [ ! -f "$PROJECT_ROOT/.env_localtest" ]; then
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env_localtest"
        # 替换容器主机名为 localhost
        sed -i.bak 's/QDRANT_HOST=qdrant/QDRANT_HOST=localhost/' "$PROJECT_ROOT/.env_localtest"
        sed -i.bak 's|RAGFLOW_BASE_URL=http://ragflow:9380|RAGFLOW_BASE_URL=http://localhost:9380|' "$PROJECT_ROOT/.env_localtest"
        sed -i.bak 's/REDIS_HOST=redis/REDIS_HOST=localhost/' "$PROJECT_ROOT/.env_localtest"
        sed -i.bak 's/ES_HOST=elasticsearch/ES_HOST=localhost/' "$PROJECT_ROOT/.env_localtest"
        rm -f "$PROJECT_ROOT/.env_localtest.bak"
        echo "[OK] 已从 .env.example 生成 .env_localtest，请检查并填入 API Key"
    else
        echo "[WARN] 未找到 .env.example，请手动创建 .env_localtest"
    fi
else
    echo "[OK] .env_localtest 已存在"
fi

echo ""
echo "========================================="
echo "  搭建完成!"
echo "========================================="
echo ""
echo "后续步骤:"
echo "  1. 确认 .env_localtest 中的 API Key 已填写"
echo "  2. 启动基础容器:  bash ops/prod-start.sh  (或仅启动 infra)"
echo "  3. 启动本地调试:  bash ops/local-start.sh"
