#!/usr/bin/env bash
set -euo pipefail

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

declare -a worktree_paths=()
declare -a worktree_branches=()

while IFS= read -r line; do
  if [[ -z "${line}" ]]; then
    if [[ -n "${current_path:-}" && "${current_path}" == "${repo_root}/.worktrees/"* ]]; then
      worktree_paths+=("${current_path}")
      worktree_branches+=("${current_branch:-detached}")
    fi
    current_path=""
    current_branch="detached"
    continue
  fi

  case "${line}" in
    worktree\ *)
      current_path="${line#worktree }"
      ;;
    branch\ refs/heads/*)
      current_branch="${line#branch refs/heads/}"
      ;;
  esac
done < <(git worktree list --porcelain && printf '\n')

if (( ${#worktree_paths[@]} == 0 )); then
  echo "No managed worktrees found under .worktrees/."
  exit 0
fi

echo "Managed worktrees:"
for i in "${!worktree_paths[@]}"; do
  rel_path="${worktree_paths[$i]#${repo_root}/}"
  printf "  %d) %s [branch: %s]\n" "$((i + 1))" "${rel_path}" "${worktree_branches[$i]}"
done

while true; do
  printf "Select a worktree to remove (q to quit): "
  read -r choice

  if [[ "${choice}" == "q" || "${choice}" == "Q" ]]; then
    echo "Canceled."
    exit 0
  fi

  if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#worktree_paths[@]} )); then
    break
  fi

  echo "Invalid selection."
done

selected_index=$((choice - 1))
target_path="${worktree_paths[$selected_index]}"
target_rel="${target_path#${repo_root}/}"

printf "Remove %s ? [y/N]: " "${target_rel}"
read -r confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
  echo "Canceled."
  exit 0
fi

if [[ -n "$(git -C "${target_path}" status --porcelain 2>/dev/null || true)" ]]; then
  printf "Uncommitted changes detected in %s. Force remove? [y/N]: " "${target_rel}"
  read -r force_confirm
  if [[ "${force_confirm}" =~ ^[Yy]$ ]]; then
    git worktree remove --force "${target_path}"
  else
    echo "Canceled."
    exit 0
  fi
else
  git worktree remove "${target_path}"
fi
echo "Removed: ${target_rel}"
