# VSCode互換のworktree作成関数
code-w() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "Usage: code-w <branch>"
        return 1
    fi

    # Gitリポジトリ内確認
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Gitリポジトリ内で実行してください"
        return 1
    fi

    local base_dir=".worktrees"
    local dir_name="$(echo "$branch" | tr '/' '-')"
    local target_dir="$base_dir/$dir_name"

    mkdir -p "$base_dir"

    # ローカルブランチ存在チェックのみ（リモートは参照しない）
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$target_dir" "$branch" || { echo "Error: worktree追加に失敗"; return 1; }
    else
      # origin/main をベースに新規ブランチ作成
      git fetch origin main
      git worktree add "$target_dir" -b "$branch" origin/main || { echo "Error: origin/mainをベースにしたworktree追加に失敗"; return 1; }
    fi

    # # 実行ディレクトリ（ここにある target/ を新worktreeへコピーしたい）
    # local invoked_dir="$PWD"

    # # .gitignore 管理外（例: Rustの target/）も worktree へコピーしたい
    # # - `git check-ignore` で「無視される」ことを確認できた場合のみコピー
    # # - コピー失敗は警告のみ（worktree作成自体は成功しているため）
    # local src_target="$invoked_dir/target"
    # local dst_worktree="$invoked_dir/$target_dir"
    # local dst_target="$dst_worktree/target"

    # if [[ -d "$src_target" ]] && git -C "$invoked_dir" check-ignore -q "target/" 2>/dev/null; then
    #   mkdir -p "$dst_target"
    #   if command -v rsync >/dev/null 2>&1; then
    #     rsync -a --no-whole-file --partial --progress "$src_target/" "$dst_target/" || echo "Warning: target/ のコピーに失敗しました: $src_target -> $dst_target"
    #   else
    #     cp -a --reflink=auto "$src_target/." "$dst_target/" || echo "Warning: target/ のコピーに失敗しました: $src_target -> $dst_target"
    #   fi
    # fi

    echo "Worktree created at: $target_dir"
    code "$target_dir"
}

wtz() {
  local branch="${1:?branch name required}"

  # ローカルブランチ or リモートブランチに存在するか確認
  if git show-ref --verify --quiet "refs/heads/${branch}" || \
     git ls-remote --exit-code --heads origin "${branch}" &>/dev/null; then
    # 既存ブランチ → そのままワークツリー作成
    wt switch "${branch}" -x "zed {{ worktree_path }}"
  else
    # 新規ブランチ → --create でブランチごと作成
    wt switch --create "${branch}" -x "zed {{ worktree_path }}"
  fi
}
