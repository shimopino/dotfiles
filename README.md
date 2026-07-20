# dotfiles

chezmoi で管理している個人用 dotfiles です。

## セットアップ

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply shimopino
```

## 管理対象

- [Zed](https://zed.dev/) エディタの設定・キーマップ
- [Starship](https://starship.rs/) プロンプト設定
- [mise](https://mise.jdx.dev/) 設定（`config.toml`）と worktree 操作用タスクスクリプト
- [sheldon](https://sheldon.cli.rs/) プラグイン設定

今後、他のツールの設定も順次追加予定です。
