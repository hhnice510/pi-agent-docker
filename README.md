# Pi Agent + Pichamber Docker

[![Build and Push Docker Image to GHCR](https://github.com/hhnice510/pi-agent-docker/actions/workflows/docker-publish.yml/badge.svg?branch=pi-agent-pichamber)](https://github.com/hhnice510/pi-agent-docker/actions/workflows/docker-publish.yml)
[![Docker Image](https://img.shields.io/badge/GHCR-pi--agent--pichamber-blue?logo=docker)](https://github.com/hhnice510/pi-agent-docker/pkgs/container/pi-agent-pichamber)

这是 **Pi Agent (CLI)** 与 **[Pichamber](https://github.com/AMagicPear/pichamber)** 极简 Web 面板的一体化 Docker 镜像方案。

> **分支说明**：
> - `main`：完整版，包含 Pi Agent + Pi-Web + code-server (VS Code Web)。
> - `pi-agent-web-only`：轻量版，仅包含 Pi Agent + Pi-Web。
> - `pi-agent-pichamber`（当前分支）：轻量版，仅包含 **Pi Agent + Pichamber Web UI**（基于 Bun 运行时的现代化 Pi Agent 交互面板）。

---

## ✨ 核心特性

- ⚡ **开箱即用**：内置 Node.js 22、Bun (>=1.3)、`@earendil-works/pi-coding-agent` 与 `@amagicpear/pichamber`。
- 🎨 **Pichamber 面板**：集成 Vue 3 + Bun 的全新轻量级 Pi Agent 交互式 GUI 面板，自带真实终端与状态管理。
- 🔄 **自动定时构建与更新**：GitHub Actions 每天 UTC 01:17（北京时间 09:17）自动检测 NPM 上游更新（`@earendil-works/pi-coding-agent` 与 `@amagicpear/pichamber`），有新版本发布即自动构建并推送最新多架构镜像（`linux/amd64`、`linux/arm64`）。
- 💾 **数据持久化**：宿主机工作区与容器内 `/workspace` 双向同步；配置、会话历史、Git 凭据自动持久化到 Docker Volume。
- 🌐 **代理友好**：一键打通宿主机代理（Clash / Surge / v2rayA 等）。

---

## 🚀 快速开始

### 1. 克隆代码并进入分支

```bash
git clone -b pi-agent-pichamber https://github.com/hhnice510/pi-agent-docker.git
cd pi-agent-docker
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入你的模型 API 密钥（至少填一个）：

```env
# Pichamber 宿主机端口
PICHAMBER_PORT=3000

# 模型 API 密钥
ANTHROPIC_API_KEY=sk-ant-api03-...
# OPENAI_API_KEY=sk-...
# DEEPSEEK_API_KEY=sk-...
# GEMINI_API_KEY=AIzaSy...

# 如果需要走宿主机代理（可选）
# HTTP_PROXY=http://host.docker.internal:7890
# HTTPS_PROXY=http://host.docker.internal:7890
```

### 3. 启动容器

```bash
docker compose up -d
```

### 4. 访问服务

在浏览器中打开：

- 🖥️ **Pichamber Web 界面**：[http://localhost:3000](http://localhost:3000)

---

## 🛠️ 常用操作

### 进入容器执行 CLI

```bash
docker compose exec pi-agent bash
# 或直接运行 pi 命令
docker compose exec pi-agent pi
```

### 查看实时运行日志

```bash
docker compose logs -f
```

### 停止并清理容器

```bash
# 停止容器
docker compose down

# 停止并删除持久化数据卷（⚠️ 会清除历史会话和配置）
docker compose down -v
```

---

## ⚙️ 环境变量配置参考

| 变量名 | 默认值 | 描述 |
| :--- | :--- | :--- |
| `PICHAMBER_PORT` | `3000` | Pichamber Web UI 映射到宿主机的端口 |
| `AUTO_UPDATE` | `false` | 容器启动时是否自动运行 `npm update -g` 检查升级最新组件 |
| `ANTHROPIC_API_KEY` | - | Anthropic Claude API 密钥 |
| `OPENAI_API_KEY` | - | OpenAI API 密钥 |
| `DEEPSEEK_API_KEY` | - | DeepSeek API 密钥 |
| `GEMINI_API_KEY` | - | Google Gemini API 密钥 |
| `HTTP_PROXY` | - | HTTP 代理地址（如 `http://host.docker.internal:7890`） |
| `HTTPS_PROXY` | - | HTTPS 代理地址 |
| `NO_PROXY` | `localhost,127.0.0.1` | 绕过代理的域名/IP 列表 |

---

## 📦 镜像标签与自动构建 (GHCR)

本分支对应镜像：`ghcr.io/hhnice510/pi-agent-pichamber`。

| 标签 | 含义 |
| :--- | :--- |
| `latest` | 最新构建 |
| `pi-<版本>_pichamber-<版本>` | 如 `pi-1.5.0_pichamber-1.5.4`，只包含本镜像实际安装的两个组件 |
| `sha-<短提交>` | 对应构建的提交 |

GitHub Actions 工作流（`.github/workflows/docker-publish.yml`）的行为：

1. **定时检测**：每天 UTC 01:17（北京时间 09:17）查询 npm 上 `@earendil-works/pi-coding-agent` 与 `@amagicpear/pichamber` 的最新版本。刻意避开整点，因为 GitHub 在整点负载最高，定时任务可能被延迟甚至丢弃。
2. **多分支矩阵**：定时任务会同时构建 `main`、`pi-agent-web-only`、`pi-agent-pichamber` 三个分支，各自推送到独立镜像仓库，互不覆盖；其它事件（push / PR / 手动触发）只构建当次触发的分支。
3. **免重复构建**：缓存 key 由「分支 + 上游版本」组成。上游版本未变且为定时调度时，工作流会在十几秒内跳过构建。
4. **精准缓存**：版本号作为 `build-arg`（`PI_VERSION` / `PICHAMBER_VERSION`）传入，配合 `type=gha` 层级缓存。上游版本一变，安装层缓存必然失效，不会出现「构建成功但装的还是旧版本」。

> ⚠️ **维护提示**：GitHub 只在仓库**默认分支**上触发 `schedule`。定时逻辑必须保留在默认分支（`main`）的 workflow 中。

---

## 📄 License

MIT License
