.PHONY: init up down logs build update-submodules clean

# 首次初始化: 拉取子模块、创建 .env、创建数据目录
init:
	git submodule update --init --recursive
	@if [ ! -f .env ]; then cp .env.example .env && echo "已创建 .env，请填入你的 API Key"; fi
	mkdir -p data/qdrant data/ragflow
	@echo "初始化完成"

# 构建并启动所有服务
up:
	docker compose up -d --build

# 停止所有服务
down:
	docker compose down

# 停止并清除数据卷
clean:
	docker compose down -v

# 查看日志 (实时跟踪)
logs:
	docker compose logs -f

# 仅构建镜像不启动
build:
	docker compose build

# 更新子模块到远程最新 commit
update-submodules:
	git submodule update --remote --merge
	@echo "子模块已更新，请检查后提交主仓库的子模块引用"

# 重启单个服务 (用法: make restart SVC=app)
restart:
	docker compose restart $(SVC)
