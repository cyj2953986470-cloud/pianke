# 🐳 片刻 (Pianke) Docker 部署指南

## 一键安装

```bash
# 下载安装脚本
curl -fsSL https://raw.githubusercontent.com/cyj2953986470-cloud/pianke/docker-adapt/install.sh -o install.sh
chmod +x install.sh

# 运行安装器（交互式，会询问照片路径和端口）
./install.sh
```

安装脚本支持 `--no-cache` 参数，用于忽略 Docker 缓存重新构建镜像：

```bash
./install.sh --no-cache
```

## 手动部署

### 1. 克隆项目

```bash
git clone --branch docker-adapt --depth 1 https://github.com/cyj2953986470-cloud/pianke.git
cd pianke
```

### 2. 配置照片路径

编辑 `docker-compose.yml`，把照片目录挂载到容器：

```yaml
volumes:
  # 左边改成你的照片目录绝对路径
  - /你的照片路径:/photos
```

**常见 NAS 路径：**

| NAS 系统 | 路径示例 |
|---------|---------|
| 群晖 DSM | `/volume1/photo` |
| 飞牛 fnOS | `/vol1/1000/Photos` |
| 威联通 QTS | `/share/Photo` |
| Unraid | `/mnt/user/Photos` |
| TrueNAS | `/mnt/pool/Photos` |

**桌面系统：**

| 系统 | 路径示例 |
|-----|---------|
| Linux | `/home/用户名/Photos` |
| macOS | `/Users/用户名/Photos` |
| Windows | `//c/Users/用户名/Photos` |

### 3. 构建并启动

```bash
# 构建镜像（首次约 5-10 分钟，需要下载 PyTorch 等依赖）
docker compose build

# 启动容器
docker compose up -d
```

如需忽略缓存重新构建：

```bash
docker compose build --no-cache
docker compose up -d
```

### 4. 访问

打开浏览器访问：**http://你的NAS-IP:5057**

## 使用方法

1. 选择工作模式：
   - **极速模式**：纯本地、无需联网，适合风景/静物
   - **专家模式**（推荐）：本地 AI 识人识脸更准，适合人像/婚礼
   - **土豪模式**：调用大模型 API，用人话解释退片原因
2. 点击「选择文件夹」→ 浏览到照片目录 → 「选择此文件夹」
3. 点击「开始」整理照片

## 常用命令

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 查看日志
docker compose logs -f

# 更新（拉取新代码后重建）
git pull
docker compose build
docker compose up -d

# 完全重建（忽略缓存）
docker compose build --no-cache
docker compose up -d
```

## 修改端口

编辑 `docker-compose.yml`：

```yaml
ports:
  - "8080:5057"  # 左边改成你想要的端口
```

然后重启：`docker compose up -d`

## 配置 API Key（土豪模式）

如果需要使用「土豪模式」（调用大模型解释退片原因），需要配置 API Key。

在项目目录创建 `.env` 文件：

```env
ARK_API_KEY=你的API密钥
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
```

然后取消 `docker-compose.yml` 中 `env_file` 的注释：

```yaml
    env_file:
      - .env
```

重启容器即可生效。

## 技术说明

- 基于 Python 3.10-slim
- 专家模式首次启动会自动下载 AI 模型（约 600MB）
- 模型缓存在 Docker named volume 中，重建容器不会丢失
- 照片不会上传到任何地方，全部本地处理
- 支持 JPG / PNG / HEIC / WEBP / TIFF / RAW 格式
- 容器以非 root 用户运行，提升安全性

## 故障排除

**Q: 构建很慢？**
A: PyTorch 依赖约 2GB，首次需要下载。之后有 Docker 缓存会很快。如果缓存异常，使用 `docker compose build --no-cache` 重建。

**Q: 专家模式分析很慢？**
A: NAS 没有 GPU，CPU 推理会慢一些。极速模式不需要 AI 模型，速度很快。

**Q: 选择文件夹按钮没反应？**
A: Docker 环境下会自动切换到网页版文件夹浏览器。如果仍然没反应，可以手动在输入框输入容器内路径（如 `/photos/你的照片文件夹`）。

**Q: 怎么挂载多个照片目录？**
A: 在 `docker-compose.yml` 的 volumes 下添加多行：
```yaml
volumes:
  - /照片路径1:/photos/folder1
  - /照片路径2:/photos/folder2
```
