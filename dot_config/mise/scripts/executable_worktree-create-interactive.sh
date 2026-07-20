#!/usr/bin/env bash
set -euo pipefail

# zsh の *(N) 相当。マッチなしのグロブを空展開にする
shopt -s nullglob

# mise global tasks run from the config location. Use the original invocation directory.
start_dir="${MISE_ORIGINAL_CWD:-${PWD}}"
cd "${start_dir}"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${repo_root}" ]]; then
  echo "Error: this command must be run inside a git repository."
  exit 1
fi

if [[ "${PWD}" != "${repo_root}" ]]; then
  echo "Error: run this command from repository root: ${repo_root}"
  exit 1
fi

git fetch --all --prune

# origin のデフォルトブランチを検出（未設定なら main にフォールバック）
default_branch="main"
if origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
  default_branch="${origin_head#origin/}"
fi

base_dir="${repo_root}/.worktrees"

# リモートブランチ一覧を収集（origin/HEAD は除外）
declare -a remote_branches=()
while IFS= read -r ref; do
  [[ "${ref}" == "origin/HEAD" ]] && continue
  remote_branches+=("${ref#origin/}")
done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin)

if (( ${#remote_branches[@]} > 0 )); then
  echo "Remote branches:"
  for i in "${!remote_branches[@]}"; do
    branch_name="${remote_branches[$i]}"
    dir_name="${branch_name//\//-}"
    marker=""
    [[ -d "${base_dir}/${dir_name}" ]] && marker="  [worktree exists]"
    printf "  %d) %s%s\n" "$((i + 1))" "${branch_name}" "${marker}"
  done
else
  echo "No remote branches found on origin."
fi

branch=""
while true; do
  printf "Select a branch by number, or type a new branch name (q to quit): "
  read -r input

  if [[ "${input}" == "q" || "${input}" == "Q" ]]; then
    echo "Canceled."
    exit 0
  fi

  if [[ -z "${input}" ]]; then
    echo "Empty input."
    continue
  fi

  if [[ "${input}" =~ ^[0-9]+$ ]]; then
    if (( input >= 1 && input <= ${#remote_branches[@]} )); then
      branch="${remote_branches[$((input - 1))]}"
      break
    fi
    echo "Invalid selection."
    continue
  fi

  # 数字以外は新規（または既存）ブランチ名として扱う
  branch="${input}"
  break
done

dir_name="${branch//\//-}"
target_dir="${base_dir}/${dir_name}"
mkdir -p "${base_dir}"

if [[ -d "${target_dir}" ]]; then
  echo "Error: a worktree already exists at ${target_dir}"
  echo "Run 'mise run worktree-open' to open it instead."
  exit 1
fi

open_in_zed() {
  if command -v zed >/dev/null 2>&1; then
    zed -n "$1"
  else
    echo "Note: 'zed' command not found; skipping editor launch."
  fi
}

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  # ローカルブランチが既に存在
  git worktree add "${target_dir}" "${branch}"
elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
  # リモートにのみ存在 → トラッキングブランチを作成
  git worktree add "${target_dir}" -b "${branch}" "origin/${branch}"
else
  # どこにも存在しない → デフォルトブランチから新規作成
  git worktree add "${target_dir}" -b "${branch}" "origin/${default_branch}"
fi

echo "Setting up worktree at: ${target_dir}"

merge_local_entries_recursively() {
  local source_dir="$1"
  local destination_dir="$2"
  local source_entry
  local destination_entry

  mkdir -p "${destination_dir}"

  for source_entry in "${source_dir}"/*; do
    destination_entry="${destination_dir}/$(basename "${source_entry}")"

    if [[ -d "${source_entry}" && ! -L "${source_entry}" ]]; then
      if [[ -d "${destination_entry}" && ! -L "${destination_entry}" ]]; then
        merge_local_entries_recursively "${source_entry}" "${destination_entry}"
      elif [[ ! -e "${destination_entry}" && ! -L "${destination_entry}" ]]; then
        ln -s "${source_entry}" "${destination_entry}"
      fi
      continue
    fi

    if [[ "${source_entry}" != *.local.* ]]; then
      continue
    fi

    if [[ -e "${destination_entry}" && ! -L "${destination_entry}" ]]; then
      continue
    fi

    rm -rf "${destination_entry}"
    ln -s "${source_entry}" "${destination_entry}"
  done
}

replace_with_symlink() {
  local source_path="$1"
  local destination_path="$2"

  if [[ ! -e "${source_path}" && ! -L "${source_path}" ]]; then
    mkdir -p "${source_path}"
  fi

  if [[ -d "${source_path}" && ! -L "${source_path}" && -d "${destination_path}" && ! -L "${destination_path}" ]]; then
    merge_local_entries_recursively "${source_path}" "${destination_path}"
    return
  fi

  if [[ -e "${destination_path}" && ! -L "${destination_path}" ]]; then
    return
  fi

  if [[ -L "${destination_path}" ]]; then
    rm -rf "${destination_path}"
  fi

  ln -s "${source_path}" "${destination_path}"
}

# シンボリックリンク
replace_with_symlink "${repo_root}/plan"              "${target_dir}/plan"
replace_with_symlink "${repo_root}/tmp"               "${target_dir}/tmp"
replace_with_symlink "${repo_root}/docs"              "${target_dir}/docs"
replace_with_symlink "${repo_root}/.zed"              "${target_dir}/.zed"
replace_with_symlink "${repo_root}/.claude"           "${target_dir}/.claude"
replace_with_symlink "${repo_root}/.copilot-tracking" "${target_dir}/.copilot-tracking"
mkdir -p "${target_dir}/.github"
replace_with_symlink "${repo_root}/.github/instructions" "${target_dir}/.github/instructions"
replace_with_symlink "${repo_root}/.github/skills"       "${target_dir}/.github/skills"
replace_with_symlink "${repo_root}/.github/agents"       "${target_dir}/.github/agents"
replace_with_symlink "${repo_root}/.github/prompts"      "${target_dir}/.github/prompts"
for f in "${repo_root}"/*.local.*; do
  replace_with_symlink "${f}" "${target_dir}/$(basename "${f}")"
done

echo "Symlinks created for: plan, tmp, docs, .zed, .copilot-tracking, .github/instructions, .github/skills, .github/agents, .github/prompts, and recursive *.local.*"

echo "Worktree created at: ${target_dir}"
open_in_zed "${target_dir}"
