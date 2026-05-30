#!/bin/bash
set -e

# ========== 片刻 (Pianke) Docker 一键安装脚本 ==========

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/cyj2953986470-cloud/pianke.git"
BRANCH="docker-adapt"
INSTALL_DIR="${1:-./pianke}"
DEFAULT_PORT=5057
NO_CACHE=""

# 解析参数
for arg in "$@"; do
    case "$arg" in
        --no-cache) NO_CACHE="--no-cache" ;;
    esac
done

echo -e "${CYAN}"
echo "  ┌─────────────────────────────────────┐"
echo "  │     片刻 (Pianke) Docker 安装器      │"
echo "  │  让 AI 替你过一遍，由你做最后的决定。  │"
echo "  └─────────────────────────────────────┘"
echo -e "${NC}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ 未找到 Docker，请先安装 Docker${NC}"
    echo "  安装命令: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! docker compose version &> /dev/null 2>&1 && ! docker-compose version &> /dev/null 2>&1; then
    echo -e "${RED}✗ 未找到 Docker Compose，请先安装${NC}"
    exit 1
fi

# 判断 compose 命令
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo -e "${GREEN}✓ Docker 环境检查通过${NC}"

# 克隆仓库
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠ 目录 $INSTALL_DIR 已存在，跳过克隆${NC}"
else
    echo -e "${CYAN}→ 正在下载项目...${NC}"
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 配置照片路径
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  配置照片文件夹挂载路径${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo "  容器内照片目录: /photos"
echo "  你需要把 NAS/主机上的照片目录挂载进去。"
echo ""
echo -e "  ${YELLOW}示例路径:${NC}"
echo "    NAS (群晖/飞牛):  /volume1/photos"
echo "    Linux/Mac:        /home/user/Photos"
echo "    Windows Docker:   //c/Users/user/Photos"
echo ""

read -rp "  请输入照片目录的绝对路径 (留空使用默认 ./data/photos): " PHOTO_PATH

# 如果用户留空，使用默认路径并确保目录存在
if [ -z "$PHOTO_PATH" ]; then
    PHOTO_PATH="./data/photos"
    mkdir -p "$PHOTO_PATH"
    echo -e "${GREEN}✓ 使用默认路径: $PHOTO_PATH${NC}"
fi

# 端口配置
read -rp "  请输入 Web 端口 (默认 $DEFAULT_PORT): " PORT
PORT="${PORT:-$DEFAULT_PORT}"

# 更新 docker-compose.yml
if [ -n "$PHOTO_PATH" ]; then
    # 替换照片挂载路径
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|./data/photos:|${PHOTO_PATH}:|g" docker-compose.yml
    else
        sed -i "s|./data/photos:|${PHOTO_PATH}:|g" docker-compose.yml
    fi
    echo -e "${GREEN}✓ 照片路径已配置: $PHOTO_PATH → /photos${NC}"
fi

# 更新端口
if [ "$PORT" != "$DEFAULT_PORT" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\"${DEFAULT_PORT}:${DEFAULT_PORT}\"|\"${PORT}:${DEFAULT_PORT}\"|g" docker-compose.yml
    else
        sed -i "s|\"${DEFAULT_PORT}:${DEFAULT_PORT}\"|\"${PORT}:${DEFAULT_PORT}\"|g" docker-compose.yml
    fi
    echo -e "${GREEN}✓ 端口已改为: $PORT${NC}"
fi

# 构建并启动
echo ""
echo -e "${CYAN}→ 正在构建 Docker 镜像（首次约 5-10 分钟）...${NC}"
if [ -n "$NO_CACHE" ]; then
    echo -e "${YELLOW}  使用 --no-cache 模式，忽略缓存重新构建${NC}"
    $COMPOSE_CMD build --no-cache
else
    $COMPOSE_CMD build
fi

echo -e "${CYAN}→ 正在启动容器...${NC}"
$COMPOSE_CMD up -d

# 等待启动（检查 HTTP 状态码）
echo -e "${CYAN}→ 等待服务启动...${NC}"
for i in $(seq 1 60); do
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        break
    fi
    sleep 2
done

# 获取本机 IP
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ 安装完成！${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}访问地址:${NC}  http://${LOCAL_IP}:${PORT}"
echo ""
echo -e "  ${YELLOW}使用步骤:${NC}"
echo "  1. 打开浏览器访问上面的地址"
echo "  2. 选择工作模式（推荐「专家模式」）"
echo "  3. 点击「选择文件夹」浏览照片目录"
echo "  4. 点击「开始」整理照片"
echo ""
echo -e "  ${YELLOW}常用命令:${NC}"
echo "  启动:  cd $INSTALL_DIR && $COMPOSE_CMD up -d"
echo "  停止:  cd $INSTALL_DIR && $COMPOSE_CMD down"
echo "  日志:  cd $INSTALL_DIR && $COMPOSE_CMD logs -f"
echo "  更新:  cd $INSTALL_DIR && git pull && $COMPOSE_CMD build && $COMPOSE_CMD up -d"
echo "  重建:  cd $INSTALL_DIR && $COMPOSE_CMD build --no-cache && $COMPOSE_CMD up -d"
echo ""
