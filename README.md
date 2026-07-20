# dotfiles

chezmoi で管理している個人用 dotfiles です。

## セットアップ

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply shimopino
```

初回 `init` 時に git のメールアドレスをプロンプトされます（`~/.config/chezmoi/chezmoi.toml` に保存され、以降は再利用されます）。
また `run_once_install-packages.sh.tmpl` が自動実行され、Homebrew（Brewfile）・mise・rustup のセットアップが行われます。

## 管理対象

- [Zed](https://zed.dev/) エディタの設定・キーマップ
- [Starship](https://starship.rs/) プロンプト設定
- [mise](https://mise.jdx.dev/) 設定（`config.toml`）と worktree 操作用タスクスクリプト
- [sheldon](https://sheldon.cli.rs/) プラグイン設定
- Claude Code（settings / CLAUDE.md / RTK.md / herdr hook）
  - `herdr-agent-state.sh` は herdr が再生成し得るため、更新されたら `chezmoi re-add` すること
- zsh 本体（`.zshenv` / `ZDOTDIR` 配下の `.zshrc` / `.zprofile` / `conf.d/*.zsh`）
  - `~/.config/zsh/secrets.zsh` は秘密情報を含むためローカルのみで管理し、chezmoi の管理対象外
- git（`.gitconfig` はテンプレート化。`user.email` は初回 `init` 時にプロンプトされ `~/.config/chezmoi/chezmoi.toml` に保存）と `.gitignore_global`
- Homebrew パッケージ（`Brewfile`、`brew bundle` で導入。apply 対象外で bootstrap スクリプトからのみ参照）

今後、他のツールの設定も順次追加予定です。
