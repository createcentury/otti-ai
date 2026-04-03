# マーケターテンプレート

1人で広告運用チームを回すための自動化システム。
RSA自動生成、CPA急増検知、無駄な支出の自動排除。

## セットアップ（5ステップ）

### 1. テンプレートをコピー

```bash
cp -r templates/marketer/ ~/my-marketing-workspace/
cd ~/my-marketing-workspace/
```

### 2. 認証情報を設定

```bash
cp .env.example .env
vim .env
```

```
GOOGLE_ADS_DEVELOPER_TOKEN=your_token
GOOGLE_ADS_CUSTOMER_ID=your_customer_id
GOOGLE_OAUTH_CREDENTIALS=path/to/credentials.json
SLACK_BOT_TOKEN=xoxb-...
```

### 3. MCP を登録・Claude Code を起動

```bash
claude
```

### 4. 動作確認

```
/bleed-detector    # 出血検知テスト
/rsa [campaign_id] # RSA生成テスト
```

---

## 主要コマンド

| コマンド | 説明 | 実行タイミング |
|---|---|---|
| `/rsa [campaign_id]` | RSA広告文を自動生成 | 広告更新時 |
| `/bleed-detector` | 出血状態（費用超過×CV0）を検知 | 1時間ごと（自動） |
| `/weekly-report` | 広告週次レポート生成 | 毎週月曜 |
| `/ab-test` | A/Bテスト設計・結果分析 | 任意 |

---

## 自動化スケジュール

```bash
# 1時間ごとに出血検知
./ralph-loop/loop.sh --cron "*/1" --skill bleed-detector &

# 毎週月曜9時に週次レポート
./ralph-loop/loop.sh --cron "MON:09:00" --skill weekly-report &
```

---

## カスタマイズポイント

`CLAUDE.md` を編集して以下を調整:
- ブランドボイス・ガイドライン
- 使用禁止ワードリスト
- 異常検知ルールの閾値
- 確認ゲートの条件
