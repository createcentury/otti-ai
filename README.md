# otti-ai

**人間の知見をソフトウェア化し、自律的に運用するためのフレームワーク**

Claude Code + MCP + Skills の3層アーキテクチャで、「業務の型」さえあれば高度なプログラミングスキルなしに強力な自動化システムを構築できます。

---

## なぜ otti-ai か

| 従来のSaaS自動化 | otti-ai |
|---|---|
| 決まった連携しかできない | MCPで任意のAPIに接続可能 |
| 設定を変えるのに開発者が必要 | CLAUDE.md を編集するだけ |
| ノウハウがツールに閉じる | SKILL.mdに蓄積され横展開できる |
| SaaSにデータを送る必要がある | ローカル実行でセキュア |

---

## アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│            Layer 3: 永続的コンテキスト層              │
│         CLAUDE.md（憲法）  SKILL.md（スキル集）        │
│         CHANGELOG.md（実験ノート）                    │
├─────────────────────────────────────────────────────┤
│            Layer 2: 接続・インターフェース層            │
│    MCP: freee / Google Ads / Slack / Notion / etc.  │
├─────────────────────────────────────────────────────┤
│            Layer 1: 実行・オーケストレーション層        │
│         Claude Code（ローカル）  Ralph Loop           │
└─────────────────────────────────────────────────────┘
```

---

## クイックスタート

### 1. 業種テンプレートをコピー

```bash
# 税理士向け
cp -r templates/tax-accountant/ ~/my-workspace/

# マーケター向け
cp -r templates/marketer/ ~/my-workspace/
```

### 2. MCP接続を設定

```bash
cd ~/my-workspace/
vim mcp/mcp-settings.json  # APIキーを記入
```

### 3. Claude Codeを起動

```bash
cd ~/my-workspace/
claude
# CLAUDE.md が自動で読み込まれ、Skillが使える状態になる
```

### 4. スラッシュコマンドを実行

```
/freee-check        # freee の未処理明細を確認・仕訳
/mtg-followup       # 議事録 → アクションアイテム展開
/rsa                # 広告コピーを自動生成
/sop-convert        # 業務手順書 → Skill に変換
```

---

## ディレクトリ構成

```
otti-ai/
├── .claude/commands/           # 共通スラッシュコマンド
├── core/                       # フレームワーク中核
│   ├── CLAUDE.md.template      # CLAUDE.md ベーステンプレート
│   ├── SKILL.md.template       # SKILL.md ベーステンプレート
│   ├── ralph-loop/             # 自律ループスクリプト
│   └── mcp/                    # MCP設定スキーマ
├── templates/                  # 業種別テンプレート（コピー起点）
│   ├── tax-accountant/         # 税理士向け
│   └── marketer/               # マーケター向け
├── skills/                     # 再利用可能なSkillファイル群
│   ├── common/                 # 業種横断スキル
│   ├── tax/                    # 税務ドメインスキル
│   └── marketing/              # マーケドメインスキル
├── docs/                       # 設計ドキュメント
└── examples/                   # 動作サンプル
```

---

## 事例

- **税理士（顧問先60社を1人で運用）**: 毎晩21時に全社の仕訳を自動処理。1社あたり約3分 → ゼロに。
- **マーケター（1人成長チーム）**: RSA広告文の自動生成、CPA急増の即時検知、無駄な支出の自動排除。

---

## ライセンス

MIT
