import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { execSync } from "child_process";

export default function (pi: ExtensionAPI) {
  // 1. Register Tool for LLM: allows Pi Agent to start/stop/restart/check code-server automatically
  pi.registerTool({
    name: "manage_code_server",
    description: "管理容器内的 code-server (VS Code Web) 服务：启动 (start)、停止 (stop)、重启 (restart) 或查看当前运行状态 (status)。",
    parameters: Type.Object({
      action: Type.Union([
        Type.Literal("start"),
        Type.Literal("stop"),
        Type.Literal("restart"),
        Type.Literal("status"),
      ], { description: "要对 code-server 执行的操作 (start|stop|restart|status)" }),
    }),
    handler: async (args) => {
      try {
        const output = execSync(`supervisorctl ${args.action} code-server`, {
          encoding: "utf-8",
          timeout: 10000,
        });
        return `code-server 操作成功:\n${output.trim()}`;
      } catch (error: any) {
        return `执行 supervisorctl ${args.action} 失败:\n${error.stdout || error.message || error}`;
      }
    },
  });

  // 2. Register Slash Command: allows users to run /codeserver [start|stop|restart|status] in Pi TUI
  pi.registerCommand("codeserver", {
    description: "管理 VS Code Web (code-server): /codeserver [start|stop|restart|status]",
    handler: async (args, ctx) => {
      const action = args.trim() || "status";
      try {
        const output = execSync(`supervisorctl ${action} code-server`, {
          encoding: "utf-8",
          timeout: 10000,
        });
        ctx.ui.notify(output.trim(), "info");
      } catch (error: any) {
        ctx.ui.notify(`错误: ${error.stdout || error.message || error}`, "error");
      }
    },
  });
}
