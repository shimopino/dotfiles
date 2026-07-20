# VSCode統合
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  . "$(code --locate-shell-integration-path zsh)"
fi

# Kiro統合
if [[ "$TERM_PROGRAM" == "kiro" ]]; then
  . "$(kiro --locate-shell-integration-path zsh)"
fi

# worktrunk (wt)
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Deno completions
if [[ ":$FPATH:" != *":/Users/shimopino/completions:"* ]]; then
  export FPATH="/Users/shimopino/completions:$FPATH"
fi

# Windsurf PATH（重複削除）
export PATH="/Users/shimopino/.codeium/windsurf/bin:$PATH"

# MCP設定
export MCP_CONFIG_PATH="~/.cursor/mcp.json"

# Rustを使用するときのコンパイルキャッシュを設定する
export RUSTC_WRAPPER=/Users/shimopino/.cargo/bin/sccache
