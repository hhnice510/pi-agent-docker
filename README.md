# Pi Agent Docker (Pi Web UI + VS Code Web)

> 📦 **本 README 属于仓库默认分支 `main`。GHCR 上三个 package 页面都会展示这一份，所以下面先列出镜像与分支的对应关系。**
>
> | 镜像 | 对应分支 | 打包内容 |
> | :--- | :--- | :--- |
> | `ghcr.io/hhnice510/pi-agent-docker` | `main` | Pi Agent + Pi-Web + code-server (VS Code Web) |
> | `ghcr.io/hhnice510/pi-agent-web-only` | `pi-agent-web-only` | 仅 Pi Agent + Pi-Web（无 code-server） |
> | `ghcr.io/hhnice510/pi-agent-pichamber` | `pi-agent-pichamber` | 仅 Pi Agent + Pichamber Web UI |
>
> 下文描述的是 **`main` 分支的完整版**（含 code-server）。其它两个分支的细节请切到对应分支查看各自的 README。

本项目提供了一个将 **[Pi Coding Agent](https://pi.dev/)** 引擎、**[Pi Web UI](https://github.com/agegr/pi-web)** 前端以及 **code-server (VS Code Web)** 打包在同一容器内的 Docker 化开发环境。支持数据持久化管理与 GitHub Actions 自动构建打包推送至 GitHub Container Registry (GHCR)。

---

## 🌟 核心特性

- **一站式开发环境**：基于 `Node.js 22 (Debian Bookworm)`，预装 `git`、`vim`、`ripgrep`、`curl`、`build-essential` 等工具。
- **Pi Web 可视化前端**：内置 [agegr/pi-web](https://github.com/agegr/pi-web) 交互式 Web Dashboard，容器内固定端口 `30141`。
- **Code-server (VS Code Web)**：浏览器内获得完整的 VS Code 体验，直接编辑 `/workspace` 代码并进行 Git 版本管理，容器内固定端口 `8443`。
- **三控交互体验**：
  1. **Web Dashboard**：通过浏览器访问 Pi Web 进行 AI 对话、任务协作与会话管理；
  2. **VS Code Web**：通过浏览器访问 code-server 编辑代码与进行 Git 操作；
  3. **CLI 终端**：随时通过终端进入容器使用 `pi` 命令行交互。
- **全量持久化**：
  - `pi_data` (`/root/.pi`)：持久化保存模型配置、扩展技能 (Skills)、自定义 Prompt、历史 Session、Git 全局配置（用户名/邮箱/凭证）以及 code-server 配置与扩展（`/root/.pi/code-server`）。
  - `workspace` (`/workspace`)：持久化挂载您的本地代码项目，Pi Web、code-server 与 Pi CLI 共享同一工作区。
- **轻量进程守护（Supervisord）**：容器以 `supervisord` 作为 PID 1 统一管理 `pi-web` 与 `code-server`，独立运行、异常自动重启（`autorestart`）、优雅退出（SIGTERM）。
- **智能 CI/CD (GHCR)**：包含 GitHub Actions 工作流，每天定时检测上游更新，自动构建 `amd64` 与 `arm64` 双架构镜像并推送至 GHCR。

---

## 📁 目录结构

```text
.
├── Dockerfile                   # Docker 镜像构建文件 (Node 22 Debian)
├── docker-compose.yml           # Docker Compose 本地启动与持久化配置
├── entrypoint.sh                # 容器启动入口脚本 (Supervisord 启动与环境初始化)
├── supervisord.conf             # Supervisord 多进程管理配置
├── .env.example                 # 环境变量配置模版
├── extensions/                  # 内置 Pi Agent 扩展与插件
│   └── code-server-manager.ts   # VS Code Web 动态启停管理插件 (Tool & Command)
├── .github/
│   └── workflows/
│       └── docker-publish.yml   # GitHub Actions 构建与推送工作流
└── README.md                    # 说明文档
```

---

## 🚀 快速开始

### 方式一：使用 Docker Compose 本地运行（推荐）

1. **配置环境变量**
   ```bash
   cp .env.example .env
   ```
   *在 `.env` 中填入您的 LLM API 密钥（如 `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`）及可选的访问密码。*

2. **创建代码工作区目录**
   ```bash
   mkdir -p workspace
   ```

3. **启动容器**
   ```bash
   docker compose up -d
   ```

4. **访问服务**
   - **Pi Web UI**：[http://localhost:30141](http://localhost:30141)
   - **VS Code Web**：[http://localhost:8443](http://localhost:8443)（若未配置 `CODE_SERVER_PASSWORD`，随机生成的密码会打印在容器启动日志中，可通过 `docker compose logs` 查看）

---

### 方式二：使用 GHCR 预构建镜像直接运行

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

> **注意**：容器内部端口已固定（Pi Web: `30141`，code-server: `8443`）。如需在宿主机使用其他端口，只需修改端口映射的冒号左侧（例如 `-p 3000:30141 -p 8080:8443`）。

---

## 💻 命令行 CLI 交互

除了 Web 界面，您可以随时直接连接容器使用 `pi` 命令行：

```bash
docker exec -it pi-agent pi
```

或者进入容器的 Bash 终端：
```bash
docker exec -it pi-agent bash
```

> **提示**：当使用 `docker run ... <command>` 传入自定义命令（如 `bash` 或 `pi`）时，容器将直接执行该命令并退出，不会启动后台 Web 服务。

---

## 🔑 环境变量说明

| 变量名 | 必填 | 示例 | 详细备注 |
| :--- | :---: | :--- | :--- |
| **PI_WEB_PASSWORD** | ❌ | `123456` | Web UI Basic Auth 访问密码（用户名默认为 `pi`，留空免密） |
| **CODE_SERVER_PASSWORD** | ❌ | `123456` | Code-server 登录密码（留空则启动时随机生成并在日志中打印） |
| **CODE_SERVER_EXTENSIONS** | ❌ | `ms-ceintl.vscode-language-pack-zh-hans,esbenp.prettier-vscode` | 容器启动时自动安装的 VS Code 扩展 ID（多个用英文逗号分隔） |
| **CODE_SERVER_ENABLED** | ❌ | `true` | 是否在容器内启动 Code-server（`true`/`false`，默认 `true`） |
| **AUTO_UPDATE** | ❌ | `false` | 容器启动时是否自动升级 `pi` 和 `pi-web` 到 npm 最新版 |
| **ANTHROPIC_API_KEY** | ❌ | `sk-ant-api03-...` | Anthropic Claude API 密钥（模型密钥按需至少填一个） |
| **OPENAI_API_KEY** | ❌ | `sk-...` | OpenAI API 密钥 |
| **DEEPSEEK_API_KEY** | ❌ | `sk-...` | DeepSeek API 密钥 |
| **GEMINI_API_KEY** | ❌ | `AIzaSy...` | Google Gemini API 密钥 |
| **HTTP_PROXY** | ❌ | `http://host.docker.internal:7890` | 服务端模型/API 请求 HTTP 代理（宿主机代理用 `host.docker.internal`） |
| **HTTPS_PROXY** | ❌ | `http://host.docker.internal:7890` | 服务端模型/API 请求 HTTPS 代理 |
| **NO_PROXY** | ❌ | `localhost,127.0.0.1` | 不走代理的地址白名单 |

---

## 🖥️ Code-server (VS Code Web) 说明

1. **工作区与 Git 共享**：
   - Code-server 默认直接打开 `/workspace`，与 Pi Agent 的工作目录完全一致；
   - 容器内的 `.gitconfig` 和 `.git-credentials` 会自动同步到 `pi_data` 持久卷中，在 Code-server 中进行 Git 提交、拉取与推送均使用相同身份。
2. **扩展与配置持久化**：
   - Code-server 的设置与扩展存放在 `/root/.pi/code-server` 下，容器重建或升级后配置不丢失。
   - 也可以在 `.env` 中通过 `CODE_SERVER_EXTENSIONS` 指定在启动时自动安装扩展（例如 `ms-ceintl.vscode-language-pack-zh-hans,esbenp.prettier-vscode`）。
3. **内置 Pi Agent 插件动态启停**：
   - 本镜像内置了 `code-server-manager` 扩展，Pi Agent 支持通过 Supervisor 按需动态管理 code-server，释放系统内存。
   - **自然语言对话控制**：直接在 Pi 对话中要求它，如 “*帮我启动 VS Code*”、“*帮我关闭 code-server 释放内存*” 或 “*查看 VS Code 运行状态*”，Pi Agent 将自动调用内置 Tool 完成操作；
   - **快捷斜杠指令**：在 Pi 终端或对话中输入 `/codeserver [start|stop|restart|status]` 即可直接管理。
4. **启动时默认禁用**：
   - 若平时主要使用 Pi Web UI，可在 `.env` 中设置 `CODE_SERVER_ENABLED=false`。需要时亦可通过上述插件让 Agent 动态启动。

---

## 🌐 HTTP 代理配置

如果宿主机运行着代理（如 Clash 监听 7890 端口），在 `.env` 中添加：

```bash
HTTP_PROXY=http://host.docker.internal:7890
HTTPS_PROXY=http://host.docker.internal:7890
NO_PROXY=localhost,127.0.0.1
```

`docker-compose.yml` 中已内置 `host.docker.internal` 解析支持。

---

## 🔄 CI/CD 与智能版本检测 (GHCR)

本项目在 `.github/workflows/docker-publish.yml` 中配置了 GitHub Actions 自动化工作流。

本分支对应镜像：`ghcr.io/hhnice510/pi-agent-docker`。

| 标签 | 含义 |
| :--- | :--- |
| `latest` | 最新构建 |
| `pi-<版本>_web-<版本>_code-server-<版本>` | 如 `pi-1.5.0_web-0.14.1_code-server-4.133.0`，包含本镜像实际打包的三个组件 |
| `sha-<短提交>` | 对应构建的提交 |

1. **定时上游版本检测**：每天 UTC 01:17（北京时间 09:17）检查上游版本。每个镜像只追踪自己实际安装的组件：`main` 看 `@earendil-works/pi-coding-agent` + `@agegr/pi-web` + Dockerfile 里的 `CODE_SERVER_VERSION`，`pi-agent-web-only` 看前两者，`pi-agent-pichamber` 看 `@earendil-works/pi-coding-agent` + `@amagicpear/pichamber`。刻意避开整点，因为 GitHub 在整点负载最高，定时任务可能被延迟甚至丢弃。
2. **多分支矩阵构建**：定时任务会依次构建 `main`、`pi-agent-web-only`、`pi-agent-pichamber` 三个分支，各自推送到独立镜像仓库（`ghcr.io/hhnice510/<分支名>`，`main` 对应 `pi-agent-docker`），互不覆盖。其它事件（push / PR / 手动触发）只构建当次触发的那个分支。
3. **免重复构建**：缓存 key 由「分支 + 该镜像安装的组件版本」组成，镜像标签也按同样规则命名。若上游版本未变更且为定时调度，工作流会在十几秒内跳过构建，避免在 GHCR 产生冗余镜像。
4. **精准缓存与多架构极速构建**：将版本号作为 `build-arg` 传入 Docker 构建（`PI_VERSION` / `PI_WEB_VERSION` / `PICHAMBER_VERSION`），并启用 GitHub Actions 层级缓存 (`type=gha`)。基础 Debian 系统等不变层无需重复构建，跨架构（`amd64` + `arm64`）打包速度大幅提升；同时上游版本一变，安装层缓存必然失效，不会出现「构建成功但装的还是旧版本」。

> ⚠️ **维护提示**：GitHub 只在仓库**默认分支**上触发 `schedule`。定时逻辑必须保留在默认分支（`main`）的 workflow 中；只改其它分支的 workflow 文件不会让定时任务生效。

---

## 🔗 相关链接

- **Pi Agent 官网**: [https://pi.dev/](https://pi.dev/)
- **Pi Web UI 项目**: [https://github.com/agegr/pi-web](https://github.com/agegr/pi-web)
- **Code-server 项目**: [https://github.com/coder/code-server](https://github.com/coder/code-server)
