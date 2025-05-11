# LunarVim プラグイン分類

## プラグイン管理
- [x] **folke/lazy.nvim**
  - モダンなプラグイン管理システム
  - 遅延読み込みによるパフォーマンス最適化

## LSP（言語サーバープロトコル）関連
- [x] **neovim/nvim-lspconfig**
  - LSP設定基盤
  - 言語サーバーとの連携設定
- [x] **williamboman/mason-lspconfig.nvim**
  - LSPサーバー自動インストール
- [ ] **tamago324/nlsp-settings.nvim**
  - JSON形式でのLSP設定管理
- [ ] **nvimtools/none-ls.nvim**
  - 診断・フォーマット等LSP拡張
- [x] **williamboman/mason.nvim**
  - LSPサーバーとツールのパッケージマネージャ
- [ ] **folke/neodev.nvim**
  - Neovim Lua API開発支援
  - 型定義と補完機能強化

## 補完エンジンと拡張
- [ ] **hrsh7th/nvim-cmp**
  - モダンな補完エンジン
  - プラグイン拡張可能なアーキテクチャ
- [ ] **hrsh7th/cmp-nvim-lsp**
  - LSPからの補完ソース
- [ ] **saadparwaiz1/cmp_luasnip**
  - スニペット補完ソース
- [ ] **hrsh7th/cmp-buffer**
  - 現在のバッファからの単語補完
- [ ] **hrsh7th/cmp-path**
  - ファイルパス補完
- [ ] **hrsh7th/cmp-cmdline**
  - コマンドライン補完

## スニペット
- [ ] **L3MON4D3/LuaSnip**
  - 強力なスニペットエンジン
  - Lua設定可能
- [ ] **rafamadriz/friendly-snippets**
  - 各言語用スニペットコレクション

## 構文解析・コード分析
- [x] **nvim-treesitter/nvim-treesitter**
  - 高度な構文解析
  - 精密なコード認識と操作
- [ ] **JoosepAlviste/nvim-ts-context-commentstring**
  - 言語コンテキスト対応コメント
- [x] **RRethy/vim-illuminate**
  - 同一識別子のハイライト表示
- [x] **SmiteshP/nvim-navic**
  - コード内位置表示（breadcrumbs）
  - LSP情報を活用した構造表示

## ファイルナビゲーション
- [x] **nvim-telescope/telescope.nvim**
  - 多機能ファジーファインダー
  - 拡張可能な検索インターフェース
- [x] **nvim-telescope/telescope-fzf-native.nvim**
  - Telescopeの検索高速化（Cバイナリ）
- [x] **nvim-tree/nvim-tree.lua**
  - モダンなファイルエクスプローラー
- [x] **tamago324/lir.nvim**
  - シンプルなファイルブラウザ

## UI改善
- [x] **folke/which-key.nvim**
  - キーバインド表示ヘルパー
  - コマンド探索支援
- [x] **nvim-tree/nvim-web-devicons**
  - ファイルタイプアイコン表示
- [x] **nvim-lualine/lualine.nvim**
  - カスタマイズ可能なステータスライン
- [x] **akinsho/bufferline.nvim**
  - モダンなタブ/バッファライン
- [x] **goolord/alpha-nvim**
  - 起動画面/ダッシュボード
- [x] **windwp/nvim-autopairs**
  - インテリジェントな自動カッコ閉じ

## Git統合
- [x] **lewis6991/gitsigns.nvim**
  - Gitステータス表示
  - 差分表示と操作機能

## 開発支援ツール
- [x] **mfussenegger/nvim-dap**
  - デバッグアダプタープロトコル実装
- [x] **rcarriga/nvim-dap-ui**
  - デバッガーUI
- [x] **numToStr/Comment.nvim**
  - 効率的なコード内コメント操作
- [x] **akinsho/toggleterm.nvim**
  - 高度な組込ターミナル
- [ ] **b0o/schemastore.nvim**
  - JSONスキーマ対応

## パフォーマンス/ユーティリティ
- [x] **nvim-lua/plenary.nvim**
  - Luaユーティリティ関数群
