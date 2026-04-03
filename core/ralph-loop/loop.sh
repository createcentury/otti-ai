#!/bin/bash
# ralph-loop/loop.sh
# Ralph Loop — Claude Code エージェントを自律的に動かし続けるための制御スクリプト
#
# 使い方:
#   ./loop.sh --cron "21:00" --skill freee-check          # 毎日21時に実行
#   ./loop.sh --watch skills/ --on-change sop-convert     # ファイル変更を検知して実行
#   ./loop.sh --once --skill daily-report                 # 1回だけ実行
#
# 設計:
#   1. Claude Code でタスクを実行
#   2. 検証スクリプトでエラーをチェック
#   3. エラーがあればClaude Codeに修正させる (最大MAX_RETRY回)
#   4. 成功したらGitコミット
#   5. ログを記録して次のサイクルへ

set -euo pipefail

# =====================
# 設定
# =====================
MAX_RETRY=3
CIRCUIT_BREAKER_THRESHOLD=3
LOG_DIR="logs/$(date +%Y-%m-%d)"
CHANGELOG="CHANGELOG.md"

mkdir -p "$LOG_DIR"

# =====================
# ユーティリティ関数
# =====================
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/loop.log"
}

notify_slack() {
  local message="$1"
  # SLACK_WEBHOOK_URL が設定されていれば通知
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    curl -s -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-type: application/json' \
      --data "{\"text\":\"[otti-ai] $message\"}" > /dev/null
  fi
}

commit_progress() {
  local message="$1"
  if git diff --quiet && git diff --cached --quiet; then
    log "変更なし — コミットをスキップ"
    return 0
  fi
  git add -A
  git commit -m "auto: $message [$(date '+%Y-%m-%d %H:%M')]"
  log "Gitコミット完了: $message"
}

# =====================
# サーキットブレーカー
# =====================
CONSECUTIVE_ERRORS=0

check_circuit_breaker() {
  if [[ $CONSECUTIVE_ERRORS -ge $CIRCUIT_BREAKER_THRESHOLD ]]; then
    log "ERROR: サーキットブレーカー発動 — 連続${CONSECUTIVE_ERRORS}回のエラー"
    notify_slack "サーキットブレーカー発動: 手動確認が必要です ($LOG_DIR)"
    exit 1
  fi
}

# =====================
# コアループ
# =====================
run_skill() {
  local skill="$1"
  local args="${2:-}"
  local retry=0
  local start_time
  start_time=$(date +%s)

  log "スキル開始: /$skill $args"

  while [[ $retry -lt $MAX_RETRY ]]; do
    check_circuit_breaker

    # Claude Code でスキルを実行
    if claude --print "/$skill $args" 2>> "$LOG_DIR/claude.log"; then
      local end_time
      end_time=$(date +%s)
      local elapsed=$((end_time - start_time))
      log "スキル成功: /$skill — ${elapsed}秒"

      # 成功時にログを記録
      append_changelog "$skill" "success" "${elapsed}s"
      commit_progress "/$skill 完了"

      CONSECUTIVE_ERRORS=0
      return 0
    else
      retry=$((retry + 1))
      CONSECUTIVE_ERRORS=$((CONSECUTIVE_ERRORS + 1))
      log "WARN: /$skill 失敗 (試行 $retry/$MAX_RETRY)"

      if [[ $retry -lt $MAX_RETRY ]]; then
        log "エラーログを読み込んで修正を試みます..."
        # エラーログをClaude Codeに渡して自己修正させる
        claude --print "直前のエラーログを確認して修正してください: $(tail -20 $LOG_DIR/claude.log)" \
          2>> "$LOG_DIR/claude.log" || true
        sleep 5
      fi
    fi
  done

  log "ERROR: /$skill — ${MAX_RETRY}回リトライしても失敗"
  notify_slack "スキル失敗: /$skill — ログ: $LOG_DIR"
  append_changelog "$skill" "failed" "after ${MAX_RETRY} retries"
  return 1
}

append_changelog() {
  local skill="$1"
  local status="$2"
  local detail="$3"
  local entry="- $(date '+%Y-%m-%d %H:%M') | /$skill | $status | $detail"

  # CHANGELOG.md に追記
  if [[ ! -f "$CHANGELOG" ]]; then
    echo "# CHANGELOG — 実験ノート" > "$CHANGELOG"
    echo "" >> "$CHANGELOG"
  fi

  # 今日のセクションを探して追記、なければ作成
  if ! grep -q "## $(date '+%Y-%m-%d')" "$CHANGELOG"; then
    echo "" >> "$CHANGELOG"
    echo "## $(date '+%Y-%m-%d')" >> "$CHANGELOG"
  fi

  echo "$entry" >> "$CHANGELOG"
}

# =====================
# 実行モード
# =====================
MODE="once"
SKILL=""
ARGS=""
CRON_TIME=""
WATCH_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cron)
      MODE="cron"
      CRON_TIME="$2"
      shift 2
      ;;
    --watch)
      MODE="watch"
      WATCH_PATH="$2"
      shift 2
      ;;
    --once)
      MODE="once"
      shift
      ;;
    --skill)
      SKILL="$2"
      shift 2
      ;;
    --args)
      ARGS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$SKILL" ]]; then
  echo "Usage: $0 --skill <skill-name> [--once|--cron HH:MM|--watch <path>]"
  exit 1
fi

case "$MODE" in
  once)
    run_skill "$SKILL" "$ARGS"
    ;;
  cron)
    log "Cronモード起動: 毎日 $CRON_TIME に /$SKILL を実行"
    while true; do
      CURRENT_TIME=$(date '+%H:%M')
      if [[ "$CURRENT_TIME" == "$CRON_TIME" ]]; then
        run_skill "$SKILL" "$ARGS"
        sleep 61  # 同分内の二重実行を防ぐ
      fi
      sleep 30
    done
    ;;
  watch)
    log "Watchモード起動: $WATCH_PATH の変更を監視"
    # fswatch が必要 (brew install fswatch)
    fswatch -o "$WATCH_PATH" | while read -r _; do
      log "変更検知: $WATCH_PATH"
      run_skill "$SKILL" "$ARGS"
    done
    ;;
esac
