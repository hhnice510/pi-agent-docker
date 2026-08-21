# Pi Agent Docker & Pi Web UI & VS Code Web

本项目提供了一个用于运行 **[Pi Coding Agent](https://pi.dev/)** 引擎、**[Pi Web UI](https://github.com/agegr/pi-web)** 前端以及 **code-server (VS Code Web)** 的 Dockerized 解决方案，支持数据持久化管理与 GitHub Actions 自动构建打包推送至 GitHub Container Registry (GHCR)。

---

## 🌟 核心特性

- **完整环境集成**：基于 `Node.js 22 (Debian Bookworm)` 打造，预装 `git`、`vim`、`ripgrep`、`curl`、`build-essential` 等工具。
- **Pi Web 端可视化支持**：内置 [agegr/pi-web](https://github.com/agegr/pi-web) 交互式 Web Dashboard，默认暴露 `30141` 端口。
- **Code-server (VS Code Web) 内置**：浏览器中即可获得完整的 VS Code 体验，直接查看 `/workspace` 中的项目文件并进行 **git 管理**（提交、分支、推送等），默认暴露 `8443` 端口。code-server 与 Pi Agent 共享同一套 git 全局配置（用户名/邮箱/凭证）与 SSH 密钥，且其设置和扩展持久化在 `pi_data` 卷中。
- **三控体验**：既可通过浏览器使用 VS Code Web 编辑代码与 git 管理，也可通过 Pi Web 进行会话控制与文件预览，还可随时通过终端连接容器使用 `pi` 命令行交互。
- **全量持久化**：
  - `pi_data` (`/root/.pi`)：持久化保存模型配置、API 密钥、扩展技能 (Skills)、自定义 Prompt、历史 Session 记录，以及 **git 全局配置（用户名/邮箱/token）**（容器启动时自动在 `/root/.pi` 与 `/root` 间同步）。`pi_data` 卷同时也是 **code-server 设置与扩展** 的存放位置（`/root/.pi/code-server`），容器重建后 IDE 配置不丢失。
  - `workspace` (`/workspace`)：持久化挂载您需要 Agent 协作的代码项目，pi-web / code-server / pi CLI 三者共享同一目录。
- **进程守护（Supervisord）**：容器以 `supervisord` 作为 PID 1 统一管理 `pi-web` 与 `code-server` 两个常驻服务，各自独立、崩溃自愈（`autorestart`），容器停止时由 supervisord 统一优雅关停（SIGTERM）。
- **GHCR CI/CD 集成**：包含 GitHub Actions 工作流，可自动构建 `amd64` 与 `arm64` 架构的镜像并推送至 GHCR。

---

## 📁 目录结构

```text
.
├── Dockerfile                   # Docker 镜像构建文件 (Node 22 Debian)
├── docker-compose.yml           # Docker Compose 本地启动与持久化挂载配置
├── entrypoint.sh                # 容器启动入口脚本
├── .env.example                 # 环境变量模版 (API Key, 密码, 代理等可选配置)
├── .github/
│   └── workflows/
│       └── docker-publish.yml   # GitHub Actions 构建并推送至 GHCR 的 Workflow
└── README.md                    # 说明文档
```

---

## 🚀 快速开始

### 方式一：使用 Docker Compose 本地构建启动（推荐）

1. **复制并配置环境变量**
   ```bash
   cp .env.example .env
   ```
   *根据需求在 `.env` 中填入您的 LLM API 密钥（如 `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`）或可选的 Web UI 访问密码。*

2. **创建本地代码工作区目录（若未创建）**
   ```bash
   mkdir -p workspace
   ```

3. **启动容器**
   ```bash
   docker compose up -d
   ```

4. **访问 Web 界面**
   - Pi Web UI：[http://localhost:30141](http://localhost:30141)
   - Code-server (VS Code Web)：[http://localhost:8443](http://localhost:8443)（未设置 `CODE_SERVER_PASSWORD` 时，随机密码会打印在容器日志中）

---

### 方式二：使用 GHCR 预构建镜像运行

在推送镜像至 GitHub Container Registry 后，您可以直接在服务器或任何开发机上运行：

```bash
docker run -d \
  --name pi-agent \
  -p 30141:30141 \
  -p 8443:8443 \
  -v pi_agent_data:/root/.pi \
  -v $(pwd)/workspace:/workspace \
  -e ANTHROPIC_API_KEY="your_api_key_here" \
  -e CODE_SERVER_PASSWORD="your_secure_password" \
  ghcr.io/hhnice510/pi-agent-docker:latest
```

---

## 💻 命令行 CLI 交互

除了在 Web UI / VS Code Web 操作外，您还可以直接进入容器使用终端 `pi` 命令行：

```bash
docker exec -it pi-agent pi
```

或者进入容器的 Bash 环境：
```bash
docker exec -it pi-agent bash
```

> **提示**：当通过 `docker run ... <command>` 传入命令（如 `bash`、`pi`）时，容器将只执行该命令，不会启动 pi-web 与 code-server。

---

## ⚙️ 环境变量说明

| 变量名 | 说明 | 默认值 |
| :--- | :--- | :--- |
| `PORT` | Pi Web UI 服务监听端口（已在镜像内固定，一般无需在 `.env` 配置） | `30141` |
| `PI_WEB_PASSWORD` | 可选，开启 Web UI 的 Basic 密码验证 | 空（无密码） |
| `CODE_SERVER_PORT` | Code-server (VS Code Web) 监听端口（已在镜像内固定，一般无需在 `.env` 配置） | `8443` |
| `CODE_SERVER_PASSWORD` | 可选，Code-server 登录密码；留空则每次启动随机生成并打印到容器日志 | 空（随机生成） |
| `CODE_SERVER_EXTENSIONS` | 可选，容器启动时自动安装的 VS Code 扩展 ID（逗号分隔） | 空 |
| `CODE_SERVER_ENABLED` | 是否在容器启动时运行 code-server (`true`/`false`) | `true` |
| `AUTO_UPDATE` | 容器启动时是否自动检查并更新 pi 与 pi-web 到 npm 最新版 (`true`/`false`) | `false` |
| `ANTHROPIC_API_KEY` | Anthropic Claude API Key | - |
| `OPENAI_API_KEY` | OpenAI API Key | - |
| `DEEPSEEK_API_KEY` | DeepSeek API Key | - |
| `GEMINI_API_KEY` | Google Gemini API Key | - |
| `HTTP_PROXY` | 可选，pi-web 服务端模型/API 请求的 HTTP 代理 | 空（不走代理） |
| `HTTPS_PROXY` | 可选，HTTPS 代理地址 | 空（不走代理） |
| `NO_PROXY` | 可选，不走代理的地址白名单（逗号分隔） | 空 |

---

## 🖥️ Code-server (VS Code Web)

容器内置了 [code-server](https://github.com/coder/code-server)，在浏览器中即可获得完整的 VS Code 体验，适合**查看/编辑项目文件**与 **git 管理**（diff、提交、分支切换、推送等）。

### 快速使用

1. 在浏览器打开 [http://localhost:8443](http://localhost:8443)。
2. 登录密码：
   - 已在 `.env` 中设置 `CODE_SERVER_PASSWORD` → 使用该密码；
   - 未设置 → 容器每次启动会随机生成密码，并打印在容器日志中（`docker compose logs pi-agent` 可见）。
3. 默认打开 `/workspace` 目录，与 Pi Agent 的工作目录完全一致。

### 与 Pi Agent 的联动

- **git 配置互通**：code-server 与 Pi Agent 共享容器内同一套 git 全局配置（`.gitconfig` / `.git-credentials`，启动时自动双向同步），您在 code-server 中提交、推送时自动使用同一身份与凭证。
- **工作区互通**：`/workspace` 是同一个持久化目录，Pi Agent 改动的文件可立即在 VS Code Web 中查看，反之亦然。
- **设置与扩展持久化**：code-server 的设置与扩展存放在 `pi_data` 卷的 `/root/.pi/code-server` 下，容器重建后不丢失。
- **扩展自动安装**：在 `.env` 中设置 `CODE_SERVER_EXTENSIONS` 即可在容器启动时自动安装扩展（仅在缺失时安装，不会重复下载）。

```bash
# 示例：安装中文语言包与 Prettier
CODE_SERVER_EXTENSIONS=ms-ceintl.vscode-language-pack-zh-hans,esbenp.prettier-vscode
```

### 关闭 code-server

若不需要 VS Code Web，在 `.env` 中设置 `CODE_SERVER_ENABLED=false` 后重启容器即可，Pi Web UI 不受影响。

---

## 🌐 HTTP 代理配置

pi-web 的服务端模型和 API 请求支持标准 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 环境变量。

**注意**：容器内 `127.0.0.1` 指向容器自身。如果代理跑在 Docker 宿主机上，请使用 `host.docker.internal`（docker-compose 已配置 `host-gateway` 映射）。

### 方式一：`.env` 文件（推荐）

在 `.env` 中添加：

```bash
# 代理在宿主机上（如 Clash 默认端口 7890）
HTTP_PROXY=http://host.docker.internal:7890
HTTPS_PROXY=http://host.docker.internal:7890
NO_PROXY=localhost,127.0.0.1
```

然后重启容器生效：

```bash
docker compose up -d
```

### 方式二：`docker run` 传参

```bash
docker run -d \
  --name pi-agent \
  -p 30141:30141 \
  -p 8443:8443 \
  -v pi_agent_data:/root/.pi \
  -v $(pwd)/workspace:/workspace \
  --add-host host.docker.internal:host-gateway \
  -e HTTP_PROXY="http://host.docker.internal:7890" \
  -e HTTPS_PROXY="http://host.docker.internal:7890" \
  -e NO_PROXY="localhost,127.0.0.1" \
  ghcr.io/hhnice510/pi-agent-docker:latest
```

如果代理也运行在容器内，直接用容器的 IP/服务名即可。

---

## 📦 GitHub Actions CI/CD (GHCR)

本项目在 `.github/workflows/docker-publish.yml` 中配置了 GitHub Actions 工作流。

- **触发条件**：
  - 推送至 `main` 或 `master` 分支；
  - 发布以 `v*` 开头的 Tag（例如 `v1.0.0`）；
  - 手动触发 (`workflow_dispatch`)。
- **自动逻辑**：
  - 使用 Docker Buildx 构建 `linux/amd64` 与 `linux/arm64` 双架构镜像。
  - 自动登录 GHCR (`ghcr.io`) 并推送最新镜像。

---

## 🔄 智能上游 (pi & pi-web) 更新检测机制

为了解决“**每天无脑构建导致无新版本也重复推送镜像**”的问题，本项目在 GitHub Actions 中内置了 **智能上游版本检测机制**：

### 核心工作原理：
1. **自动查询 NPM Registry**：每次定时任务触发时，Actions 会首先请求 npm 官方仓库，查询 `@earendil-works/pi-coding-agent` 和 `@agegr/pi-web` 的最新版本号（如 `pi-1.2.0_web-1.0.5`）。
2. **对比历史构建缓存**：Actions 会将版本号与上一次成功构建的 Cache 进行比对。
3. **精准构建与跳过**：
   - **上游未更新**：如果上游 npm 版本没有任何变化，Actions 会直接在 10 秒内跳过 Docker 构建与推送，**不会在 GHCR 产生垃圾无用镜像**；
   - **上游已更新**：一旦检测到 `pi` 或 `pi-web` 在 npm 发布的版本号变化，Workflow 会自动进行全量无缓存重新构建，并推送最新的 `ghcr.io/hhnice510/pi-agent-docker:latest`！

---

### 如何触发/升级：
- **完全自动**：保持默认配置，GitHub 每天 08:00 会自动拉取 npm 版本比对，一旦上游更新就会自动构建推送新镜像。
- **手动触发**：在 GitHub 仓库 -> **Actions** -> **Build and Push Docker Image to GHCR** -> 点击 **Run workflow**（手动触发不受版本号对比限制，强制重新打包）。
- **容器内部自动更新 (`AUTO_UPDATE=true`)**：如果不想等待或不想拉新镜像，在 `.env` 中设置 `AUTO_UPDATE=true`，容器启动时会自动在内部更新到 npm 最新版。

---

## 🔗 相关链接

- **Pi Agent 官网**: [https://pi.dev/](https://pi.dev/)
- **Pi Web UI 项目**: [https://github.com/agegr/pi-web](https://github.com/agegr/pi-web)
- **Code-server 项目**: [https://github.com/coder/code-server](https://github.com/coder/code-server)

