# 税理士事務所テンプレート

スタッフ0人の税理士が、顧問先を1人で回すための自動化システム。

## セットアップ（5ステップ）

### 1. テンプレートをコピー

```bash
cp -r templates/tax-accountant/ ~/my-tax-workspace/
cd ~/my-tax-workspace/
```

### 2. freee API 認証情報を設定

```bash
cp .env.example .env
vim .env
```

```
FREEE_CLIENT_ID=your_client_id
FREEE_CLIENT_SECRET=your_client_secret
FREEE_ACCESS_TOKEN=your_access_token
SLACK_BOT_TOKEN=xoxb-...
NOTION_API_TOKEN=secret_...
```

### 3. MCP を Claude Code に登録

```bash
# claude_desktop_config.json または settings.json に追記
cat mcp/mcp-settings.json
```

### 4. Claude Code を起動

```bash
claude
# CLAUDE.md が自動読み込みされる
```

### 5. 動作確認

```
/freee-check   # 顧問先1社のIDを指定してテスト実行
```

---

## 主要コマンド

| コマンド | 説明 | 実行タイミング |
|---|---|---|
| `/freee-check` | 全事業所の未処理明細を仕訳 | 毎晩21時（自動）または任意 |
| `/mtg-followup` | 議事録 → アクションアイテム | 打ち合わせ後 |
| `/kessho-prep` | 決算準備チェック | 決算月 |
| `/daily-report` | 日次サマリ生成 | 毎朝9時（自動） |

---

## 自動化スケジュール（Ralph Loop）

```bash
# 自動起動の設定
./ralph-loop/loop.sh --cron "21:00" --skill freee-check &
./ralph-loop/loop.sh --cron "09:00" --skill daily-report &
```

---

## カスタマイズポイント

`CLAUDE.md` を編集して以下を調整:
- 仕訳分類キーワード辞書の追加
- 確認ゲートの金額閾値の変更
- 事務所固有の会計ルールの追記
