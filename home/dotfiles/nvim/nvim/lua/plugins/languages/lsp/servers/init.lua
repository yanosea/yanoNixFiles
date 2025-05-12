-- サーバー設定の読み込み
return {
  -- 各言語サーバーのインポート
  { import = "plugins.languages.lsp.servers.lua_ls" },
  -- 後で他の言語サーバーを追加
}
