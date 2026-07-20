#!/usr/bin/env bash
set -euo pipefail

# chezmoi 管理の dotfiles をインタラクティブに同期する
#   1) ローカルドリフト（chezmoi status）を1件ずつ re-add / apply / skip
#   2) ソースリポジトリの変更をコミット
#   3) リモート（origin/main）を fetch し、遅れていれば pull --rebase + apply
#   4) 進んでいれば確認の上で push
#   5) サマリを表示

source_path="$(chezmoi source-path)"

re_added_count=0
applied_count=0
committed=0
pulled=0
pushed=0

print_summary() {
  echo ""
  echo "=== Summary ==="
  echo "  re-add: ${re_added_count}"
  echo "  apply:  ${applied_count}"
  if [[ "${committed}" -eq 1 ]]; then
    echo "  commit: yes"
  else
    echo "  commit: no"
  fi
  if [[ "${pulled}" -eq 1 ]]; then
    echo "  pull --rebase: yes"
  else
    echo "  pull --rebase: no"
  fi
  if [[ "${pushed}" -eq 1 ]]; then
    echo "  push: yes"
  else
    echo "  push: no"
  fi
}

echo "=== Step 1: Review local drift ==="

status_output="$(chezmoi status)"
if [[ -z "${status_output}" ]]; then
  echo "No local drift."
else
  # 先に全行を配列へ集めておく（後段の read <<< が対話プロンプトの stdin を奪わないように）
  drift_lines=()
  while IFS= read -r status_line; do
    [[ -z "${status_line}" ]] && continue
    drift_lines+=("${status_line}")
  done <<< "${status_output}"

  quit_drift=0
  for line in "${drift_lines[@]}"; do
    if [[ "${quit_drift}" -eq 1 ]]; then
      break
    fi

    # 形式: 2文字コード + スペース + ~ からの相対パス
    rel_path="${line:3}"
    target="${HOME}/${rel_path}"

    echo ""
    echo "--- ${line} ---"
    # chezmoi diff は stdin を読み進めてしまうため、後続プロンプトの入力を奪わないよう /dev/null にリダイレクトする
    chezmoi diff "${target}" < /dev/null || true

    while true; do
      printf "[r]e-add (keep local) / [a]pply (take source) / [s]kip / [q]uit: "
      if ! read -r choice; then
        choice="q"
      fi
      case "${choice}" in
        r|R)
          chezmoi re-add "${target}"
          re_added_count=$((re_added_count + 1))
          break
          ;;
        a|A)
          chezmoi apply --force "${target}"
          applied_count=$((applied_count + 1))
          break
          ;;
        s|S)
          break
          ;;
        q|Q)
          quit_drift=1
          break
          ;;
        *)
          echo "Invalid choice."
          ;;
      esac
    done
  done
fi

echo ""
echo "=== Step 2: Commit source changes ==="

if [[ -n "$(git -C "${source_path}" status --short)" ]]; then
  git -C "${source_path}" status --short
  printf "Commit message [chore: update dotfiles]: "
  if ! read -r commit_msg; then
    commit_msg=""
  fi
  if [[ -z "${commit_msg}" ]]; then
    commit_msg="chore: update dotfiles"
  fi
  git -C "${source_path}" add -A
  git -C "${source_path}" commit -m "${commit_msg}"
  committed=1
else
  echo "No changes to commit."
fi

echo ""
echo "=== Step 3: Fetch remote ==="

if ! git -C "${source_path}" fetch origin main; then
  echo "Warning: git fetch failed (offline?). Skipping push."
  print_summary
  exit 0
fi

behind_count="$(git -C "${source_path}" rev-list --count HEAD..origin/main)"
if [[ "${behind_count}" -gt 0 ]]; then
  echo "Local branch is behind origin/main by ${behind_count} commit(s)."
  git -C "${source_path}" pull --rebase origin main
  pulled=1

  printf "Apply remote changes to files now? [y/N]: "
  if ! read -r apply_confirm; then
    apply_confirm="n"
  fi
  if [[ "${apply_confirm}" == "y" || "${apply_confirm}" == "Y" ]]; then
    chezmoi apply --force
  else
    echo "Skipped chezmoi apply. Run 'chezmoi apply' manually later."
  fi
fi

echo ""
echo "=== Step 4: Push ==="

ahead_count="$(git -C "${source_path}" rev-list --count origin/main..HEAD)"
if [[ "${ahead_count}" -gt 0 ]]; then
  printf "Push %s commit(s) to origin/main? [y/N]: " "${ahead_count}"
  if ! read -r push_confirm; then
    push_confirm="n"
  fi
  if [[ "${push_confirm}" == "y" || "${push_confirm}" == "Y" ]]; then
    git -C "${source_path}" push origin main
    pushed=1
  fi
else
  echo "Nothing to push."
fi

print_summary
