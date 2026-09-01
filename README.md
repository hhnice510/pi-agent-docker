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
- 🔄 **自动定时构建与更新**：GitHub Actions 每天自动检测 NPM 上游更新（`pi-coding-agent` 和 `pichamber`），有新版本发布即自动构建并推送最新多架构镜像（`linux/amd64`、`linux/arm64`）。
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

## 📄 License

MIT License
