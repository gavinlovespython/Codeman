#!/bin/bash
# Claudeman launchd wrapper
#
# 根因: Node 25 被 launchd 直接拉起时 V8 bootstrapper 概率性死锁
# (进程存在、端口不监听、日志空白、sample 显示卡在 LoadEnvironment)
# 手动 nohup 同样环境则正常。通过 bash wrapper + exec 绕过此问题。
#
# 额外加固:
# - 启动前清理占 3000 端口的野进程
# - 写启动日志到 stderr（被 launchd 重定向到 StandardErrorPath）

set -euo pipefail

PORT=3000
CLAUDEMAN_DIR="/Users/teigen/Documents/Workspace/AI_project/Claudeman"

export HOME=/Users/teigen
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

echo "[wrapper] $(date '+%Y-%m-%d %H:%M:%S') starting claudeman web" >&2

# 清理占端口的野进程（非本进程树的残留 node）
STALE_PIDS=$(/usr/sbin/lsof -nP -iTCP:${PORT} -sTCP:LISTEN -t 2>/dev/null || true)
if [[ -n "$STALE_PIDS" ]]; then
  echo "[wrapper] clearing stale processes on port ${PORT}: ${STALE_PIDS}" >&2
  for pid in $STALE_PIDS; do
    kill "$pid" 2>/dev/null || true
  done
  sleep 2
fi

cd "$CLAUDEMAN_DIR"
exec /opt/homebrew/bin/node dist/index.js web --https -p "$PORT"
